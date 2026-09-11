import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKonselingDto, UpdateKonselingDto } from './dto/konseling.dto';

@Injectable()
export class KonselingService {
  constructor(private prisma: PrismaService) {}

  private async assertSantri(tenantId: string, santriId: string) {
    const found = await this.prisma.santri.findFirst({ where: { id: santriId, tenantId } });
    if (!found) throw new NotFoundException('Santri tidak ditemukan di pondok ini.');
    return found;
  }

  async findAllKonseling(tenantId: string, santriId?: string) {
    return this.prisma.konseling.findMany({
      where: { tenantId, ...(santriId ? { santriId } : {}) },
      include: {
        santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } },
        konselor: { select: { id: true, nama: true } },
      },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createKonseling(tenantId: string, dto: CreateKonselingDto, user: RequestUser) {
    await this.assertSantri(tenantId, dto.santriId);
    if (dto.konselorId) {
      const konselor = await this.prisma.ustadz.findFirst({ where: { id: dto.konselorId, tenantId } });
      if (!konselor) throw new NotFoundException('Konselor tidak ditemukan.');
    }
    return this.prisma.konseling.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        tanggal: dto.tanggal ? new Date(dto.tanggal) : new Date(),
        konselorId: dto.konselorId ?? null,
        topik: dto.topik,
        catatan: dto.catatan,
        tindakLanjut: dto.tindakLanjut ?? null,
        privat: dto.privat ?? true,
      },
      include: {
        santri: { select: { id: true, nama: true, nis: true } },
        konselor: { select: { id: true, nama: true } },
      },
    });
  }

  async updateKonseling(tenantId: string, id: string, dto: UpdateKonselingDto) {
    const found = await this.prisma.konseling.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Catatan konseling tidak ditemukan.');
    return this.prisma.konseling.update({
      where: { id },
      data: {
        tanggal: dto.tanggal ? new Date(dto.tanggal) : undefined,
        konselorId: dto.konselorId ?? undefined,
        topik: dto.topik,
        catatan: dto.catatan,
        tindakLanjut: dto.tindakLanjut,
        privat: dto.privat,
      },
    });
  }

  async removeKonseling(tenantId: string, id: string) {
    const found = await this.prisma.konseling.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Catatan konseling tidak ditemukan.');
    return this.prisma.konseling.delete({ where: { id } });
  }
}