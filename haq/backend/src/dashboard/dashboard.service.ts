import { ForbiddenException, Injectable } from '@nestjs/common';
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

    // Hanya role ini yang menerima nama santri (rekap pelanggaran,
  // tahfidz tertinggal) dan log aktivitas.
  private static readonly ROLE_LIHAT_NAMA: Role[] = [Role.ADMIN, Role.PIMPINAN];

  async getDashboard(user: RequestUser) {
    if (user.role === Role.SUPER_ADMIN) {
      return this.superAdminDashboard();
    }
    if (user.role === Role.WALI_SANTRI) {
      return this.waliDashboard(user.userId, user.tenantId);
    }

    // Semua role di bawah ini wajib terikat ke satu pondok.
    if (!user.tenantId) {
      throw new ForbiddenException('Akun tidak terhubung ke pondok manapun.');
    }

    // Santri tidak boleh menerima payload tenant sama sekali.
    if (user.role === Role.SANTRI) {
      return { role: 'SANTRI', statistik: {}, pesan: 'Dashboard santri belum tersedia.' };
    }

    if (user.role === Role.USTADZ) {
      const payload = await this.ustadzDashboard(user.userId, user.tenantId);
      if (payload) return payload;
      // Ustadz non-GURU jatuh ke dashboard tenant, tanpa nama santri.
    }

    const lihatNama = DashboardService.ROLE_LIHAT_NAMA.includes(user.role);
    return this.tenantDashboard(user.tenantId, lihatNama);
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

    const mengajar = await this.prisma.ustadzMengajar.findMany({
      where: { tenantId, ustadzId: ustadz.id },
      select: { kelasId: true, mapelId: true },
    });

    // kelasId -> mapelId yang diampu ustadz ini di kelas tersebut
    const mapelDiampuPerKelas = new Map<string, Set<string>>();
    for (const m of mengajar) {
      if (!m.mapelId) continue;
      if (!mapelDiampuPerKelas.has(m.kelasId)) {
        mapelDiampuPerKelas.set(m.kelasId, new Set());
      }
      mapelDiampuPerKelas.get(m.kelasId)!.add(m.mapelId);
    }
    const kelasList = await this.prisma.kelas.findMany({
      where: {
        tenantId,
        OR: [
          { waliKelasId: ustadz.id },
          { id: { in: mengajar.map((m) => m.kelasId) } },
        ],
      },
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

    const hariIniWib = new Date(Date.now() + 7 * 3600 * 1000).toISOString().slice(0, 10);
    const todayStart = new Date(`${hariIniWib}T00:00:00+07:00`);
    const tomorrowStart = new Date(todayStart.getTime() + 24 * 3600 * 1000);

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

    const kelasDiampu = kelasList.map((k) => {
      const diampu = mapelDiampuPerKelas.get(k.id) ?? new Set<string>();
      const terisiSemua = mapelTerisiPerKelas.get(k.id) ?? new Set<string>();
      // Hanya hitung mapel yang diampu ustadz ini
      const terisiMilikku = [...terisiSemua].filter((id) => diampu.has(id)).length;

      return {
        id: k.id,
        namaKelas: k.namaKelas,
        mapel: null as string | null,
        tingkat: k.tingkat,
        jumlahSantri: k._count.santris,
        absensiHariIniTerisi: kelasTerisi.has(k.id),
        jumlahMapel: diampu.size,
        mapelTerisiHariIni: terisiMilikku,
      };
    });
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

  private async tenantDashboard(tenantId: string, lihatNama: boolean) {
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

    // Kepatuhan rekap absensi: rombel dianggap terisi kalau SEMUA mapel
    // yang diajarkan di kelas itu sudah diabsen hari ini (WIB).
    const hariIniWib = new Date(Date.now() + 7 * 3600 * 1000).toISOString().slice(0, 10);
    const awalWib = new Date(`${hariIniWib}T00:00:00+07:00`);
    const akhirWib = new Date(awalWib.getTime() + 24 * 3600 * 1000);

    const [absensiHariIni, pengampu] = await Promise.all([
      this.prisma.absensi.findMany({
        where: {
          tenantId,
          kelasId: { not: null },
          tanggal: { gte: awalWib, lt: akhirWib },
        },
        select: { kelasId: true, mapelId: true },
      }),
      this.prisma.ustadzMengajar.findMany({
        where: { tenantId },
        select: { kelasId: true, mapelId: true },
      }),
    ]);

    // kelasId -> mapel yang seharusnya diabsen
    const mapelWajib = new Map<string, Set<string>>();
    for (const m of pengampu) {
      if (!mapelWajib.has(m.kelasId)) mapelWajib.set(m.kelasId, new Set());
      mapelWajib.get(m.kelasId)!.add(m.mapelId);
    }
    // kelasId -> mapel yang sudah diabsen hari ini
    const mapelSudah = new Map<string, Set<string>>();
    for (const a of absensiHariIni) {
      if (!a.kelasId) continue;
      if (!mapelSudah.has(a.kelasId)) mapelSudah.set(a.kelasId, new Set());
      if (a.mapelId) mapelSudah.get(a.kelasId)!.add(a.mapelId);
    }
    const kelasAdaAbsensi = new Set(
      absensiHariIni.map((a) => a.kelasId).filter((x): x is string => !!x),
    );
    // Log aktivitas memuat nama pengguna/aksi, jadi hanya untuk Admin & Pimpinan.
    const logAktivitas = lihatNama ? await this.audit.recentTenant(tenantId, 5) : [];

    // Audit kelengkapan data master
    const [
      santriTanpaKelas,
      santriTanpaWali,
      santriTanpaTglLahir,
      kelasTanpaWali,
      ustadzTanpaAkun,
    ] = await Promise.all([
      this.prisma.santri.count({ where: { tenantId, status: 'AKTIF', kelasId: null } }),
      this.prisma.santri.count({ where: { tenantId, status: 'AKTIF', waliId: null } }),
      this.prisma.santri.count({ where: { tenantId, status: 'AKTIF', tanggalLahir: null } }),
      this.prisma.kelas.count({ where: { tenantId, waliKelasId: null } }),
      this.prisma.ustadz.count({ where: { tenantId, userId: null } }),
    ]);

    const auditKelengkapan = [
      santriTanpaKelas > 0 && {
        judul: `${santriTanpaKelas} santri aktif belum punya kelas`,
        deskripsi: 'Plot santri ke rombel',
        aksi: 'Lihat',
        tujuan: 'santri',
      },
      santriTanpaWali > 0 && {
        judul: `${santriTanpaWali} santri aktif belum punya wali`,
        deskripsi: 'Data wali wajib diisi',
        aksi: 'Lengkapi',
        tujuan: 'santri',
      },
      santriTanpaTglLahir > 0 && {
        judul: `${santriTanpaTglLahir} santri belum ada tanggal lahir`,
        deskripsi: 'Dibutuhkan untuk penomoran ijazah',
        aksi: 'Lengkapi',
        tujuan: 'santri',
      },
      kelasTanpaWali > 0 && {
        judul: `${kelasTanpaWali} kelas belum punya wali kelas`,
        deskripsi: 'Tentukan wali kelas di rombel',
        aksi: 'Atur',
        tujuan: 'kelas',
      },
      ustadzTanpaAkun > 0 && {
        judul: `${ustadzTanpaAkun} ustadz belum punya akun login`,
        deskripsi: 'Buat akun agar bisa masuk',
        aksi: 'Buat',
        tujuan: 'ustadz',
      },
    ].filter(Boolean);
    const idKelasTenant = new Set(distribusiKelas.map((k) => k.id));
    const rombelTerisi = [...idKelasTenant].filter((id) => {
      const wajib = mapelWajib.get(id);
      if (!wajib || wajib.size === 0) return kelasAdaAbsensi.has(id); // aturan lama
      const sudah = mapelSudah.get(id) ?? new Set<string>();
      return [...wajib].every((m) => sudah.has(m));
    }).length;
    const kepatuhanAbsensi = {
      terisi: rombelTerisi,
      total: distribusiKelas.length,
    };

    // ---- BARU: kehadiran hari ini per status ----
    const absensiPerStatus = await this.prisma.absensi.groupBy({
      by: ['status'],
      where: { tenantId, tanggal: { gte: todayStart, lte: todayEnd } },
      _count: true,
    });
    const kehadiranHariIni: Record<string, number> = { hadir: 0, izin: 0, sakit: 0, alpa: 0 };
    for (const r of absensiPerStatus) kehadiranHariIni[r.status.toLowerCase()] = r._count;

    // ---- BARU: santri sakit yang masih aktif (unik per santri) ----
    const logKesehatanTerakhir = await this.prisma.kesehatanLog.findMany({
      where: { tenantId },
      orderBy: [{ tanggal: 'desc' }, { createdAt: 'desc' }],
      distinct: ['santriId'],
      select: { santriId: true, status: true },
    });
    const sakitAktif = logKesehatanTerakhir.filter(
      (l) => l.status === 'RAWAT_JALAN' || l.status === 'DIRUJUK',
    );

    // ---- BARU: izin di luar, terlambat, kunjungan wali ----
    const sekarang = new Date();
    const awalBulan = new Date(sekarang.getFullYear(), sekarang.getMonth(), 1);
    const [izinDiLuar, izinTerlambat, kunjunganBulanIni] = await Promise.all([
    // Sedang di luar: disetujui, belum tercatat kembali
      this.prisma.perizinan.count({
        where: { tenantId, statusApproval: 'DISETUJUI', tanggalKembali: null },
      }),
      // Tercatat telat (sudah ditandai TELAT oleh Musyrif/Admin)
            // Terlambat: sudah ditandai TELAT, atau masih di luar dan lewat batas kembali
      this.prisma.perizinan.count({
        where: {
          tenantId,
          tanggalKembali: null, // hanya yang belum kembali
          OR: [
            { statusApproval: 'TELAT' },
            { statusApproval: 'DISETUJUI', rencanaKembali: { lt: sekarang } },
          ],
        },
      }),
      this.prisma.kunjunganWali.count({ where: { tenantId, tanggal: { gte: awalBulan } } }),
    ]);

        // ---- BARU: rekap pelanggaran per kelas & per santri (berdasarkan poin) ----
    const semuaPelanggaran = await this.prisma.pelanggaran.findMany({
    where: { tenantId },
    orderBy: { tanggal: 'desc' },
    select: {
      poin: true,
      jenisPelanggaran: true,
      santri: {
        select: {
          id: true,
          nama: true,
          kelas: { select: { id: true, namaKelas: true } },
        },
      },
    },
  });

    const perKelasMap = new Map<string, { kelas: string; jumlah: number; poin: number }>();
    const perSantriMap = new Map<
    string,
    {
      santriId: string;
      nama: string;
      kelas: string;
      jumlah: number;
      poin: number;
      jenis: string[];
    }
  >();
    for (const p of semuaPelanggaran) {
      const namaKelas = p.santri.kelas?.namaKelas ?? 'Tanpa kelas';
      const kKey = p.santri.kelas?.id ?? '_tanpa';
      const k = perKelasMap.get(kKey) ?? { kelas: namaKelas, jumlah: 0, poin: 0 };
      k.jumlah += 1;
      k.poin += p.poin;
      perKelasMap.set(kKey, k);

      const s = perSantriMap.get(p.santri.id) ?? {
        santriId: p.santri.id,
        nama: p.santri.nama,
        kelas: namaKelas,
        jumlah: 0,
        poin: 0,
        jenis: [] as string[],
      };
      s.jumlah += 1;
      s.poin += p.poin;
      if (
        s.jenis.length < 2 &&
        p.jenisPelanggaran &&
        !s.jenis.includes(p.jenisPelanggaran)
      ) {
        s.jenis.push(p.jenisPelanggaran);
      }
      perSantriMap.set(p.santri.id, s);
    }
    const rekapPelanggaran = {
      perKelas: [...perKelasMap.values()].sort((a, b) => b.poin - a.poin),
            topSantri: lihatNama
        ? [...perSantriMap.values()].sort((a, b) => b.poin - a.poin).slice(0, 5)
        : [],
    };

    // ---- BARU: capaian tahfidz ----
    const HARI_TERTINGGAL = 14;
    const batasTertinggal = new Date(Date.now() - HARI_TERTINGGAL * 24 * 60 * 60 * 1000);
    const tigaPuluhHariLalu = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const santriAktifList = await this.prisma.santri.findMany({
      where: { tenantId, status: 'AKTIF' },
      select: { id: true, nama: true, kelas: { select: { namaKelas: true } } },
    });
    const idAktif = santriAktifList.map((s) => s.id);

    const [juzDistinct, terakhirSetor, setoran30Hari] = await Promise.all([
      this.prisma.capaianTahfidz.findMany({
        where: { tenantId, santriId: { in: idAktif }, jenis: 'ZIYADAH' },
        distinct: ['santriId', 'juz'],
        select: { santriId: true },
      }),
      this.prisma.capaianTahfidz.groupBy({
        by: ['santriId'],
        where: { tenantId, santriId: { in: idAktif } },
        _max: { tanggalSetor: true },
      }),
      this.prisma.capaianTahfidz.count({
        where: { tenantId, santriId: { in: idAktif }, tanggalSetor: { gte: tigaPuluhHariLalu } },
      }),
    ]);

    const terakhirMap = new Map(terakhirSetor.map((r) => [r.santriId, r._max.tanggalSetor]));
    const tertinggalAll = santriAktifList
      .map((s) => {
        const t = terakhirMap.get(s.id) ?? null;
        return {
          nama: s.nama,
          kelas: s.kelas?.namaKelas ?? 'Tanpa kelas',
          hariSejak: t ? Math.floor((Date.now() - t.getTime()) / 86400000) : null,
          _belum: t === null || t < batasTertinggal,
        };
      })
      .filter((s) => s._belum)
      // yang belum pernah setor paling atas, lalu yang paling lama
      .sort((a, b) => (b.hariSejak ?? 1e9) - (a.hariSejak ?? 1e9));

    const tahfidz = {
      rataJuz: idAktif.length > 0 ? juzDistinct.length / idAktif.length : 0,
      jumlahSantri: idAktif.length,
      setoran30Hari,
      hariTertinggal: HARI_TERTINGGAL,
      jumlahTertinggal: tertinggalAll.length,
      tertinggal: lihatNama
        ? tertinggalAll.slice(0, 5).map(({ _belum, ...r }) => r)
        : [],
    };

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
        santriSakitAktif: sakitAktif.length, // BARU
        izinDiLuar,                          // BARU
        izinTerlambat,                       // BARU
        kunjunganBulanIni,                   // BARU
      },
      kehadiranHariIni, // BARU
      rekapPelanggaran, // BARU
      tahfidz,          // BARU
      distribusiKelas,
      pelanggaranPerHari,
      kepatuhanAbsensi,
      logAktivitas,
      auditKelengkapan,
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

    const anak = await Promise.all(
      wali.santris.map(async (s) => {
        const [totalAbsen, hadir, poin, izinAktif, juzList] = await Promise.all([
          this.prisma.absensi.count({ where: { santriId: s.id } }),
          this.prisma.absensi.count({ where: { santriId: s.id, status: 'HADIR' } }),
          this.prisma.pelanggaran.aggregate({
            where: { santriId: s.id },
            _sum: { poin: true },
          }),
          this.prisma.perizinan.count({
            where: {
              santriId: s.id,
              statusApproval: { in: ['DISETUJUI', 'TELAT'] },
            },
          }),
          this.prisma.capaianTahfidz.findMany({
            where: { santriId: s.id, jenis: 'ZIYADAH' },
            distinct: ['juz'],
            select: { juz: true },
          }),
        ]);

        return {
          ...s,
          ringkasan: {
            kehadiranPersen: totalAbsen > 0 ? Math.round((hadir / totalAbsen) * 100) : null,
            poinPelanggaran: poin._sum.poin ?? 0,
            izinAktif,
            juzTahfidz: juzList.length > 0 ? juzList.length : null,
          },
        };
      }),
    );

    return {
      role: 'WALI_SANTRI',
      namaPengguna: wali.nama,
      wali: { id: wali.id, nama: wali.nama, hubungan: wali.hubungan },
      anak,
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