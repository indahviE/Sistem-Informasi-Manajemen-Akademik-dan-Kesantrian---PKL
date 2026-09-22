import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { Role } from '@prisma/client';
import {
  CreateSubAdminDto,
  UbahPasswordDto,
  UpdateKebijakanOnboardingDto,
  UpdateNotifikasiDto,
  UpdateProfilDto,
} from './dto/pengaturan.dto';

@Injectable()
export class PengaturanService {
  constructor(private prisma: PrismaService) {}

  // Setting-nya singleton (1 row buat seluruh platform).
  // Kalau belum pernah dibuat, otomatis dibuatin dengan nilai default.
  private async getOrCreateSetting() {
    const existing = await this.prisma.platformSetting.findFirst();
    if (existing) return existing;
    return this.prisma.platformSetting.create({ data: {} });
  }

  async getSettings() {
    const setting = await this.getOrCreateSetting();
    const subAdmins = await this.getSubAdmins();
    return {
      kebijakanOnboarding: {
        autoApproveTenant: setting.autoApproveTenant,
        graceDaysPending: setting.graceDaysPending,
      },
      notifikasi: {
        notifTenantBaru: setting.notifTenantBaru,
        notifTagihan: setting.notifTagihan,
        notifKeamanan: setting.notifKeamanan,
        notifLaporanMingguan: setting.notifLaporanMingguan,
      },
      subAdmins,
    };
  }

  async updateKebijakanOnboarding(dto: UpdateKebijakanOnboardingDto) {
    const setting = await this.getOrCreateSetting();
    return this.prisma.platformSetting.update({ where: { id: setting.id }, data: dto });
  }

  async updateNotifikasi(dto: UpdateNotifikasiDto) {
    const setting = await this.getOrCreateSetting();
    return this.prisma.platformSetting.update({ where: { id: setting.id }, data: dto });
  }

  async getSubAdmins() {
    return this.prisma.user.findMany({
      where: { role: Role.SUPER_ADMIN, tenantId: null, isRootAdmin: false },
      select: { id: true, nama: true, email: true, subRole: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createSubAdmin(dto: CreateSubAdminDto) {
    const exists = await this.prisma.user.findFirst({ where: { email: dto.email } });
    if (exists) throw new ConflictException('Email sudah dipakai.');

    const passwordHash = await bcrypt.hash(dto.password, 10);
    return this.prisma.user.create({
      data: {
        nama: dto.nama,
        email: dto.email,
        passwordHash,
        role: Role.SUPER_ADMIN,
        tenantId: null,
        subRole: dto.subRole,
        isRootAdmin: false,
      },
      select: { id: true, nama: true, email: true, subRole: true, createdAt: true },
    });
  }

  async removeSubAdmin(id: string) {
    const user = await this.prisma.user.findFirst({
      where: { id, role: Role.SUPER_ADMIN, tenantId: null, isRootAdmin: false },
    });
    if (!user) throw new NotFoundException('Sub-admin tidak ditemukan.');
    await this.prisma.user.delete({ where: { id } });
    return { message: 'Akses sub-admin dicabut.' };
  }

    async updateProfil(userId: string, dto: UpdateProfilDto) {
    console.log('[updateProfil] userId dari token:', userId, '| email dikirim:', dto.email);

    const current = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!current) throw new NotFoundException('Pengguna tidak ditemukan.');

    console.log('[updateProfil] akun di DB:', current.id, current.email);

    const data: { nama?: string; email?: string } = {};
    if (dto.nama?.trim()) data.nama = dto.nama.trim();

    const emailBaru = dto.email?.trim().toLowerCase();
    if (emailBaru && emailBaru !== current.email.toLowerCase()) {
      const dipakai = await this.prisma.user.findFirst({
        where: { email: emailBaru, id: { not: current.id } },
      });
      if (dipakai) throw new ConflictException('Email sudah dipakai pengguna lain.');
      data.email = emailBaru;
    }

    return this.prisma.user.update({
      where: { id: current.id },
      data,
      select: { id: true, nama: true, email: true, role: true },
    });
  }

  async ubahPassword(userId: string, dto: UbahPasswordDto) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new NotFoundException('Pengguna tidak ditemukan.');

    const cocok = await bcrypt.compare(dto.passwordLama, user.passwordHash);
    if (!cocok) throw new BadRequestException('Password saat ini salah.');

    const passwordHash = await bcrypt.hash(dto.passwordBaru, 10);
    await this.prisma.user.update({ where: { id: userId }, data: { passwordHash } });
    return { message: 'Password berhasil diubah.' };
  }
}