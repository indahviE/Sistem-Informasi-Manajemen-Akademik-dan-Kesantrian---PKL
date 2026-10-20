import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto, UpdateUserDto } from './dto/user.dto';
import { JenisUstadz, Role } from '@prisma/client';

@Injectable()
export class UsersService {
  constructor(private prisma: PrismaService) {}

  async findAll(tenantId: string, role?: Role) {
    return this.prisma.user.findMany({
      where: { tenantId, ...(role ? { role } : {}) },
      select: {
        id: true,
        nama: true,
        email: true,
        role: true,
        status: true,
        createdAt: true,
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async create(tenantId: string, dto: CreateUserDto) {
    const exists = await this.prisma.user.findFirst({
      where: { tenantId, email: dto.email },
    });
    if (exists) throw new ConflictException('Email sudah dipakai.');

    const pengajar = dto.role === Role.USTADZ || dto.role === Role.MUSYRIF;
    const jenisSesuai = dto.role === Role.MUSYRIF ? JenisUstadz.MUSYRIF : JenisUstadz.GURU;
    const wali = dto.role === Role.WALI_SANTRI;

    // Validasi tautan ke data Ustadz yang sudah ada (kalau diminta).
    let ustadzId: string | null = null;
    if (dto.ustadzId) {
      if (!pengajar) {
        throw new BadRequestException('ustadzId hanya untuk role USTADZ atau MUSYRIF.');
      }
      const u = await this.prisma.ustadz.findFirst({ where: { id: dto.ustadzId, tenantId } });
      if (!u) throw new NotFoundException('Data ustadz tidak ditemukan.');
      if (u.jenis !== jenisSesuai) {
        throw new BadRequestException(
          `Role ${dto.role} harus ditautkan ke data ustadz berjenis ${jenisSesuai}.`,
        );
      }
      if (u.userId) {
        const akunLama = await this.prisma.user.findFirst({ where: { id: u.userId, tenantId } });
        if (akunLama) throw new ConflictException('Ustadz ini sudah punya akun.');
      }
      ustadzId = u.id;
    }

    // Validasi khusus wali: tautan ke data wali lama + daftar anak.
    if (!wali && (dto.waliSantriId || dto.santriIds?.length)) {
      throw new BadRequestException('waliSantriId dan santriIds hanya untuk role WALI_SANTRI.');
    }

    let waliSantriId: string | null = null;
    if (dto.waliSantriId) {
      const w = await this.prisma.waliSantri.findFirst({
        where: { id: dto.waliSantriId, tenantId },
      });
      if (!w) throw new NotFoundException('Data wali tidak ditemukan.');
      if (w.userId) throw new ConflictException('Wali ini sudah punya akun.');
      waliSantriId = w.id;
    }

    const santriIds = [...new Set(dto.santriIds ?? [])];
    if (santriIds.length) {
      const jumlah = await this.prisma.santri.count({
        where: { id: { in: santriIds }, tenantId },
      });
      if (jumlah !== santriIds.length) {
        throw new NotFoundException('Sebagian santri tidak ditemukan.');
      }
    }

    const passwordHash = await bcrypt.hash(dto.password, 10);

    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          tenantId,
          nama: dto.nama,
          email: dto.email,
          passwordHash,
          role: dto.role,
          noHp: dto.noHp || undefined,
        },
        select: { id: true, nama: true, email: true, role: true },
      });

      if (ustadzId) {
        await tx.ustadz.update({ where: { id: ustadzId }, data: { userId: user.id } });
      } else if (pengajar) {
        await tx.ustadz.create({
          data: { tenantId, nama: dto.nama, jenis: jenisSesuai, userId: user.id },
        });
      }

      if (wali) {
        let idWali = waliSantriId;
        if (idWali) {
          // Pakai data wali yang sudah ada, tinggal sambungkan ke akun baru.
          await tx.waliSantri.update({ where: { id: idWali }, data: { userId: user.id } });
        } else {
          // Buat data wali baru + sambungkan ke akun.
          const baru = await tx.waliSantri.create({
            data: {
              tenantId,
              nama: dto.nama,
              noHp: dto.noHp || undefined,
              email: dto.email,
              hubungan: dto.hubungan ?? 'Wali',
              userId: user.id,
            },
          });
          idWali = baru.id;
        }

        // Tautkan anak-anak yang dipilih admin (banyak anak = banyak santri, satu wali).
        if (santriIds.length) {
          await tx.santri.updateMany({
            where: { id: { in: santriIds }, tenantId },
            data: { waliId: idWali },
          });
        }
      }

      return user;
    });
  }

  async update(tenantId: string, id: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.findFirst({ where: { id, tenantId } });
    if (!user) throw new NotFoundException('User tidak ditemukan.');

    return this.prisma.user.update({
      where: { id },
      data: {
        nama: dto.nama,
        email: dto.email,
        role: dto.role,
      },
      select: { id: true, nama: true, email: true, role: true },
    });
  }

  async remove(tenantId: string, id: string, requesterId?: string) {
    if (requesterId && requesterId === id) {
      throw new BadRequestException('Kamu tidak bisa menghapus akunmu sendiri.');
    }
    const user = await this.prisma.user.findFirst({ where: { id, tenantId } });
    if (!user) throw new NotFoundException('User tidak ditemukan.');
    if (user.isRootAdmin) {
      throw new ForbiddenException('Akun admin utama tidak bisa dihapus.');
    }
    await this.prisma.$transaction([
      this.prisma.ustadz.updateMany({ where: { userId: id, tenantId }, data: { userId: null } }),
      this.prisma.waliSantri.updateMany({ where: { userId: id, tenantId }, data: { userId: null } }),
      this.prisma.user.delete({ where: { id } }),
    ]);
    return { message: 'User dihapus.' };
  }

  async toggleStatus(tenantId: string, id: string, requesterId?: string) {
    if (requesterId && requesterId === id) {
      throw new BadRequestException('Kamu tidak bisa menonaktifkan akunmu sendiri.');
    }
    const user = await this.prisma.user.findFirst({ where: { id, tenantId } });
    if (!user) throw new NotFoundException('User tidak ditemukan.');
    if (user.isRootAdmin && user.status === 'AKTIF') {
      throw new ForbiddenException('Akun admin utama tidak bisa dinonaktifkan.');
    }
    const updated = await this.prisma.user.update({
      where: { id },
      data: { status: user.status === 'AKTIF' ? 'NONAKTIF' : 'AKTIF' },
    });
    return { status: updated.status };
  }
}