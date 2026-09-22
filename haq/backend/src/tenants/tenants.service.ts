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
import { AuditKategori, AuditTingkat, JenisNotifikasi } from '@prisma/client';
import { AuditService } from '../audit/audit.service';
import { NotifikasiService } from '../notifikasi/notifikasi.service';
import { RequestUser } from '../common/decorators/current-user.decorator';

const STATUS_LABEL: Record<string, string> = {
  PENDING: 'Pending',
  AKTIF: 'Aktif',
  SUSPENDED: 'Suspended',
};

@Injectable()
export class TenantsService {
  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
    private notifikasi: NotifikasiService,
  ) {}

  async signup(dto: SignupTenantDto, ip?: string) {
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

    const result = await this.prisma.$transaction(async (tx) => {
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

    await this.audit.log({
      action: 'TENANT_SIGNUP',
      entity: 'tenants',
      entityId: result.id,
      tenantId: result.id,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.INFO,
      judul: 'Pendaftaran Pondok Baru',
      deskripsi: `Pondok "${result.namaPondok}" (\`${result.kodeTenant}\`) mendaftar via self-service dan menunggu validasi Super Admin.`,
      meta: 'Menunggu Persetujuan',
      userNama: dto.adminNama,
      userRole: 'ADMIN',
      ip,
    });

    await this.notifikasi.kirimKeSuperAdmin(
      JenisNotifikasi.TENANT_BARU,
      `Tenant baru "${result.namaPondok}" (${result.kodeTenant}) mendaftar dan menunggu persetujuan.`,
    );

    return result;
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

  async approve(tenantId: string, actor?: RequestUser, ip?: string) {
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

    await this.audit.log({
      action: 'TENANT_APPROVE',
      entity: 'tenants',
      entityId: tenantId,
      tenantId,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.INFO,
      judul: 'Pondok Disetujui & Diaktivasi',
      deskripsi: `Status beralih dari ${STATUS_LABEL[tenant.status] ?? tenant.status} ke Aktif. Kode tenant \`${tenant.kodeTenant}\` kini dapat dipakai untuk login.`,
      meta: 'Tenant Aktif',
      userId: actor?.userId,
      userRole: actor?.role ? String(actor.role) : null,
      ip,
    });

    return { message: 'Tenant berhasil diaktifkan.', id: tenantId };
  }

  async suspend(tenantId: string, actor?: RequestUser, ip?: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { status: TenantStatus.SUSPENDED },
    });
    // Di aplikasi, tombol "Tolak" pendaftaran juga memanggil endpoint ini.
    const ditolak = tenant.status === TenantStatus.PENDING;
    await this.audit.log({
      action: ditolak ? 'TENANT_REJECT' : 'TENANT_SUSPEND',
      entity: 'tenants',
      entityId: tenantId,
      tenantId,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.WARNING,
      judul: ditolak ? 'Pendaftaran Pondok Ditolak' : 'Tenant Di-suspend',
      deskripsi: `Status beralih dari ${STATUS_LABEL[tenant.status] ?? tenant.status} ke Suspended. Pengguna pondok tidak dapat login.`,
      meta: 'Akses Login Ditutup',
      userId: actor?.userId,
      userRole: actor?.role ? String(actor.role) : null,
      ip,
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