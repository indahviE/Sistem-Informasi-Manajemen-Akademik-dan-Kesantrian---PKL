import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateWaliDto, LinkWaliUserDto } from './dto/wali.dto';

@Injectable()
export class WaliService {
  constructor(private prisma: PrismaService) {}

  async findAll(tenantId: string) {
    return this.prisma.waliSantri.findMany({
      where: { tenantId },
      include: {
        _count: { select: { santris: true } },
        user: { select: { id: true, email: true } },
      },
      orderBy: { nama: 'asc' },
    });
  }

  async create(tenantId: string, dto: CreateWaliDto) {
    return this.prisma.waliSantri.create({
      data: { tenantId, ...dto },
    });
  }

  async update(tenantId: string, id: string, dto: Partial<CreateWaliDto>) {
    const found = await this.prisma.waliSantri.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Wali tidak ditemukan.');
    return this.prisma.waliSantri.update({ where: { id }, data: dto });
  }

  async linkUser(tenantId: string, dto: LinkWaliUserDto) {
    const wali = await this.prisma.waliSantri.findFirst({
      where: { id: dto.waliId, tenantId },
    });
    if (!wali) throw new NotFoundException('Wali tidak ditemukan.');

    const user = await this.prisma.user.findFirst({
      where: { id: dto.userId, tenantId },
    });
    if (!user) throw new NotFoundException('User tidak ditemukan.');

    return this.prisma.waliSantri.update({
      where: { id: dto.waliId },
      data: { userId: dto.userId },
    });
  }

  async myProfile(userId: string) {
    const wali = await this.prisma.waliSantri.findFirst({
      where: { userId },
      include: {
        santris: { include: { kelas: { select: { namaKelas: true } } } },
      },
    });
    if (!wali) throw new NotFoundException('Akun wali belum terhubung ke data santri.');
    return wali;
  }
}