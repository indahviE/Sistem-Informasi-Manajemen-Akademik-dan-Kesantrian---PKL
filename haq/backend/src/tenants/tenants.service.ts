import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Cron, CronExpression } from '@nestjs/schedule';
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
  ARCHIVED: 'Diarsipkan',
};

@Injectable()
export class TenantsService {
  /** Lama tenant boleh nongkrong di sampah sebelum dihapus permanen otomatis. */
  private readonly RETENSI_SAMPAH_HARI = 30; // ganti ke 40 kalau mau lebih lama

  constructor(
    private prisma: PrismaService,
    private audit: AuditService,
    private notifikasi: NotifikasiService,
  ) {}

  async isSlugAvailable(kodeTenant: string): Promise<boolean> {
    if (!kodeTenant?.trim()) return false;
    const existing = await this.prisma.tenant.findUnique({
      where: { kodeTenant: kodeTenant.trim() },
    });
    return !existing;
  }

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

    // Baca kebijakan onboarding platform (tabel singleton PlatformSetting)
    const platformSetting = await this.prisma.platformSetting.findFirst();
    const autoApprove = platformSetting?.autoApproveTenant ?? false;
    const initialStatus = autoApprove ? TenantStatus.AKTIF : TenantStatus.PENDING;

    const passwordHash = await bcrypt.hash(dto.adminPassword, 10);

