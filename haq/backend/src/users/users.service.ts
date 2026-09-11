import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import * as bcrypt from 'bcryptjs';
import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto, UpdateUserDto } from './dto/user.dto';
import { Role } from '@prisma/client';

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

    const passwordHash = await bcrypt.hash(dto.password, 10);
    return this.prisma.user.create({
      data: {
        tenantId,
        nama: dto.nama,
        email: dto.email,
        passwordHash,
        role: dto.role,
      },
      select: { id: true, nama: true, email: true, role: true },
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
    await this.prisma.user.delete({ where: { id } });
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