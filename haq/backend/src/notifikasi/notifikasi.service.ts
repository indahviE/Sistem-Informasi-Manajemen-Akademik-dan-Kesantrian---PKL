import { Injectable, Logger } from '@nestjs/common';
import { JenisNotifikasi, Prisma, Role, UserStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

type AdminNotifKey =
  | 'perizinanBaru'
  | 'pelanggaranBaru'
  | 'waliBelumAktivasi'
  | 'eskalasiDarurat'
  | 'rekapAbsensiShalat';

const ADMIN_NOTIF_DEFAULT: Record<AdminNotifKey, boolean> = {
  perizinanBaru: true,
  pelanggaranBaru: true,
  waliBelumAktivasi: true,
  eskalasiDarurat: true,
  rekapAbsensiShalat: false,
};

type WaliNotifKey =
  | 'perizinanAnak'
  | 'pelanggaranAnak'
  | 'kesehatanAnak'
  | 'nilaiRapor'
  | 'absensiAnak';

const WALI_NOTIF_DEFAULT: Record<WaliNotifKey, boolean> = {
  perizinanAnak: true,
  pelanggaranAnak: true,
  kesehatanAnak: true,
  nilaiRapor: true,
  absensiAnak: true,
};

// DARURAT sengaja tidak ada di sini: selalu tampil untuk wali.
const WALI_NOTIF_JENIS: Record<WaliNotifKey, JenisNotifikasi[]> = {
  perizinanAnak: [JenisNotifikasi.PERIZINAN],
  pelanggaranAnak: [JenisNotifikasi.PELANGGARAN],
  kesehatanAnak: [JenisNotifikasi.KESEHATAN],
  nilaiRapor: [JenisNotifikasi.NILAI],
  absensiAnak: [JenisNotifikasi.ABSENSI],
};

type UstadzNotifKey =
  | 'pengingatAbsensi'
  | 'pengingatNilai'
  | 'jadwalMengajar'
  | 'pengumumanPondok';

const USTADZ_NOTIF_DEFAULT: Record<UstadzNotifKey, boolean> = {
  pengingatAbsensi: true,
  pengingatNilai: true,
  jadwalMengajar: true,
  pengumumanPondok: true,
};

@Injectable()
export class NotifikasiService {
  private readonly logger = new Logger(NotifikasiService.name);

  constructor(private prisma: PrismaService) {}

  /**
   * Notifikasi yang boleh dilihat user:
   * - user tenant (Wali, Musyrif, Admin, dst): miliknya sendiri + siaran
   *   (userId null) di tenant-nya saja
   * - Super Admin (tanpa tenant): hanya yang ditujukan ke akunnya
   */
  private scope(userId: string, tenantId: string | undefined): Prisma.NotifikasiWhereInput {
    return tenantId
      ? { tenantId, OR: [{ userId }, { userId: null }] }
      : { userId };
  }

  /** Jenis yang dimatikan user wali di Pengaturan. Role lain: kosong. */
  private async jenisDimatikan(userId: string): Promise<JenisNotifikasi[]> {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: { role: true, notifSetting: true },
    });
    if (!user || user.role !== Role.WALI_SANTRI) return [];

    const off: JenisNotifikasi[] = [];
    for (const key of Object.keys(WALI_NOTIF_JENIS) as WaliNotifKey[]) {
      const aktif = user.notifSetting ? user.notifSetting[key] : WALI_NOTIF_DEFAULT[key];
      if (!aktif) off.push(...WALI_NOTIF_JENIS[key]);
    }
    return off;
  }

  private async scopeTampil(
    userId: string,
    tenantId: string | undefined,
  ): Promise<Prisma.NotifikasiWhereInput> {
    const base = this.scope(userId, tenantId);
    const off = await this.jenisDimatikan(userId);
    return off.length ? { AND: [base, { jenis: { notIn: off } }] } : base;
  }

  async myNotifikasis(userId: string, tenantId: string | undefined) {
    return this.prisma.notifikasi.findMany({
      where: await this.scopeTampil(userId, tenantId),
      orderBy: { tanggal: 'desc' },
      take: 100,
    });
  }

  async unreadCount(userId: string, tenantId: string | undefined) {
    return this.prisma.notifikasi.count({
      where: { AND: [await this.scopeTampil(userId, tenantId), { statusBaca: false }] },
    });
  }

  async markRead(userId: string, tenantId: string | undefined, id: string) {
    return this.prisma.notifikasi.updateMany({
      where: { id, ...this.scope(userId, tenantId) },
      data: { statusBaca: true },
    });
  }

  async markAllRead(userId: string, tenantId: string | undefined) {
    return this.prisma.notifikasi.updateMany({
      where: { ...this.scope(userId, tenantId), statusBaca: false },
      data: { statusBaca: true },
    });
  }

  // -------------------------------------------------------------------------
  // Pengiriman notifikasi ke Super Admin (platform, tanpa tenant)
  // -------------------------------------------------------------------------

  /**
   * Kirim ke semua Super Admin aktif, satu baris per akun (tenantId kosong,
   * sesuai scope() di atas). Menghormati toggle di PlatformSetting lewat
   * diizinkan(). Tidak pernah melempar error.
   */
  async kirimKeSuperAdmin(jenis: JenisNotifikasi, pesan: string): Promise<void> {
    try {
      if (!(await this.diizinkan(jenis))) return;

      const superAdmins = await this.prisma.user.findMany({
        where: { role: Role.SUPER_ADMIN, status: UserStatus.AKTIF },
        select: { id: true },
      });
      if (superAdmins.length === 0) return;

      await this.prisma.notifikasi.createMany({
        data: superAdmins.map((u) => ({ userId: u.id, jenis, pesan })),
      });
    } catch (e) {
      this.logger.error(`Gagal kirim notifikasi super admin ${jenis}: ${(e as Error).message}`);
    }
  }

  // -------------------------------------------------------------------------
  // Pengiriman notifikasi ke Admin Lembaga (per tenant)
  // -------------------------------------------------------------------------

  /**
   * Kirim ke semua Admin aktif di satu tenant, satu baris per admin, dan
   * hormati toggle masing-masing (UserNotifSetting). Admin yang belum pernah
   * membuka Pengaturan (belum ada baris setting) memakai nilai default.
   * Tidak pernah melempar error.
   */
  async kirimKeAdminTenant(
    tenantId: string,
    jenis: JenisNotifikasi,
    pesan: string,
  ): Promise<void> {
    try {
      const key = this.kunciToggleAdmin(jenis);

      const admins = await this.prisma.user.findMany({
        where: { tenantId, role: Role.ADMIN, status: UserStatus.AKTIF },
        select: { id: true, notifSetting: true },
      });

      const penerima = admins.filter((a) => {
        if (!key) return true;
        return a.notifSetting ? a.notifSetting[key] : ADMIN_NOTIF_DEFAULT[key];
      });
      if (penerima.length === 0) return;

      await this.prisma.notifikasi.createMany({
        data: penerima.map((a) => ({ tenantId, userId: a.id, jenis, pesan })),
      });
    } catch (e) {
      this.logger.error(`Gagal kirim notifikasi admin ${jenis}: ${(e as Error).message}`);
    }
  }

  // -------------------------------------------------------------------------
  // Pengiriman notifikasi ke Ustadz (per akun)
  // -------------------------------------------------------------------------

  /**
   * Kirim satu notifikasi ke satu ustadz, hanya kalau toggle-nya menyala di
   * Pengaturan Ustadz. Ustadz yang belum pernah membuka Pengaturan (belum ada
   * baris setting) memakai nilai default. Mengembalikan true kalau terkirim.
   * Tidak pernah melempar error.
   */
  async kirimKeUstadz(
    tenantId: string,
    userId: string,
    jenis: JenisNotifikasi,
    kunci: UstadzNotifKey,
    pesan: string,
  ): Promise<boolean> {
    try {
      const setting = await this.prisma.userNotifSetting.findUnique({ where: { userId } });
      const aktif = setting ? setting[kunci] : USTADZ_NOTIF_DEFAULT[kunci];
      if (!aktif) return false;

      await this.prisma.notifikasi.create({ data: { tenantId, userId, jenis, pesan } });
      return true;
    } catch (e) {
      this.logger.error(`Gagal kirim notifikasi ustadz ${jenis}: ${(e as Error).message}`);
      return false;
    }
  }

  /** Jenis notifikasi -> nama toggle di Pengaturan Admin. */
  private kunciToggleAdmin(jenis: JenisNotifikasi): AdminNotifKey | null {
    switch (jenis) {
      case JenisNotifikasi.PERIZINAN:
        return 'perizinanBaru';
      case JenisNotifikasi.PELANGGARAN:
        return 'pelanggaranBaru';
      case JenisNotifikasi.WALI_BELUM_AKTIVASI:
        return 'waliBelumAktivasi';
      case JenisNotifikasi.DARURAT:
      case JenisNotifikasi.KESEHATAN:
        return 'eskalasiDarurat';
      case JenisNotifikasi.ABSENSI:
        return 'rekapAbsensiShalat';
      default:
        return null; // jenis lain: selalu dikirim
    }
  }

  /** Cek toggle di Pengaturan (PlatformSetting). Tanpa data = pakai nilai default. */
  private async diizinkan(jenis: JenisNotifikasi): Promise<boolean> {
    const s = await this.prisma.platformSetting.findFirst();
    switch (jenis) {
      case JenisNotifikasi.TENANT_BARU:
        return s?.notifTenantBaru ?? true;
      case JenisNotifikasi.TAGIHAN:
        return s?.notifTagihan ?? true;
      case JenisNotifikasi.KEAMANAN:
        return s?.notifKeamanan ?? true;
      case JenisNotifikasi.LAPORAN:
        return s?.notifLaporanMingguan ?? false;
      default:
        return true;
    }
  }
}