    const result = await this.prisma.$transaction(async (tx) => {
      const tenant = await tx.tenant.create({
        data: {
          kodeTenant: dto.kodeTenant,
          namaPondok: dto.namaPondok,
          logoUrl: dto.logoUrl,
          alamat: dto.alamat,
          karakteristik: dto.karakteristik,
          status: initialStatus,
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
        message: autoApprove
          ? 'Pendaftaran berhasil. Tenant langsung diaktifkan sesuai kebijakan platform.'
          : 'Pendaftaran berhasil. Menunggu persetujuan Super Admin sebelum bisa digunakan.',
      };
    });

    await this.audit.log({
      action: autoApprove ? 'TENANT_SIGNUP_AUTO_APPROVED' : 'TENANT_SIGNUP',
      entity: 'tenants',
      entityId: result.id,
      tenantId: result.id,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.INFO,
      judul: autoApprove ? 'Pondok Baru Terdaftar & Otomatis Aktif' : 'Pendaftaran Pondok Baru',
      deskripsi: autoApprove
        ? `Pondok "${result.namaPondok}" (\`${result.kodeTenant}\`) mendaftar via self-service dan langsung diaktifkan sesuai kebijakan Auto-Approve platform.`
        : `Pondok "${result.namaPondok}" (\`${result.kodeTenant}\`) mendaftar via self-service dan menunggu validasi Super Admin.`,
      meta: autoApprove ? 'Tenant Aktif' : 'Menunggu Persetujuan',
      userNama: dto.adminNama,
      userRole: 'ADMIN',
      ip,
    });

    await this.notifikasi.kirimKeSuperAdmin(
      JenisNotifikasi.TENANT_BARU,
      autoApprove
        ? `Tenant baru "${result.namaPondok}" (${result.kodeTenant}) mendaftar dan langsung diaktifkan otomatis.`
        : `Tenant baru "${result.namaPondok}" (${result.kodeTenant}) mendaftar dan menunggu persetujuan.`,
    );

    return result;
  }

  async findAll(status?: TenantStatus) {
    const tenants = await this.prisma.tenant.findMany({
      where: { deletedAt: null, ...(status ? { status } : {}) },
      orderBy: { tanggalDaftar: 'desc' },
      include: {
        _count: { select: { users: true, santris: true, kelas: true } },
        adminAwal: { select: { nama: true, email: true } },
      },
    });
    return tenants.map((t) => ({
      ...t,
      jumlahUser: t._count.users,
      jumlahSantri: t._count.santris,
      jumlahKelas: t._count.kelas,
      adminNama: t.adminAwal?.nama,
      adminEmail: t.adminAwal?.email,
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

  async archive(tenantId: string, actor?: RequestUser, ip?: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');

    if (tenant.status === TenantStatus.PENDING) {
      throw new BadRequestException(
        'Tenant yang masih pending belum punya data aktif. Gunakan Hapus, bukan Arsipkan.',
      );
    }
    if (tenant.status === TenantStatus.ARCHIVED) {
      throw new ConflictException('Tenant ini sudah diarsipkan.');
    }

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { status: TenantStatus.ARCHIVED },
    });

    await this.audit.log({
      action: 'TENANT_ARCHIVE',
      entity: 'tenants',
      entityId: tenantId,
      tenantId,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.WARNING,
      judul: 'Tenant Diarsipkan',
      deskripsi: `Status beralih dari ${STATUS_LABEL[tenant.status] ?? tenant.status} ke Diarsipkan. Seluruh akses login untuk tenant \`${tenant.kodeTenant}\` ditutup.`,
      meta: 'Tenant Diarsipkan',
      userId: actor?.userId,
      userRole: actor?.role ? String(actor.role) : null,
      ip,
    });

    return { message: 'Tenant berhasil diarsipkan.', id: tenantId };
  }

  async unarchive(tenantId: string, actor?: RequestUser, ip?: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');

    if (tenant.status !== TenantStatus.ARCHIVED) {
      throw new BadRequestException('Tenant ini tidak sedang diarsipkan.');
    }

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { status: TenantStatus.AKTIF },
    });

    await this.audit.log({
      action: 'TENANT_UNARCHIVE',
      entity: 'tenants',
      entityId: tenantId,
      tenantId,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.INFO,
      judul: 'Tenant Dipulihkan dari Arsip',
      deskripsi: `Status beralih dari Diarsipkan ke Aktif. Kode tenant \`${tenant.kodeTenant}\` kini dapat dipakai untuk login kembali.`,
      meta: 'Tenant Aktif',
      userId: actor?.userId,
      userRole: actor?.role ? String(actor.role) : null,
      ip,
    });

    return { message: 'Tenant berhasil dipulihkan dari arsip.', id: tenantId };
  }

  async deletePending(tenantId: string, actor?: RequestUser, ip?: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');

    if (tenant.status !== TenantStatus.PENDING) {
      throw new BadRequestException(
        'Hanya tenant dengan status pending yang bisa dihapus permanen. Gunakan Arsipkan untuk tenant yang sudah aktif.',
      );
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.tahunAjaran.deleteMany({ where: { tenantId } });
      await tx.user.deleteMany({ where: { tenantId } });
      await tx.tenant.delete({ where: { id: tenantId } });
    });

    await this.audit.log({
      action: 'TENANT_DELETE_PENDING',
      entity: 'tenants',
      entityId: tenantId,
      tenantId,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.WARNING,
      judul: 'Pendaftaran Tenant Dihapus',
      deskripsi: `Pendaftaran pondok "${tenant.namaPondok}" (\`${tenant.kodeTenant}\`) dihapus permanen sebelum sempat diaktifkan.`,
      meta: 'Dihapus Permanen',
      userId: actor?.userId,
      userRole: actor?.role ? String(actor.role) : null,
      ip,
    });

    return { message: 'Pendaftaran tenant berhasil dihapus.' };
  }

