import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateKurikulumDto,
  CreateRppDto,
  CreateSilabusDto,
  UpdateKurikulumDto,
  UpdateRppDto,
  UpdateSilabusDto,
} from './dto/kurikulum.dto';

@Injectable()
export class KurikulumService {
  constructor(private prisma: PrismaService) {}

  // ===== Kurikulum =====
  async findAllKurikulum(tenantId: string) {
    return this.prisma.kurikulum.findMany({
      where: { tenantId },
      orderBy: { createdAt: 'desc' },
      include: {
        tahunAjaran: true,
        _count: { select: { silabus: true } },
      },
    });
  }

  async createKurikulum(tenantId: string, dto: CreateKurikulumDto) {
    return this.prisma.kurikulum.create({
      data: { tenantId, ...dto },
      include: { tahunAjaran: true },
    });
  }

  async updateKurikulum(tenantId: string, id: string, dto: UpdateKurikulumDto) {
    const exist = await this.prisma.kurikulum.findFirst({ where: { id, tenantId } });
    if (!exist) throw new NotFoundException('Kurikulum tidak ditemukan.');
    return this.prisma.kurikulum.update({ where: { id }, data: dto });
  }

  async removeKurikulum(tenantId: string, id: string) {
    const exist = await this.prisma.kurikulum.findFirst({ where: { id, tenantId } });
    if (!exist) throw new NotFoundException('Kurikulum tidak ditemukan.');
    return this.prisma.kurikulum.delete({ where: { id } });
  }

  // ===== Silabus =====
  async findAllSilabus(tenantId: string) {
    return this.prisma.silabus.findMany({
      where: { tenantId },
      orderBy: { createdAt: 'desc' },
      include: { kurikulum: true, mapel: true },
    });
  }

  async createSilabus(tenantId: string, dto: CreateSilabusDto) {
    return this.prisma.silabus.create({ data: { tenantId, ...dto } });
  }

  async updateSilabus(tenantId: string, id: string, dto: UpdateSilabusDto) {
    const exist = await this.prisma.silabus.findFirst({ where: { id, tenantId } });
    if (!exist) throw new NotFoundException('Silabus tidak ditemukan.');
    return this.prisma.silabus.update({ where: { id }, data: dto });
  }

  async removeSilabus(tenantId: string, id: string) {
    const exist = await this.prisma.silabus.findFirst({ where: { id, tenantId } });
    if (!exist) throw new NotFoundException('Silabus tidak ditemukan.');
    return this.prisma.silabus.delete({ where: { id } });
  }

  // ===== RPP =====
  async findAllRpp(tenantId: string) {
    return this.prisma.rpp.findMany({
      where: { tenantId },
      orderBy: [{ pertemuan: 'asc' }, { createdAt: 'desc' }],
      include: { mapel: true },
    });
  }

  async createRpp(tenantId: string, dto: CreateRppDto) {
    return this.prisma.rpp.create({
      data: { tenantId, pertemuan: dto.pertemuan ?? 1, ...dto },
    });
  }

  async updateRpp(tenantId: string, id: string, dto: UpdateRppDto) {
    const exist = await this.prisma.rpp.findFirst({ where: { id, tenantId } });
    if (!exist) throw new NotFoundException('RPP tidak ditemukan.');
    return this.prisma.rpp.update({ where: { id }, data: dto });
  }

  async removeRpp(tenantId: string, id: string) {
    const exist = await this.prisma.rpp.findFirst({ where: { id, tenantId } });
    if (!exist) throw new NotFoundException('RPP tidak ditemukan.');
    return this.prisma.rpp.delete({ where: { id } });
  }
}
