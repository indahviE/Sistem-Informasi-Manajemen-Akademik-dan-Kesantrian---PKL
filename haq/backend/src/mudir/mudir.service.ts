// src/mudir/mudir.service.ts  (FILE BARU, khusus role PIMPINAN / Mudir)
//
// Isi: ringkasan akademik, tren lintas modul, dan laporan rekap per tahun ajaran.
// Semua query dibatasi tenantId (data terisolasi per pondok).
//
// CATATAN PENTING:
// 1. Model TahunAjaran di schema hanya punya `nama` dan `aktif`, TIDAK punya tanggal mulai/selesai.
//    Jadi rentang tanggal diturunkan dari nama, mis. "2025/2026" => 1 Juli 2025 s.d. 30 Juni 2026.
//    Kalau nama tidak berpola begitu, kirim `dari` dan `sampai` (YYYY-MM-DD) secara manual.
// 2. Data dikaitkan ke tahun ajaran lewat Santri -> Kelas -> tahunAjaranId.
// 3. Import PrismaService di bawah mengikuti pola umum NestJS. Sesuaikan path kalau di proyekmu beda.

import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Prisma, SantriStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

export type Granularitas = 'minggu' | 'bulan';

interface Periode {
  tahunAjaran: { id: string; nama: string };
  dari: string; // YYYY-MM-DD (WIB)
  sampai: string; // YYYY-MM-DD (WIB), inklusif
  awal: Date; // awal hari "dari" pukul 00:00 WIB (untuk kolom DateTime)
  akhir: Date; // awal hari setelah "sampai" pukul 00:00 WIB (eksklusif)
  awalTgl: Date; // untuk kolom @db.Date (Nilai.tanggal)
  akhirTgl: Date; // eksklusif, untuk kolom @db.Date
}

const WIB = '+07:00';

const adaFormatTanggal = (s?: string) =>
  !!s && /^\d{4}-\d{2}-\d{2}$/.test(s) && !isNaN(new Date(`${s}T00:00:00Z`).getTime());

const tambahHari = (s: string, n: number) => {
  const d = new Date(`${s}T00:00:00Z`);
  d.setUTCDate(d.getUTCDate() + n);
  return d.toISOString().slice(0, 10);
};

const keYmd = (v: Date | string) =>
  typeof v === 'string' ? v.slice(0, 10) : v.toISOString().slice(0, 10);

const bulatkan = (v: unknown, digit = 1) => {
  const n = Number(v);
  if (!isFinite(n)) return null;
  const f = 10 ** digit;
  return Math.round(n * f) / f;
};

function kunciPeriode(hari: string, g: Granularitas): string {
  if (g === 'bulan') return hari.slice(0, 7);
  const d = new Date(`${hari}T00:00:00Z`);
  const mundur = (d.getUTCDay() + 6) % 7; // Senin = awal minggu
  d.setUTCDate(d.getUTCDate() - mundur);
  return d.toISOString().slice(0, 10);
}

@Injectable()
export class MudirService {
  constructor(private prisma: PrismaService) {}

  // Daftar tahun ajaran untuk pemilih periode di aplikasi
  async daftarTahunAjaran(tenantId: string) {
    return this.prisma.tahunAjaran.findMany({
      where: { tenantId },
      select: { id: true, nama: true, aktif: true },
      orderBy: { nama: 'desc' },
    });
  }

  // ---------------------------------------------------------------------------
  // Periode: tahun ajaran -> rentang tanggal WIB
  // ---------------------------------------------------------------------------
  private async tentukanPeriode(
    tenantId: string,
    tahunAjaranId?: string,
    dari?: string,
    sampai?: string,
  ): Promise<Periode> {
    const ta = tahunAjaranId
      ? await this.prisma.tahunAjaran.findFirst({ where: { id: tahunAjaranId, tenantId } })
      : await this.prisma.tahunAjaran.findFirst({
          where: { tenantId, aktif: true },
          orderBy: { nama: 'desc' },
        });
    if (!ta) throw new NotFoundException('Tahun ajaran tidak ditemukan untuk pondok ini');

    let d = dari;
    let s = sampai;
    if (!adaFormatTanggal(d) || !adaFormatTanggal(s)) {
      const m = ta.nama.match(/(\d{4})\s*[\/\-]\s*(\d{4})/);
      if (!m) {
        throw new BadRequestException(
          `Rentang tanggal tahun ajaran "${ta.nama}" tidak bisa diturunkan dari namanya. Kirim parameter dari dan sampai (YYYY-MM-DD).`,
        );
      }
      d = `${m[1]}-07-01`;
      s = `${m[2]}-06-30`;
    }
    if (d! > s!) throw new BadRequestException('Tanggal "dari" tidak boleh setelah "sampai"');

    const akhirYmd = tambahHari(s!, 1);
    return {
      tahunAjaran: { id: ta.id, nama: ta.nama },
      dari: d!,
      sampai: s!,
      awal: new Date(`${d}T00:00:00${WIB}`),
      akhir: new Date(`${akhirYmd}T00:00:00${WIB}`),
      awalTgl: new Date(`${d}T00:00:00Z`),
      akhirTgl: new Date(`${akhirYmd}T00:00:00Z`),
    };
  }

