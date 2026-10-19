import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import {
  JenisNotifikasi,
  Role,
  SantriStatus,
  StatusKehadiranUjian,
  TenantStatus,
} from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotifikasiService } from './notifikasi.service';

/** Hari ke-berapa setelah tanggal ujian pengingat nilai dikirim (mode cron). */
const HARI_PENGINGAT_NILAI = [1, 3, 7];
const MS_HARI = 24 * 3600 * 1000;
const MS_WIB = 7 * 3600 * 1000;

@Injectable()
export class NotifikasiScheduler {
  private readonly logger = new Logger(NotifikasiScheduler.name);

  constructor(
    private prisma: PrismaService,
    private notifikasi: NotifikasiService,
  ) {}

  /**
   * Dipanggil saat ustadz membuka dashboard / aplikasi.
   * Menjalankan pengecekan absensi & nilai khusus untuk satu user.
   * Aman dipanggil berulang: dedupe per hari mencegah notifikasi dobel.
   */
  async cekPengingatUntukUser(userId: string, tenantId: string) {
    await this.pengingatAbsensiUstadz(userId, tenantId);
    await this.pengingatNilaiUstadz(userId, tenantId);
  }

  /** Tiap hari 08:00 WIB: ingatkan wali yang belum punya akun (maks sekali per 7 hari per tenant). */
  @Cron('0 8 * * *', { timeZone: 'Asia/Jakarta' })
  async waliBelumAktivasi() {
    try {
      const tenants = await this.prisma.tenant.findMany({
        where: { status: TenantStatus.AKTIF, deletedAt: null },
        select: { id: true },
      });
      const tujuhHariLalu = new Date(Date.now() - 7 * 24 * 3600 * 1000);

      for (const t of tenants) {
        const jumlah = await this.prisma.waliSantri.count({
          where: {
            tenantId: t.id,
            userId: null,
            santris: { some: { status: SantriStatus.AKTIF } },
          },
        });
        if (jumlah === 0) continue;

        const sudahKirim = await this.prisma.notifikasi.count({
          where: {
            tenantId: t.id,
            jenis: JenisNotifikasi.WALI_BELUM_AKTIVASI,
            tanggal: { gte: tujuhHariLalu },
          },
        });
        if (sudahKirim > 0) continue;

        await this.notifikasi.kirimKeAdminTenant(
          t.id,
          JenisNotifikasi.WALI_BELUM_AKTIVASI,
          `${jumlah} wali santri belum mengaktifkan akun portal. Segera generate kredensial atau ingatkan wali.`,
        );
      }
    } catch (e) {
      this.logger.error(`Cron wali belum aktivasi gagal: ${(e as Error).message}`);
    }
  }

  /** Tiap hari 20:30 WIB (setelah Isya): kirim rekap kehadiran ibadah hari ini. */
  @Cron('30 20 * * *', { timeZone: 'Asia/Jakarta' })
  async rekapAbsensiShalat() {
    try {
      // Awal hari ini menurut WIB, dalam UTC.
      const wib = new Date(Date.now() + 7 * 3600 * 1000);
      const mulai = new Date(
        Date.UTC(wib.getUTCFullYear(), wib.getUTCMonth(), wib.getUTCDate()) - 7 * 3600 * 1000,
      );

      const grup = await this.prisma.pembinaanIbadah.groupBy({
        by: ['tenantId', 'status'],
        where: { tanggal: { gte: mulai } },
        _count: { _all: true },
      });

      const perTenant = new Map<string, { HADIR: number; IZIN: number; ALPA: number }>();
      for (const g of grup) {
        const r = perTenant.get(g.tenantId) ?? { HADIR: 0, IZIN: 0, ALPA: 0 };
        r[g.status] = g._count._all;
        perTenant.set(g.tenantId, r);
      }

      for (const [tenantId, r] of perTenant) {
        await this.notifikasi.kirimKeAdminTenant(
          tenantId,
          JenisNotifikasi.ABSENSI,
          `Rekap ibadah hari ini: ${r.HADIR} hadir, ${r.IZIN} izin, ${r.ALPA} alpa.`,
        );
      }
    } catch (e) {
      this.logger.error(`Cron rekap absensi shalat gagal: ${(e as Error).message}`);
    }
  }

