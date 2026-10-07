import { BadRequestException, ConflictException, Injectable, NotFoundException } from '@nestjs/common';
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

    const passwordHash = await bcrypt.hash(dto.password, 10);

    return this.prisma.$transaction(async (tx) => {
      const user = await tx.user.create({
        data: {
          tenantId,
          nama: dto.nama,
          email: dto.email,
          passwordHash,
          role: dto.role,
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

  async remove(tenantId: string, id: string) {
    const user = await this.prisma.user.findFirst({ where: { id, tenantId } });
    if (!user) throw new NotFoundException('User tidak ditemukan.');
    await this.prisma.$transaction([
      this.prisma.ustadz.updateMany({ where: { userId: id, tenantId }, data: { userId: null } }),
      this.prisma.user.delete({ where: { id } }),
    ]);
    return { message: 'User dihapus.' };
  }

  async toggleStatus(tenantId: string, id: string) {
    const user = await this.prisma.user.findFirst({ where: { id, tenantId } });
    if (!user) throw new NotFoundException('User tidak ditemukan.');
    const updated = await this.prisma.user.update({
      where: { id },
      data: { status: user.status === 'AKTIF' ? 'NONAKTIF' : 'AKTIF' },
    });
    return { status: updated.status };
  }
}