  // ---------------------------------------------------------------------------
  // 1. Ringkasan akademik
  // ---------------------------------------------------------------------------
  async ringkasanAkademik(tenantId: string, tahunAjaranId?: string, dari?: string, sampai?: string) {
    const p = await this.tentukanPeriode(tenantId, tahunAjaranId, dari, sampai);
    const taId = p.tahunAjaran.id;
    const scopeSantri = { kelas: { tahunAjaranId: taId } };

    const [jumlahPerKelas, rataKelasMapel, bawahKkmRows, totalUjian, ujianDikunci, remedial, rapor] =
      await Promise.all([
        this.prisma.santri.groupBy({
          by: ['kelasId'],
          where: { tenantId, status: SantriStatus.AKTIF, ...scopeSantri },
          _count: { _all: true },
        }),
        this.prisma.$queryRaw<
          { kelasId: string; namaKelas: string; mapelId: string; namaMapel: string; kkm: number; rata: unknown; jumlah: bigint }[]
        >(Prisma.sql`
          SELECT s.kelasId AS kelasId, k.namaKelas AS namaKelas, n.mapelId AS mapelId,
                 m.namaMapel AS namaMapel, m.kkm AS kkm, AVG(n.nilai) AS rata, COUNT(*) AS jumlah
          FROM nilais n
          JOIN santris s ON s.id = n.santriId AND s.tenantId = ${tenantId}
          JOIN kelas k ON k.id = s.kelasId AND k.tenantId = ${tenantId}
          JOIN mata_pelajarans m ON m.id = n.mapelId AND m.tenantId = ${tenantId}
          WHERE n.tenantId = ${tenantId}
            AND k.tahunAjaranId = ${taId}
            AND n.tanggal >= ${p.awalTgl} AND n.tanggal < ${p.akhirTgl}
          GROUP BY s.kelasId, k.namaKelas, n.mapelId, m.namaMapel, m.kkm
          ORDER BY k.namaKelas, m.namaMapel
        `),
        this.prisma.$queryRaw<
          { santriId: string; nama: string; namaKelas: string; namaMapel: string; kkm: number; rata: unknown }[]
        >(Prisma.sql`
          SELECT s.id AS santriId, s.nama AS nama, k.namaKelas AS namaKelas,
                 m.namaMapel AS namaMapel, m.kkm AS kkm, AVG(n.nilai) AS rata
          FROM nilais n
          JOIN santris s ON s.id = n.santriId AND s.tenantId = ${tenantId}
          JOIN kelas k ON k.id = s.kelasId AND k.tenantId = ${tenantId}
          JOIN mata_pelajarans m ON m.id = n.mapelId AND m.tenantId = ${tenantId}
          WHERE n.tenantId = ${tenantId}
            AND k.tahunAjaranId = ${taId}
            AND s.status = 'AKTIF'
            AND n.tanggal >= ${p.awalTgl} AND n.tanggal < ${p.akhirTgl}
          GROUP BY s.id, s.nama, k.namaKelas, m.id, m.namaMapel, m.kkm
          HAVING AVG(n.nilai) < m.kkm
          ORDER BY rata ASC
          LIMIT 5000
        `),
        this.prisma.ujian.count({ where: { tenantId, kelas: { tahunAjaranId: taId } } }),
        this.prisma.ujian.count({
          where: { tenantId, kelas: { tahunAjaranId: taId }, dikunciPada: { not: null } },
        }),
        this.prisma.remedial.groupBy({
          by: ['status'],
          where: { tenantId, santri: scopeSantri },
          _count: { _all: true },
        }),
        this.prisma.rapor.groupBy({
          by: ['status'],
          where: { tenantId, santri: scopeSantri },
          _count: { _all: true },
          _avg: { rataRata: true },
        }),
      ]);

    const kelasList = await this.prisma.kelas.findMany({
      where: { tenantId, tahunAjaranId: taId },
      select: { id: true, namaKelas: true },
      orderBy: { namaKelas: 'asc' },
    });
    const jumlahMap = new Map(jumlahPerKelas.map((r) => [r.kelasId, r._count._all]));

    return {
      tahunAjaran: p.tahunAjaran,
      periode: { dari: p.dari, sampai: p.sampai },
      perKelas: kelasList.map((k) => ({
        kelasId: k.id,
        namaKelas: k.namaKelas,
        santriAktif: jumlahMap.get(k.id) ?? 0,
      })),
      rataNilai: rataKelasMapel.map((r) => ({
        kelasId: r.kelasId,
        namaKelas: r.namaKelas,
        mapelId: r.mapelId,
        namaMapel: r.namaMapel,
        kkm: Number(r.kkm),
        rata: bulatkan(r.rata),
        jumlahNilai: Number(r.jumlah),
        dibawahKkm: Number(r.rata) < Number(r.kkm),
      })),
      santriDibawahKkm: {
        total: bawahKkmRows.length,
        daftar: bawahKkmRows.slice(0, 20).map((r) => ({
          santriId: r.santriId,
          nama: r.nama,
          namaKelas: r.namaKelas,
          namaMapel: r.namaMapel,
          kkm: Number(r.kkm),
          rata: bulatkan(r.rata),
        })),
      },
      ujian: {
        total: totalUjian,
        dikunci: ujianDikunci,
        belumDikunci: totalUjian - ujianDikunci,
      },
      remedial: Object.fromEntries(remedial.map((r) => [r.status, r._count._all])),
      rapor: {
        perStatus: Object.fromEntries(rapor.map((r) => [r.status, r._count._all])),
        rataRata: bulatkan(
          rapor.reduce((a, r) => a + (r._avg.rataRata ?? 0) * r._count._all, 0) /
            Math.max(1, rapor.reduce((a, r) => a + (r._avg.rataRata == null ? 0 : r._count._all), 0)),
        ),
      },
    };
  }

