import { Injectable, Logger } from '@nestjs/common';
import { JenisNotifikasi, Prisma, Role, UserStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';

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
  // Pengiriman notifikasi platform ke Super Admin
  // -------------------------------------------------------------------------

  /**
   * Kirim notifikasi platform ke semua akun Super Admin (ROOT + sub-admin).
   * Menghormati toggle di halaman Pengaturan. Tidak pernah melempar error:
   * gagal kirim notifikasi tidak boleh menggagalkan proses utama
   * (login, pendaftaran tenant, dst).
   */
  async kirimKeSuperAdmin(jenis: JenisNotifikasi, pesan: string): Promise<void> {
    try {
      if (!(await this.diizinkan(jenis))) return;

      const admins = await this.prisma.user.findMany({
        where: { role: Role.SUPER_ADMIN, tenantId: null, status: UserStatus.AKTIF },
        select: { id: true },
      });
      if (admins.length === 0) return;

      await this.prisma.notifikasi.createMany({
        data: admins.map((a) => ({ tenantId: null, userId: a.id, jenis, pesan })),
      });
    } catch (e) {
      this.logger.error(`Gagal mengirim notifikasi ${jenis}: ${(e as Error).message}`);
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