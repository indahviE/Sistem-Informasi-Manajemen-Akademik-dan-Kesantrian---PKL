import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
import { PrismaService } from '../prisma/prisma.service';
import { JenisNotifikasi, PeriodePaket, StatusInvoice, StatusSubscription, TenantStatus } from '@prisma/client';
import {
  AssignSubscriptionDto,
  CreateInvoiceDto,
  CreatePaketDto,
  UpdateInvoiceDto,
  UpdatePaketDto,
  UpdateSubscriptionDto,
} from './dto/billing.dto';
import { NotifikasiService } from '../notifikasi/notifikasi.service';

@Injectable()
export class BillingService {
  constructor(
    private prisma: PrismaService,
    private notifikasi: NotifikasiService,
  ) {}

  // ===== Paket (platform level) =====
  async findAllPaket() {
    return this.prisma.paket.findMany({ orderBy: { harga: 'asc' } });
  }

  async createPaket(dto: CreatePaketDto) {
    return this.prisma.paket.create({
      data: { nama: dto.nama, harga: dto.harga, limitSantri: dto.limitSantri, periode: dto.periode, fitur: dto.fitur },
    });
  }

  async updatePaket(id: string, dto: UpdatePaketDto) {
    const exist = await this.prisma.paket.findUnique({ where: { id } });
    if (!exist) throw new NotFoundException('Paket tidak ditemukan.');
    return this.prisma.paket.update({ where: { id }, data: dto });
  }

    async removePaket(id: string) {
    const exist = await this.prisma.paket.findUnique({ where: { id } });
    if (!exist) throw new NotFoundException('Paket tidak ditemukan.');

    const jumlahLangganan = await this.prisma.subscription.count({
      where: { paketId: id },
    });
    if (jumlahLangganan > 0) {
      throw new BadRequestException(
        `Paket ini masih terkait dengan ${jumlahLangganan} langganan dan tidak bisa dihapus. Nonaktifkan paket ini saja, atau hapus langganan terkait terlebih dahulu.`,
      );
    }

    return this.prisma.paket.delete({ where: { id } });
  }

  // ===== Subscription =====
  async findAllSubscription(isSuperAdmin: boolean, tenantId?: string) {
    return this.prisma.subscription.findMany({
      where: isSuperAdmin ? {} : { tenantId },
      orderBy: { tanggalMulai: 'desc' },
      include: { tenant: { select: { namaPondok: true, kodeTenant: true } }, paket: true },
    });
  }

  async assignSubscription(dto: AssignSubscriptionDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: dto.tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');

    // Tenant suspended / archived tidak boleh di-assign paket.
    // PENDING dan AKTIF diperbolehkan.
    if (
      tenant.status === TenantStatus.SUSPENDED ||
      tenant.status === TenantStatus.ARCHIVED
    ) {
      throw new BadRequestException(
        `Tenant berstatus ${tenant.status.toLowerCase()}. Aktifkan/pulihkan tenant terlebih dahulu sebelum assign paket.`,
      );
    }

    const paket = await this.prisma.paket.findUnique({ where: { id: dto.paketId } });
    if (!paket) throw new NotFoundException('Paket tidak ditemukan.');
    if (!paket.aktif) throw new BadRequestException('Paket sudah tidak aktif.');

    // Hitung tanggal akhir sesuai periode paket
    const tanggalAkhir = new Date();
    if (paket.periode === PeriodePaket.HARIAN) {
      tanggalAkhir.setDate(tanggalAkhir.getDate() + 1);
    } else if (paket.periode === PeriodePaket.BULANAN) {
      tanggalAkhir.setMonth(tanggalAkhir.getMonth() + 1);
    } else {
      tanggalAkhir.setFullYear(tanggalAkhir.getFullYear() + 1);
    }

    // Expire subscription lama + buat yang baru dalam satu transaksi
    const [, subscription] = await this.prisma.$transaction([
      this.prisma.subscription.updateMany({
        where: { tenantId: dto.tenantId, status: StatusSubscription.AKTIF },
        data: { status: StatusSubscription.EXPIRED },
      }),
      this.prisma.subscription.create({
        data: {
          tenantId: dto.tenantId,
          paketId: dto.paketId,
          tanggalAkhir,
        },
      }),
    ]);

    return subscription;
  }