  // ---------------------------------------------------------------------------
  // 2. Tren lintas modul (kehadiran, pelanggaran, tahfidz, nilai)
  // ---------------------------------------------------------------------------
  async tren(
    tenantId: string,
    tahunAjaranId?: string,
    granularitas: Granularitas = 'bulan',
    dari?: string,
    sampai?: string,
  ) {
    const g: Granularitas = granularitas === 'minggu' ? 'minggu' : 'bulan';
    const p = await this.tentukanPeriode(tenantId, tahunAjaranId, dari, sampai);
    const taId = p.tahunAjaran.id;

    const [absensi, pelanggaran, tahfidz, nilai] = await Promise.all([
      this.prisma.$queryRaw<{ hari: Date | string; status: string; n: bigint }[]>(Prisma.sql`
        SELECT DATE(CONVERT_TZ(a.tanggal, '+00:00', '+07:00')) AS hari, a.status AS status, COUNT(*) AS n
        FROM absensis a
        JOIN santris s ON s.id = a.santriId AND s.tenantId = ${tenantId}
        JOIN kelas k ON k.id = s.kelasId AND k.tenantId = ${tenantId}
        WHERE a.tenantId = ${tenantId} AND k.tahunAjaranId = ${taId}
          AND a.tanggal >= ${p.awal} AND a.tanggal < ${p.akhir}
        GROUP BY hari, a.status
      `),
      this.prisma.$queryRaw<{ hari: Date | string; n: bigint; poin: bigint | null }[]>(Prisma.sql`
        SELECT DATE(CONVERT_TZ(x.tanggal, '+00:00', '+07:00')) AS hari, COUNT(*) AS n, SUM(x.poin) AS poin
        FROM pelanggarans x
        JOIN santris s ON s.id = x.santriId AND s.tenantId = ${tenantId}
        JOIN kelas k ON k.id = s.kelasId AND k.tenantId = ${tenantId}
        WHERE x.tenantId = ${tenantId} AND k.tahunAjaranId = ${taId}
          AND x.tanggal >= ${p.awal} AND x.tanggal < ${p.akhir}
        GROUP BY hari
      `),
      this.prisma.$queryRaw<{ hari: Date | string; n: bigint }[]>(Prisma.sql`
        SELECT DATE(CONVERT_TZ(t.tanggalSetor, '+00:00', '+07:00')) AS hari, COUNT(*) AS n
        FROM capaian_tahfidzs t
        JOIN santris s ON s.id = t.santriId AND s.tenantId = ${tenantId}
        JOIN kelas k ON k.id = s.kelasId AND k.tenantId = ${tenantId}
        WHERE t.tenantId = ${tenantId} AND k.tahunAjaranId = ${taId}
          AND t.tanggalSetor >= ${p.awal} AND t.tanggalSetor < ${p.akhir}
        GROUP BY hari
      `),
      this.prisma.$queryRaw<{ hari: Date | string; total: unknown; n: bigint }[]>(Prisma.sql`
        SELECT n.tanggal AS hari, SUM(n.nilai) AS total, COUNT(*) AS n
        FROM nilais n
        JOIN santris s ON s.id = n.santriId AND s.tenantId = ${tenantId}
        JOIN kelas k ON k.id = s.kelasId AND k.tenantId = ${tenantId}
        WHERE n.tenantId = ${tenantId} AND k.tahunAjaranId = ${taId}
          AND n.tanggal >= ${p.awalTgl} AND n.tanggal < ${p.akhirTgl}
        GROUP BY n.tanggal
      `),
    ]);

    type Baris = {
      hadir: number; izin: number; sakit: number; alpa: number;
      pelanggaran: number; poinPelanggaran: number; setoranTahfidz: number;
      nilaiTotal: number; nilaiJumlah: number;
    };
    const peta = new Map<string, Baris>();
    const ambil = (hari: Date | string) => {
      const key = kunciPeriode(keYmd(hari), g);
      let b = peta.get(key);
      if (!b) {
        b = { hadir: 0, izin: 0, sakit: 0, alpa: 0, pelanggaran: 0, poinPelanggaran: 0, setoranTahfidz: 0, nilaiTotal: 0, nilaiJumlah: 0 };
        peta.set(key, b);
      }
      return b;
    };

    for (const r of absensi) {
      const b = ambil(r.hari);
      const n = Number(r.n);
      if (r.status === 'HADIR') b.hadir += n;
      else if (r.status === 'IZIN') b.izin += n;
      else if (r.status === 'SAKIT') b.sakit += n;
      else if (r.status === 'ALPA') b.alpa += n;
    }
    for (const r of pelanggaran) {
      const b = ambil(r.hari);
      b.pelanggaran += Number(r.n);
      b.poinPelanggaran += Number(r.poin ?? 0);
    }
    for (const r of tahfidz) ambil(r.hari).setoranTahfidz += Number(r.n);
    for (const r of nilai) {
      const b = ambil(r.hari);
      b.nilaiTotal += Number(r.total);
      b.nilaiJumlah += Number(r.n);
    }

    const data = [...peta.entries()]
      .sort(([a], [b]) => (a < b ? -1 : 1))
      .map(([periode, b]) => {
        const totalAbsen = b.hadir + b.izin + b.sakit + b.alpa;
        return {
          periode,
          hadir: b.hadir,
          izin: b.izin,
          sakit: b.sakit,
          alpa: b.alpa,
          persenHadir: totalAbsen ? bulatkan((b.hadir / totalAbsen) * 100) : null,
          pelanggaran: b.pelanggaran,
          poinPelanggaran: b.poinPelanggaran,
          setoranTahfidz: b.setoranTahfidz,
          rataNilai: b.nilaiJumlah ? bulatkan(b.nilaiTotal / b.nilaiJumlah) : null,
        };
      });

    return {
      tahunAjaran: p.tahunAjaran,
      periode: { dari: p.dari, sampai: p.sampai },
      granularitas: g,
      data,
    };
  }

