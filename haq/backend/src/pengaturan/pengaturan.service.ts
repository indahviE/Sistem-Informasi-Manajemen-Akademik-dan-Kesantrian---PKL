import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import {
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

  async updateProfil(userId: string, dto: UpdateProfilDto) {
    const current = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!current) throw new NotFoundException('Pengguna tidak ditemukan.');

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