  /**
   * Senin-Sabtu 08:00 WIB: ingatkan ustadz wali kelas yang absensi kelasnya
   * hari ini belum diisi. Hanya terkirim kalau toggle "Pengingat Absensi"
   * ustadz menyala, dan maksimal sekali per kelas per hari.
   *
   * Mode on-open: kalau filterUserId diisi, hanya memproses kelas milik user
   * itu (Senin-Sabtu saja), tanpa menunggu jam cron.
   */
  @Cron('0 8 * * 1-6', { timeZone: 'Asia/Jakarta' })
  async pengingatAbsensiUstadz(filterUserId?: string, filterTenantId?: string) {
    try {
      // Awal hari ini menurut WIB, dalam UTC.
      const wib = new Date(Date.now() + MS_WIB);

      // Cron sudah dibatasi Senin-Sabtu; mode on-open harus dicek manual (Minggu = 0).
      if (filterUserId && wib.getUTCDay() === 0) return;

      const mulai = new Date(
        Date.UTC(wib.getUTCFullYear(), wib.getUTCMonth(), wib.getUTCDate()) - MS_WIB,
      );
      const besok = new Date(mulai.getTime() + MS_HARI);

      const kelasList = await this.prisma.kelas.findMany({
        where: {
          tenant: { status: TenantStatus.AKTIF, deletedAt: null },
          ...(filterTenantId ? { tenantId: filterTenantId } : {}),
          waliKelas: { is: { userId: filterUserId ?? { not: null } } },
        },
        select: {
          id: true,
          tenantId: true,
          namaKelas: true,
          waliKelas: { select: { userId: true } },
        },
      });

      for (const k of kelasList) {
        const userId = k.waliKelas?.userId;
        if (!userId) continue;

        const santriAktif = await this.prisma.santri.count({
          where: { tenantId: k.tenantId, kelasId: k.id, status: SantriStatus.AKTIF },
        });
        if (santriAktif === 0) continue;

        const sudahAbsen = await this.prisma.absensi.count({
          where: {
            tenantId: k.tenantId,
            tanggal: { gte: mulai, lt: besok },
            santri: { kelasId: k.id },
          },
        });
        if (sudahAbsen > 0) continue;

        const pesan = `Absensi kelas ${k.namaKelas} hari ini belum diisi.`;
        const sudahKirim = await this.prisma.notifikasi.count({
          where: { userId, jenis: JenisNotifikasi.ABSENSI, pesan, tanggal: { gte: mulai } },
        });
        if (sudahKirim > 0) continue;

        await this.notifikasi.kirimKeUstadz(
          k.tenantId,
          userId,
          JenisNotifikasi.ABSENSI,
          'pengingatAbsensi',
          pesan,
        );
      }
    } catch (e) {
      this.logger.error(`Cron pengingat absensi ustadz gagal: ${(e as Error).message}`);
    }
  }

