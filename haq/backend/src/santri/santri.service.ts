import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateSantriDto, QuerySantriDto, UpdateSantriDto } from './dto/santri.dto';

@Injectable()
export class SantriService {
  constructor(private prisma: PrismaService) {}

  async findAll(tenantId: string, query: QuerySantriDto) {
    const { kelasId, search, page = 1, perPage = 20 } = query;
    const where: any = {
      tenantId,
      ...(kelasId ? { kelasId } : {}),
      ...(search
        ? { OR: [{ nama: { contains: search } }, { nis: { contains: search } }] }
        : {}),
    };

    const [items, total] = await this.prisma.$transaction([
      this.prisma.santri.findMany({
        where,
        include: {
          kelas: { select: { id: true, namaKelas: true } },
          wali: { select: { id: true, nama: true, noHp: true } },
        },
        orderBy: { nama: 'asc' },
        skip: (page - 1) * perPage,
        take: perPage,
      }),
      this.prisma.santri.count({ where }),
    ]);

    return { items, total, page, perPage };
  }

  async findOne(tenantId: string, id: string) {
    const santri = await this.prisma.santri.findFirst({
      where: { id, tenantId },
      include: {
        kelas: true,
        wali: true,
        capaianTahfidzs: { orderBy: { tanggalSetor: 'desc' }, take: 10 },
        pelanggarans: { orderBy: { tanggal: 'desc' }, take: 10 },
      },
    });
    if (!santri) throw new NotFoundException('Santri tidak ditemukan.');
    return santri;
  }

  create(tenantId: string, dto: CreateSantriDto) {
    return this.prisma.santri.create({
      data: {
        tenantId,
        nis: dto.nis,
        nama: dto.nama,
        jenisKelamin: dto.jenisKelamin,
        tanggalLahir: dto.tanggalLahir ? new Date(dto.tanggalLahir) : undefined,
        kelasId: dto.kelasId,
        asrama: dto.asrama,
        waliId: dto.waliId,
        tahunMasuk: dto.tahunMasuk,
      },
    });
  }

  async update(tenantId: string, id: string, dto: UpdateSantriDto) {
    const existing = await this.prisma.santri.findFirst({ where: { id, tenantId } });
    if (!existing) throw new NotFoundException('Santri tidak ditemukan.');
    return this.prisma.santri.update({
      where: { id },
      data: {
        nama: dto.nama,
        jenisKelamin: dto.jenisKelamin,
        tanggalLahir: dto.tanggalLahir ? new Date(dto.tanggalLahir) : undefined,
        kelasId: dto.kelasId,
        asrama: dto.asrama,
        waliId: dto.waliId,
      },
    });
  }

  async remove(tenantId: string, id: string) {
    const existing = await this.prisma.santri.findFirst({ where: { id, tenantId } });
    if (!existing) throw new NotFoundException('Santri tidak ditemukan.');
    await this.prisma.santri.delete({ where: { id } });
    return { message: 'Santri dihapus.' };
  }
}