import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StatusInvoice, StatusSubscription } from '@prisma/client';
import {
  AssignSubscriptionDto,
  CreateInvoiceDto,
  CreatePaketDto,
  UpdateInvoiceDto,
  UpdatePaketDto,
  UpdateSubscriptionDto,
} from './dto/billing.dto';

@Injectable()
export class BillingService {
  constructor(private prisma: PrismaService) {}

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
    const paket = await this.prisma.paket.findUnique({ where: { id: dto.paketId } });
    if (!paket) throw new NotFoundException('Paket tidak ditemukan.');

    await this.prisma.subscription.updateMany({
      where: { tenantId: dto.tenantId, status: StatusSubscription.AKTIF },
      data: { status: StatusSubscription.EXPIRED },
    });

    return this.prisma.subscription.create({
      data: {
        tenantId: dto.tenantId,
        paketId: dto.paketId,
        tanggalAkhir: new Date(new Date().setFullYear(new Date().getFullYear() + 1)),
      },
    });
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
}