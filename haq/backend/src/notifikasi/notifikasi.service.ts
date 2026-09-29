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

  async myNotifikasis(userId: string, tenantId: string | undefined) {
    return this.prisma.notifikasi.findMany({
      where: this.scope(userId, tenantId),
      orderBy: { tanggal: 'desc' },
      take: 100,
    });
  }

  async unreadCount(userId: string, tenantId: string | undefined) {
    return this.prisma.notifikasi.count({
      where: { ...this.scope(userId, tenantId), statusBaca: false },
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

  /**
   * TODO (penting): sambungkan ke tempat toggle admin disimpan, yaitu data
   * yang dibaca GET /pengaturan/admin. Sementara ini memakai nilai default
   * yang sama dengan di Flutter, jadi toggle BELUM berpengaruh.
   */
  private async adminMenerima(adminId: string, key: AdminNotifKey): Promise<boolean> {
    return ADMIN_NOTIF_DEFAULT[key];
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