  // ---------------------------------------------------------------------------
  // 3. Laporan rekap per tahun ajaran (data JSON untuk layar Flutter)
  // ---------------------------------------------------------------------------
  async laporan(tenantId: string, tahunAjaranId?: string, dari?: string, sampai?: string) {
    const p = await this.tentukanPeriode(tenantId, tahunAjaranId, dari, sampai);
    const scopeSantri = { kelas: { tahunAjaranId: p.tahunAjaran.id } };
    const rentang = { gte: p.awal, lt: p.akhir };

    const [
      totalSantriAktif,
      absensi,
      pelanggaranJenis,
      pelanggaranTop,
      tahfidzJenis,
      tahfidzSantri,
      perizinan,
    ] = await Promise.all([
      this.prisma.santri.count({ where: { tenantId, status: SantriStatus.AKTIF, ...scopeSantri } }),
      this.prisma.absensi.groupBy({
        by: ['status'],
        where: { tenantId, santri: scopeSantri, tanggal: rentang },
        _count: { _all: true },
      }),
      this.prisma.pelanggaran.groupBy({
        by: ['jenisPelanggaran'],
        where: { tenantId, santri: scopeSantri, tanggal: rentang },
        _count: { _all: true },
        _sum: { poin: true },
        orderBy: { _count: { jenisPelanggaran: 'desc' } },
        take: 10,
      }),
      this.prisma.pelanggaran.groupBy({
        by: ['santriId'],
        where: { tenantId, santri: scopeSantri, tanggal: rentang },
        _count: { _all: true },
        _sum: { poin: true },
        orderBy: { _sum: { poin: 'desc' } },
        take: 10,
      }),
      this.prisma.capaianTahfidz.groupBy({
        by: ['jenis'],
        where: { tenantId, santri: scopeSantri, tanggalSetor: rentang },
        _count: { _all: true },
      }),
      this.prisma.capaianTahfidz.groupBy({
        by: ['santriId'],
        where: { tenantId, santri: scopeSantri, tanggalSetor: rentang },
      }),
      this.prisma.perizinan.groupBy({
        by: ['statusApproval'],
        where: { tenantId, santri: scopeSantri, tanggalKeluar: rentang },
        _count: { _all: true },
      }),
    ]);

    const namaSantri = pelanggaranTop.length
      ? await this.prisma.santri.findMany({
          where: { tenantId, id: { in: pelanggaranTop.map((r) => r.santriId) } },
          select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } },
        })
      : [];
    const santriMap = new Map(namaSantri.map((s) => [s.id, s]));

    const hitungAbsen = Object.fromEntries(absensi.map((r) => [r.status, r._count._all])) as Record<string, number>;
    const totalAbsen = absensi.reduce((a, r) => a + r._count._all, 0);

    const akademik = await this.ringkasanAkademik(tenantId, p.tahunAjaran.id, p.dari, p.sampai);

    return {
      tahunAjaran: p.tahunAjaran,
      periode: { dari: p.dari, sampai: p.sampai },
      santriAktif: totalSantriAktif,
      kehadiran: {
        hadir: hitungAbsen.HADIR ?? 0,
        izin: hitungAbsen.IZIN ?? 0,
        sakit: hitungAbsen.SAKIT ?? 0,
        alpa: hitungAbsen.ALPA ?? 0,
        persenHadir: totalAbsen ? bulatkan(((hitungAbsen.HADIR ?? 0) / totalAbsen) * 100) : null,
      },
      pelanggaran: {
        perJenis: pelanggaranJenis.map((r) => ({
          jenis: r.jenisPelanggaran,
          jumlah: r._count._all,
          poin: r._sum.poin ?? 0,
        })),
        santriPoinTertinggi: pelanggaranTop.map((r) => ({
          santriId: r.santriId,
          nama: santriMap.get(r.santriId)?.nama ?? null,
          nis: santriMap.get(r.santriId)?.nis ?? null,
          kelas: santriMap.get(r.santriId)?.kelas?.namaKelas ?? null,
          jumlah: r._count._all,
          poin: r._sum.poin ?? 0,
        })),
      },
      tahfidz: {
        totalSetoran: tahfidzJenis.reduce((a, r) => a + r._count._all, 0),
        perJenis: Object.fromEntries(tahfidzJenis.map((r) => [r.jenis, r._count._all])),
        santriYangSetor: tahfidzSantri.length,
      },
      perizinan: Object.fromEntries(perizinan.map((r) => [r.statusApproval, r._count._all])),
      akademik: {
        rataNilai: akademik.rataNilai,
        santriDibawahKkm: akademik.santriDibawahKkm.total,
        ujian: akademik.ujian,
        remedial: akademik.remedial,
        rapor: akademik.rapor,
      },
    };
  }
}