  async getByTenantId(tenantId: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { id: tenantId },
      include: {
        _count: { select: { users: true, santris: true, kelas: true, ustadzs: true } },
        adminAwal: { select: { nama: true, email: true } },
      },
    });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');
    return {
      ...tenant,
      adminNama: tenant.adminAwal?.nama,
      adminEmail: tenant.adminAwal?.email,
    };
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

  // ===========================================================================
  // Sampah (Trash) — soft-delete ala galeri. Tenant yang dipindah ke sampah
  // hilang dari listing biasa (findAll sudah filter deletedAt: null), tapi
  // masih bisa dipulihkan sampai RETENSI_SAMPAH_HARI hari, setelah itu
  // dihapus permanen otomatis oleh cron di bawah.
  // ===========================================================================

  async pindahKeSampah(tenantId: string, actor?: RequestUser, ip?: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');
    if (tenant.deletedAt) throw new ConflictException('Tenant ini sudah ada di sampah.');

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { deletedAt: new Date() },
    });

    await this.audit.log({
      action: 'TENANT_TRASH',
      entity: 'tenants',
      entityId: tenantId,
      tenantId,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.WARNING,
      judul: 'Tenant Dipindahkan ke Sampah',
      deskripsi: `Pondok "${tenant.namaPondok}" (\`${tenant.kodeTenant}\`) dipindahkan ke sampah. Akan dihapus permanen otomatis dalam ${this.RETENSI_SAMPAH_HARI} hari jika tidak dipulihkan.`,
      meta: 'Masuk Sampah',
      userId: actor?.userId,
      userRole: actor?.role ? String(actor.role) : null,
      ip,
    });

    return { message: 'Tenant dipindahkan ke sampah.', id: tenantId };
  }

  async pulihkanDariSampah(tenantId: string, actor?: RequestUser, ip?: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');
    if (!tenant.deletedAt) throw new BadRequestException('Tenant ini tidak ada di sampah.');

    await this.prisma.tenant.update({
      where: { id: tenantId },
      data: { deletedAt: null },
    });

    await this.audit.log({
      action: 'TENANT_RESTORE_FROM_TRASH',
      entity: 'tenants',
      entityId: tenantId,
      tenantId,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.INFO,
      judul: 'Tenant Dipulihkan dari Sampah',
      deskripsi: `Pondok "${tenant.namaPondok}" (\`${tenant.kodeTenant}\`) dipulihkan dari sampah.`,
      meta: 'Dipulihkan',
      userId: actor?.userId,
      userRole: actor?.role ? String(actor.role) : null,
      ip,
    });

    return { message: 'Tenant berhasil dipulihkan.', id: tenantId };
  }

  async findTrashed() {
    const tenants = await this.prisma.tenant.findMany({
      where: { deletedAt: { not: null } },
      orderBy: { deletedAt: 'desc' },
      include: {
        _count: { select: { users: true, santris: true, kelas: true } },
        adminAwal: { select: { nama: true, email: true } },
      },
    });
    return tenants.map((t) => ({
      ...t,
      jumlahUser: t._count.users,
      jumlahSantri: t._count.santris,
      jumlahKelas: t._count.kelas,
      adminNama: t.adminAwal?.nama,
      adminEmail: t.adminAwal?.email,
      hapusPermanenPada: new Date(
        t.deletedAt!.getTime() + this.RETENSI_SAMPAH_HARI * 24 * 60 * 60 * 1000,
      ),
    }));
  }

  async hapusPermanen(tenantId: string, actor?: RequestUser, ip?: string) {
    const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
    if (!tenant) throw new NotFoundException('Tenant tidak ditemukan.');
    if (!tenant.deletedAt) {
      throw new BadRequestException('Pindahkan tenant ke sampah terlebih dahulu sebelum menghapus permanen.');
    }

    await this.prisma.$transaction(async (tx) => {
      await tx.tahunAjaran.deleteMany({ where: { tenantId } });
      await tx.user.deleteMany({ where: { tenantId } });
      await tx.tenant.delete({ where: { id: tenantId } });
    });

    await this.audit.log({
      action: 'TENANT_DELETE_PERMANENT',
      entity: 'tenants',
      entityId: tenantId,
      kategori: AuditKategori.SISTEM,
      tingkat: AuditTingkat.WARNING,
      judul: 'Tenant Dihapus Permanen',
      deskripsi: `Pondok "${tenant.namaPondok}" (\`${tenant.kodeTenant}\`) dihapus permanen dari sampah oleh Super Admin.`,
      meta: 'Dihapus Permanen',
      userId: actor?.userId,
      userRole: actor?.role ? String(actor.role) : null,
      ip,
    });

    return { message: 'Tenant berhasil dihapus permanen.' };
  }

  /** Cron: beres-beres sampah tiap hari jam 09:00 — hapus permanen yang udah kelewat retensi. */
  @Cron(CronExpression.EVERY_DAY_AT_9AM)
  async purgeSampahKedaluwarsa(): Promise<void> {
    const batasWaktu = new Date();
    batasWaktu.setDate(batasWaktu.getDate() - this.RETENSI_SAMPAH_HARI);

    const expired = await this.prisma.tenant.findMany({
      where: { deletedAt: { not: null, lt: batasWaktu } },
    });
    if (expired.length === 0) return;

    for (const tenant of expired) {
      await this.prisma.$transaction(async (tx) => {
        await tx.tahunAjaran.deleteMany({ where: { tenantId: tenant.id } });
        await tx.user.deleteMany({ where: { tenantId: tenant.id } });
        await tx.tenant.delete({ where: { id: tenant.id } });
      });

      await this.audit.log({
        action: 'TENANT_AUTO_PURGE',
        entity: 'tenants',
        kategori: AuditKategori.SISTEM,
        tingkat: AuditTingkat.WARNING,
        judul: 'Tenant Dihapus Permanen Otomatis',
        deskripsi: `Pondok "${tenant.namaPondok}" (\`${tenant.kodeTenant}\`) sudah di sampah lebih dari ${this.RETENSI_SAMPAH_HARI} hari, dihapus permanen otomatis oleh sistem.`,
        meta: 'Auto-Purge',
      });
    }
  }

  // ===========================================================================
  // Cron: auto-tolak pendaftaran PENDING yang melewati masa tenggang —
  // jalan tiap hari jam 08:00. Grace period diambil dari
  // PlatformSetting.graceDaysPending (diatur di halaman Pengaturan).
  // ===========================================================================
  @Cron(CronExpression.EVERY_DAY_AT_8AM)
  async autoTolakPendingKedaluwarsa(): Promise<void> {
    const setting = await this.prisma.platformSetting.findFirst();
    const graceDays = setting?.graceDaysPending ?? 14;

    const batasWaktu = new Date();
    batasWaktu.setDate(batasWaktu.getDate() - graceDays);

    const expired = await this.prisma.tenant.findMany({
      where: {
        status: TenantStatus.PENDING,
        tanggalDaftar: { lt: batasWaktu },
      },
    });

    if (expired.length === 0) return;

    for (const tenant of expired) {
      await this.prisma.tenant.update({
        where: { id: tenant.id },
        data: { deletedAt: new Date() },
      });

      await this.audit.log({
        action: 'TENANT_AUTO_REJECT_GRACE_EXPIRED',
        entity: 'tenants',
        entityId: tenant.id,
        tenantId: tenant.id,
        kategori: AuditKategori.SISTEM,
        tingkat: AuditTingkat.WARNING,
        judul: 'Pendaftaran Otomatis Dipindahkan ke Sampah',
        deskripsi: `Pondok "${tenant.namaPondok}" (\`${tenant.kodeTenant}\`) tidak diverifikasi dalam ${graceDays} hari sejak mendaftar (${tenant.tanggalDaftar.toISOString().split('T')[0]}), sehingga dipindahkan ke sampah oleh sistem. Akan dihapus permanen dalam ${this.RETENSI_SAMPAH_HARI} hari jika tidak dipulihkan.`,
        meta: 'Masuk Sampah',
      });
    }

    await this.notifikasi.kirimKeSuperAdmin(
      JenisNotifikasi.TENANT_BARU,
      `${expired.length} pendaftaran tenant otomatis dibatalkan karena melewati masa tenggang ${graceDays} hari: ${expired.map((t) => t.namaPondok).join(', ')}.`,
    );
  }
}