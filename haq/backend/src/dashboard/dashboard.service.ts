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
    return this.tenantDashboard(user.tenantId);
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