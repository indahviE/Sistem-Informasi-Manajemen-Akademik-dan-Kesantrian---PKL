import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { Role, TenantStatus } from '@prisma/client';
import { SignupTenantDto, UpdateBrandingDto } from './dto/tenant.dto';

@Injectable()
export class TenantsService {
  constructor(private prisma: PrismaService) {}

  async signup(dto: SignupTenantDto) {
    const existing = await this.prisma.tenant.findUnique({
      where: { kodeTenant: dto.kodeTenant },
    });
    if (existing) {
      throw new ConflictException('Kode tenant sudah dipakai. Pilih kode lain.');
    }

    const emailExists = await this.prisma.user.findFirst({
      where: { email: dto.adminEmail },
    });
    if (emailExists) {
      throw new ConflictException('Email admin sudah terdaftar di platform ini.');
    }

    const passwordHash = await bcrypt.hash(dto.adminPassword, 10);

    return this.prisma.$transaction(async (tx) => {
      const tenant = await tx.tenant.create({
        data: {
          kodeTenant: dto.kodeTenant,
          namaPondok: dto.namaPondok,
          logoUrl: dto.logoUrl,
          status: TenantStatus.PENDING,
        },
      });

      const admin = await tx.user.create({
        data: {
          tenantId: tenant.id,
          nama: dto.adminNama,
          email: dto.adminEmail,
          passwordHash,
          role: Role.ADMIN,
        },
      });

      await tx.tenant.update({
        where: { id: tenant.id },
        data: { adminAwalId: admin.id },
      });

      await tx.tahunAjaran.create({
        data: { tenantId: tenant.id, nama: '2026/2027', aktif: true },
      });

      return {
        id: tenant.id,
        namaPondok: tenant.namaPondok,
        kodeTenant: tenant.kodeTenant,
        status: tenant.status,
        message:
          'Pendaftaran berhasil. Menunggu persetujuan Super Admin sebelum bisa digunakan.',
      };
    });
  }

  async findAll(status?: TenantStatus) {
    const tenants = await this.prisma.tenant.findMany({
      where: status ? { status } : {},
      orderBy: { tanggalDaftar: 'desc' },
      include: {
        _count: { select: { users: true, santris: true, kelas: true } },
      },
    });
    return tenants.map((t) => ({
      ...t,
      jumlahUser: t._count.users,
      jumlahSantri: t._count.santris,
      jumlahKelas: t._count.kelas,
    }));
  }

  async approve(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { status: TenantStatus.AKTIF },
    });

    await this.prisma.notifikasi.create({
      data: {
        tenantId,
        jenis: 'SISTEM',
        pesan: `Pondok "${tenant.namaPondok}" telah diaktifkan. Admin dapat login dan mulai setup data.`,
      },
    });

    return { message: 'Tenant berhasil diaktifkan.', id: tenantId };
  }

  async suspend(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { status: TenantStatus.SUSPENDED },
    });
    return { message: 'Tenant di-suspend.' };
  }

  async getByTenantId(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      include: {
        _count: { select: { users: true, santris: true, kelas: true, ustadzs: true } },
      },
    });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');
    return tenant;
  }

  async getBranding(kodeTenant: string) {
    if (!kodeTenant) throw new BadRequestException('Parameter kodeTenant wajib diisi.');
    const tenant = await this.prisma.tenant.findUnique({
      where: { kodeTenant },
      select: {
        kodeTenant: true,
        namaPondok: true,
        logoUrl: true,
        warnaTema: true,
        status: true,
      },
    });
    if (!tenant) throw new NotFoundException('Pondok dengan kode tersebut tidak ditemukan.');
    return tenant;
  }

  async getMyBranding(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      select: {
        id: true,
        kodeTenant: true,
        namaPondok: true,
        logoUrl: true,
        warnaTema: true,
        status: true,
        tanggalDaftar: true,
      },
    });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');
    return tenant;
  }

  async updateBranding(tenantId: string, dto: UpdateBrandingDto) {
    return this.prisma.tenant.update({
      where: { id: tenantId },
      data: dto,
      select: {
        id: true,
        namaPondok: true,
        logoUrl: true,
        warnaTema: true,
      },
    });
  }
}
