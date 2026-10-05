import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';
import { AuditService } from '../audit/audit.service';

@Injectable()
export class DashboardService {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
  ) {}

  async getDashboard(user: RequestUser) {
    if (user.role === Role.SUPER_ADMIN) {
      return this.superAdminDashboard();
    }
    if (user.role === Role.WALI_SANTRI) {
      return this.waliDashboard(user.userId, user.tenantId);
    }
    if (user.role === Role.USTADZ) {
    const payload = await this.ustadzDashboard(user.userId, user.tenantId);
    if (payload) return payload;
  }
    return this.tenantDashboard(user.tenantId);
  }

    // [BARU] Beranda Ustadz (GURU)
  private async ustadzDashboard(userId: string, tenantId: string | undefined) {
    // Jangan pernah query tanpa tenantId (where undefined = tanpa filter).
    if (!tenantId) return null;

    const ustadz = await this.prisma.ustadz.findFirst({
      where: { userId, tenantId },
      select: { id: true, nama: true, jenis: true },
    });
    if (!ustadz || ustadz.jenis !== 'GURU') return null;

    const kelasList = await this.prisma.kelas.findMany({
      where: { tenantId, waliKelasId: ustadz.id },
      orderBy: { namaKelas: 'asc' },
      select: {
        id: true,
        namaKelas: true,
        tingkat: true,
        _count: { select: { santris: { where: { status: 'AKTIF' } } } },
      },
    });

    if (kelasList.length === 0) {
      return {
        role: 'USTADZ',
        namaPengguna: ustadz.nama,
        kelasDiampu: [],
        ringkasan: { kehadiranKet: 'Belum ada kelas yang Anda ampu' },
      };
    }

    const todayStart = new Date();
  todayStart.setHours(0, 0, 0, 0);
  const tomorrowStart = new Date(todayStart);
  tomorrowStart.setDate(tomorrowStart.getDate() + 1);

const jumlahMapel = await this.prisma.mataPelajaran.count({ where: { tenantId } });

    const absensiHariIni = await this.prisma.absensi.findMany({
      where: {
        tenantId,
        kelasId: { in: kelasList.map((k) => k.id) },
        tanggal: { gte: todayStart, lt: tomorrowStart },
      },
      select: { kelasId: true, mapelId: true, status: true },
    });

    // kelasId -> kumpulan mapelId berbeda yang sudah direkap hari ini
    const mapelTerisiPerKelas = new Map<string, Set<string>>();
    for (const a of absensiHariIni) {
      if (!a.mapelId) continue;
      if (!mapelTerisiPerKelas.has(a.kelasId)) {
        mapelTerisiPerKelas.set(a.kelasId, new Set());
      }
      mapelTerisiPerKelas.get(a.kelasId)!.add(a.mapelId);
    }

    const kelasTerisi = new Set(absensiHariIni.map((a) => a.kelasId));

    const kelasDiampu = kelasList.map((k) => ({
      id: k.id,
      namaKelas: k.namaKelas,
      mapel: null as string | null,
      tingkat: k.tingkat,
      jumlahSantri: k._count.santris,
      absensiHariIniTerisi: kelasTerisi.has(k.id),
      jumlahMapel,
      mapelTerisiHariIni: mapelTerisiPerKelas.get(k.id)?.size ?? 0,
    }));

    const total = absensiHariIni.length;
    const hadir = absensiHariIni.filter((a) => a.status === 'HADIR').length;

    const ringkasan =
      total > 0
        ? {
            kehadiranPersen: Math.round((hadir / total) * 100),
            kehadiranKet: `${hadir} dari ${total} data absensi hari ini`,
          }
        : { kehadiranKet: 'Belum ada absensi hari ini' };

    return {
      role: 'USTADZ',
      namaPengguna: ustadz.nama,
      kelasDiampu,
      ringkasan,
    };
  }

  private async superAdminDashboard() {
    const tigaPuluhHariLalu = new Date();
    tigaPuluhHariLalu.setDate(tigaPuluhHariLalu.getDate() - 30);

    const [totalTenant, tenantAktif, tenantPending, tenantBaru30Hari, totalUser, totalSantri] =
      await this.prisma.$transaction([
        this.prisma.tenant.count(),
        this.prisma.tenant.count({ where: { status: 'AKTIF' } }),
        this.prisma.tenant.count({ where: { status: 'PENDING' } }),
        this.prisma.tenant.count({ where: { tanggalDaftar: { gte: tigaPuluhHariLalu } } }),
        this.prisma.user.count({ where: { role: { not: Role.SUPER_ADMIN } } }),
        this.prisma.santri.count(),
      ]);

    const recentTenants = await this.prisma.tenant.findMany({
      orderBy: { tanggalDaftar: 'desc' },
      take: 10,
      include: { _count: { select: { users: true, santris: true } } },
    });

    return {
      role: 'SUPER_ADMIN',
      statistik: { totalTenant, tenantAktif, tenantPending, tenantBaru30Hari, totalUser, totalSantri },
      tenantTerbaru: recentTenants,
      platformHealth: await this.getPlatformHealth(),
      auditKeamanan: await this.audit.recent(3),
    };
  }

  private async getPlatformHealth() {
    const mulai = Date.now();
    let sehat = true;
    try {
      await this.prisma.$queryRaw`SELECT 1`;
    } catch {
      sehat = false;
    }
    return {
      latencyMs: Date.now() - mulai,
      clusterLabel: process.env.DEPLOY_REGION || 'Self-hosted VPS',
      sehat,
    };
  }

  private async tenantDashboard(tenantId: string) {
    const todayStart = new Date();
    todayStart.setHours(0, 0, 0, 0);
    const todayEnd = new Date();
    todayEnd.setHours(23, 59, 59, 999);

    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - 7);

    const [
      totalSantri,
      santriAktif,
      totalKelas,
      totalUstadz,
      hadirHariIni,
      pelanggaranMingguIni,
      izinPending,
      santriSakit,
    ] = await this.prisma.$transaction([
      this.prisma.santri.count({ where: { tenantId } }),
      this.prisma.santri.count({ where: { tenantId, status: 'AKTIF' } }),
      this.prisma.kelas.count({ where: { tenantId } }),
      this.prisma.ustadz.count({ where: { tenantId } }),
      this.prisma.absensi.count({
        where: { tenantId, status: 'HADIR', tanggal: { gte: todayStart, lte: todayEnd } },
      }),
      this.prisma.pelanggaran.count({
        where: { tenantId, tanggal: { gte: weekStart } },
      }),
      this.prisma.perizinan.count({ where: { tenantId, statusApproval: 'DIAJUKAN' } }),
      this.prisma.kesehatanLog.count({
        where: {
          tenantId,
          tanggal: { gte: weekStart },
          status: { in: ['RAWAT_JALAN', 'DIRUJUK'] },
        },
      }),
    ]);

    const distribusiKelas = await this.prisma.kelas.findMany({
      where: { tenantId },
      include: { _count: { select: { santris: true } } },
    });

    const pelanggaranPerHari = await this.prisma.pelanggaran.groupBy({
      by: ['tanggal'],
      where: { tenantId, tanggal: { gte: weekStart } },
      _count: true,
      orderBy: { tanggal: 'asc' },
    });

    return {
      role: 'TENANT',
      statistik: {
        totalSantri,
        santriAktif,
        totalKelas,
        totalUstadz,
        hadirHariIni,
        pelanggaranMingguIni,
        izinPending,
        santriSakit,
      },
      distribusiKelas,
      pelanggaranPerHari,
    };
  }

  private async waliDashboard(userId: string, tenantId: string | undefined) {
    const wali = await this.prisma.waliSantri.findFirst({
      where: { userId, ...(tenantId ? { tenantId } : {}) },
      include: {
        santris: {
          include: { kelas: { select: { namaKelas: true } } },
        },
      },
    });

    if (!wali || wali.santris.length === 0) {
      return { role: 'WALI_SANTRI', statistik: {}, anak: [], pesan: 'Belum ada data anak.' };
    }

    const anakIds = wali.santris.map((s) => s.id);
    const [
      pelanggaranTotal,
      izinPending,
      kehadiranBulanIni,
      rataRataNilai,
    ] = await this.prisma.$transaction([
      this.prisma.pelanggaran.count({ where: { santriId: { in: anakIds } } }),
      this.prisma.perizinan.count({
        where: { santriId: { in: anakIds }, statusApproval: 'DIAJUKAN' },
      }),
      this.prisma.absensi.count({
        where: { santriId: { in: anakIds }, status: 'HADIR' },
      }),
      this.prisma.nilai.aggregate({ _avg: { nilai: true }, where: { santriId: { in: anakIds } } }),
    ]);

    return {
      role: 'WALI_SANTRI',
      wali: { id: wali.id, nama: wali.nama, hubungan: wali.hubungan },
      anak: wali.santris,
      statistik: {
        jumlahAnak: anakIds.length,
        pelanggaranTotal,
        izinPending,
        kehadiranBulanIni,
        rataRataNilai: rataRataNilai._avg.nilai ?? null,
      },
    };
  }
}