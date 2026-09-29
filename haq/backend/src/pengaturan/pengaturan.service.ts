import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { SantriStatus, StatusSubscription } from '@prisma/client';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import {
  UbahPasswordDto,
  UpdateKebijakanOnboardingDto,
  UpdateNotifikasiAdminDto,
  UpdateNotifikasiDto,
  UpdateProfilDto,
} from './dto/pengaturan.dto';

const NOTIF_ADMIN_SELECT = {
  perizinanBaru: true,
  pelanggaranBaru: true,
  waliBelumAktivasi: true,
  eskalasiDarurat: true,
  rekapAbsensiShalat: true,
} as const;

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

    const data: { nama?: string; email?: string; noHp?: string | null } = {};
    if (dto.nama?.trim()) data.nama = dto.nama.trim();
    if (dto.noHp !== undefined) data.noHp = dto.noHp.trim() || null;

    const emailBaru = dto.email?.trim().toLowerCase();
    if (emailBaru && emailBaru !== current.email.toLowerCase()) {
      // Unique-nya per tenant ([tenantId, email]), jadi cek dibatasi ke tenant yang sama.
      const dipakai = await this.prisma.user.findFirst({
        where: { email: emailBaru, tenantId: current.tenantId, id: { not: current.id } },
      });
      if (dipakai) throw new ConflictException('Email sudah dipakai pengguna lain.');
      data.email = emailBaru;
    }

    return this.prisma.user.update({
      where: { id: current.id },
      data,
      select: { id: true, nama: true, email: true, noHp: true, role: true },
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

  // ===== Admin Lembaga =====

  async getAdminSettings(userId: string) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      select: {
        id: true,
        nama: true,
        email: true,
        noHp: true,
        role: true,
        tenantId: true,
        tenant: { select: { namaPondok: true, kodeTenant: true } },
      },
    });
    if (!user) throw new NotFoundException('Pengguna tidak ditemukan.');
    if (!user.tenantId) throw new BadRequestException('Akun ini tidak terhubung ke pondok.');

    const [sub, santriAktif, notif] = await Promise.all([
      this.prisma.subscription.findFirst({
        where: { tenantId: user.tenantId, status: StatusSubscription.AKTIF },
        orderBy: { tanggalMulai: 'desc' },
        include: { paket: true },
      }),
      this.prisma.santri.count({
        where: { tenantId: user.tenantId, status: SantriStatus.AKTIF },
      }),
      this.prisma.userNotifSetting.upsert({
        where: { userId },
        create: { userId },
        update: {},
        select: NOTIF_ADMIN_SELECT,
      }),
    ]);

    let paket: Record<string, unknown> | null = null;
    if (sub) {
      const limit = sub.paket.limitSantri;
      const sisaHari = sub.tanggalAkhir
        ? Math.max(0, Math.ceil((sub.tanggalAkhir.getTime() - Date.now()) / 86400000))
        : null;
      paket = {
        nama: sub.paket.nama,
        periode: sub.paket.periode,
        tanggalMulai: sub.tanggalMulai,
        tanggalAkhir: sub.tanggalAkhir,
        sisaHari,
        limitSantri: limit,
        santriAktif,
        persenSantri: limit > 0 ? Math.min(100, Math.round((santriAktif / limit) * 100)) : 0,
      };
    }

    return {
      profil: {
        id: user.id,
        nama: user.nama,
        email: user.email,
        noHp: user.noHp,
        role: user.role,
      },
      tenant: user.tenant,
      paket,
      notifikasi: notif,
    };
  }

  async updateAdminNotifikasi(userId: string, dto: UpdateNotifikasiAdminDto) {
    return this.prisma.userNotifSetting.upsert({
      where: { userId },
      create: { userId, ...dto },
      update: dto,
      select: NOTIF_ADMIN_SELECT,
    });
  }
}