  async updateSubscription(id: string, dto: UpdateSubscriptionDto) {
    const exist = await this.prisma.subscription.findUnique({ where: { id } });
    if (!exist) throw new NotFoundException('Subscription tidak ditemukan.');
    return this.prisma.subscription.update({ where: { id }, data: dto });
  }

  // ===== Invoice =====
  async findAllInvoice(isSuperAdmin: boolean, tenantId?: string) {
    return this.prisma.invoice.findMany({
      where: isSuperAdmin ? {} : { tenantId },
      orderBy: { createdAt: 'desc' },
      include: { tenant: { select: { namaPondok: true, kodeTenant: true } } },
    });
  }

  async createInvoice(dto: CreateInvoiceDto) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: dto.tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');

    const count = await this.prisma.invoice.count({ where: { tenantId: dto.tenantId } });
    const noInvoice = `INV-${tenant.kodeTenant.toUpperCase()}-${String(count + 1).padStart(4, '0')}`;

    return this.prisma.invoice.create({
      data: {
        tenantId: dto.tenantId,
        noInvoice,
        jumlah: dto.jumlah,
        metodeBayar: dto.metodeBayar,
        tanggalJatuhTempo: new Date(new Date().setDate(new Date().getDate() + 30)),
      },
    });
  }

  async updateInvoice(id: string, dto: UpdateInvoiceDto) {
    const exist = await this.prisma.invoice.findUnique({ where: { id } });
    if (!exist) throw new NotFoundException('Invoice tidak ditemukan.');

    const data: any = {};
    if (dto.status) data.status = dto.status;
    if (dto.status === StatusInvoice.LUNAS) data.tanggalBayar = new Date();
    if (dto.metodeBayar) data.metodeBayar = dto.metodeBayar;

    return this.prisma.invoice.update({ where: { id }, data });
  }

  // ===========================================================================
  // Cron: cek tagihan jatuh tempo — jalan tiap hari jam 07:00
  // ===========================================================================
  @Cron(CronExpression.EVERY_DAY_AT_7AM)
  async cekTagihanJatuhTempo(): Promise<void> {
    const sekarang = new Date();

    const overdue = await this.prisma.invoice.findMany({
      where: {
        status: { not: StatusInvoice.LUNAS },
        tanggalJatuhTempo: { lt: sekarang },
      },
      include: { tenant: { select: { namaPondok: true, kodeTenant: true } } },
    });

    if (overdue.length === 0) return;

    const awalHariIni = new Date(sekarang);
    awalHariIni.setHours(0, 0, 0, 0);

    const sudahAdaHariIni = await this.prisma.notifikasi.findFirst({
      where: {
        jenis: JenisNotifikasi.TAGIHAN,
        tenantId: null,
        tanggal: { gte: awalHariIni },
      },
    });
    if (sudahAdaHariIni) return;

    const totalTertunggak = overdue.reduce((sum, inv) => sum + Number(inv.jumlah), 0);
    const daftarTenant = overdue.map((inv) => inv.tenant.namaPondok).slice(0, 3).join(', ');
    const sisa = overdue.length > 3 ? ` +${overdue.length - 3} lainnya` : '';

    await this.notifikasi.kirimKeSuperAdmin(
      JenisNotifikasi.TAGIHAN,
      `${overdue.length} tagihan menunggak (${daftarTenant}${sisa}). Total tertunggak Rp ${totalTertunggak.toLocaleString('id-ID')}.`,
    );
  }
}
