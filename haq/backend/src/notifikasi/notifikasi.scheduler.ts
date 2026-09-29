import { Injectable, Logger } from '@nestjs/common';
import { Cron } from '@nestjs/schedule';
import { JenisNotifikasi, SantriStatus, TenantStatus } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { NotifikasiService } from './notifikasi.service';

@Injectable()
export class NotifikasiScheduler {
  private readonly logger = new Logger(NotifikasiScheduler.name);

  constructor(
    private prisma: PrismaService,
    private notifikasi: NotifikasiService,
  ) {}

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
}