  /**
   * Tiap hari 08:00 WIB: ingatkan pemilik ujian yang nilainya belum lengkap.
   *
   * - Ujian sudah lewat dan belum dikunci. Ujian kelas tertentu maupun "semua kelas".
   * - Mode cron: dikirim di H+1, H+3, H+7 setelah tanggal ujian, lalu berhenti.
   * - Mode on-open (filterUserId diisi): semua ujian dalam 7 hari terakhir yang
   *   belum lengkap dan milik user itu, maksimal sekali per hari per ujian.
   * - "Belum diinput": santri aktif tanpa baris nilai, atau HADIR dengan nilai kosong.
   * - "Susulan": SAKIT/IZIN dengan nilai kosong. ALPA dianggap selesai.
   * - Penerima: pembuat ujian (kalau ustadz) -> wali kelas -> admin tenant.
   * - Penerima ustadz hanya dapat kalau toggle "Pengingat Input Nilai" menyala.
   */
  @Cron('0 8 * * *', { timeZone: 'Asia/Jakarta' })
  async pengingatNilaiUstadz(filterUserId?: string, filterTenantId?: string) {
    try {
      const hariIni = Math.floor((Date.now() + MS_WIB) / MS_HARI);
      // Awal hari ini menurut WIB, dalam UTC.
      const mulai = new Date(hariIni * MS_HARI - MS_WIB);
      const batasAwal = new Date(mulai.getTime() - Math.max(...HARI_PENGINGAT_NILAI) * MS_HARI);

      const ujians = await this.prisma.ujian.findMany({
        where: {
          tenant: { status: TenantStatus.AKTIF, deletedAt: null },
          ...(filterTenantId ? { tenantId: filterTenantId } : {}),
          dikunciPada: null,
          tanggal: { gte: batasAwal, lt: mulai },
        },
        select: {
          id: true,
          tenantId: true,
          nama: true,
          tanggal: true,
          dibuatOleh: true,
          kelasId: true,
          kelas: {
            select: { namaKelas: true, waliKelas: { select: { userId: true } } },
          },
        },
      });

      for (const u of ujians) {
        try {
          if (!u.tanggal) continue;

          const selisih = hariIni - Math.floor((u.tanggal.getTime() + MS_WIB) / MS_HARI);
          // Mode cron: hanya H+1/3/7. Mode on-open: semua yang masih dalam rentang 7 hari.
          if (!filterUserId && !HARI_PENGINGAT_NILAI.includes(selisih)) continue;

          // Tentukan penerima lebih awal supaya mode on-open bisa langsung skip
          // ujian yang bukan milik user ini (tanpa query santri/nilai).
          const userId = await this.cariPenerimaNilai(
            u.tenantId,
            u.dibuatOleh,
            u.kelas?.waliKelas?.userId ?? null,
          );
          if (filterUserId && userId !== filterUserId) continue;

          // kelasId kosong = ujian untuk semua kelas -> semua santri aktif di tenant.
          const santriAktif = await this.prisma.santri.findMany({
            where: {
              tenantId: u.tenantId,
              status: SantriStatus.AKTIF,
              ...(u.kelasId ? { kelasId: u.kelasId } : {}),
            },
            select: { id: true },
          });
          if (santriAktif.length === 0) continue;

          const nilaiList = await this.prisma.nilaiUjian.findMany({
            where: { ujianId: u.id },
            select: { santriId: true, nilai: true, status: true },
          });
          const nilaiMap = new Map(nilaiList.map((n) => [n.santriId, n]));

          let belum = 0;
          let susulan = 0;
          for (const s of santriAktif) {
            const n = nilaiMap.get(s.id);
            if (!n) {
              belum++;
            } else if (n.nilai === null) {
              if (n.status === StatusKehadiranUjian.HADIR) belum++;
              else if (n.status !== StatusKehadiranUjian.ALPA) susulan++;
            }
          }
          if (belum + susulan === 0) continue;

          const total = santriAktif.length;
          const dinilai = total - belum - susulan;

          const tgl = u.tanggal.toLocaleDateString('id-ID', {
            day: 'numeric',
            month: 'short',
            timeZone: 'Asia/Jakarta',
          });
          const labelKelas = u.kelas?.namaKelas ? `kelas ${u.kelas.namaKelas}` : 'semua kelas';
          const awalan = `Nilai ${u.nama} (${tgl}) ${labelKelas}:`;
          const rincian = [
            belum > 0 ? `${belum} belum diinput` : null,
            susulan > 0 ? `${susulan} menunggu susulan` : null,
          ]
            .filter(Boolean)
            .join(', ');
          const pesan = `${awalan} ${dinilai} dari ${total} santri sudah dinilai, ${rincian}.`;

          if (userId) {
            const sudahKirim = await this.prisma.notifikasi.count({
              where: {
                userId,
                jenis: JenisNotifikasi.NILAI,
                pesan: { startsWith: awalan },
                tanggal: { gte: mulai },
              },
            });
            if (sudahKirim > 0) continue;

            await this.notifikasi.kirimKeUstadz(
              u.tenantId,
              userId,
              JenisNotifikasi.NILAI,
              'pengingatNilai',
              pesan,
            );
          } else {
            // Tidak ada ustadz yang bisa dituju (mis. ujian semua kelas dibuat admin).
            // Tidak pernah tercapai di mode on-open karena sudah di-skip di atas.
            const sudahKirim = await this.prisma.notifikasi.count({
              where: {
                tenantId: u.tenantId,
                jenis: JenisNotifikasi.NILAI,
                pesan: { startsWith: awalan },
                tanggal: { gte: mulai },
              },
            });
            if (sudahKirim > 0) continue;

            await this.notifikasi.kirimKeAdminTenant(u.tenantId, JenisNotifikasi.NILAI, pesan);
          }
        } catch (e) {
          // Satu ujian bermasalah tidak boleh menghentikan ujian lainnya.
          this.logger.error(`Pengingat nilai ujian ${u.id} gagal: ${(e as Error).message}`);
        }
      }
    } catch (e) {
      this.logger.error(`Cron pengingat nilai ustadz gagal: ${(e as Error).message}`);
    }
  }

  /**
   * Cari akun penerima pengingat nilai.
   * 1) dibuatOleh = User.id berperan USTADZ di tenant itu
   * 2) dibuatOleh = Ustadz.id yang punya akun
   * 3) fallback: wali kelas (kalau ujian dibuat admin / tidak terisi)
   */
  private async cariPenerimaNilai(
    tenantId: string,
    dibuatOleh: string | null,
    waliKelasUserId: string | null,
  ): Promise<string | null> {
    if (dibuatOleh) {
      const user = await this.prisma.user.findFirst({
        where: { id: dibuatOleh, tenantId, role: Role.USTADZ },
        select: { id: true },
      });
      if (user) return user.id;

      const ustadz = await this.prisma.ustadz.findFirst({
        where: { id: dibuatOleh, tenantId },
        select: { userId: true },
      });
      if (ustadz?.userId) return ustadz.userId;
    }
    return waliKelasUserId;
  }
}