import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateKelasDto,
  CreateMapelDto,
  CreateTahunAjaranDto,
  CreateUstadzDto,
  UpdateKelasDto,
  UpdateMapelDto,
  UpdateUstadzDto,
} from './dto/master.dto';

@Injectable()
export class MasterDataService {
  constructor(private prisma: PrismaService) {}

  // ===== Ustadz / Pembina =====
  findAllUstadz(tenantId: string, jenis?: string) {
    return this.prisma.ustadz.findMany({
      where: { tenantId, ...(jenis ? { jenis: jenis as any } : {}) },
      orderBy: { nama: 'asc' },
    });
  }

  createUstadz(tenantId: string, dto: CreateUstadzDto) {
    return this.prisma.ustadz.create({ data: { tenantId, ...dto } });
  }

  async updateUstadz(tenantId: string, id: string, dto: UpdateUstadzDto) {
    const found = await this.prisma.ustadz.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Ustadz tidak ditemukan.');
    return this.prisma.ustadz.update({ where: { id }, data: dto });
  }

  async removeUstadz(tenantId: string, id: string) {
    const found = await this.prisma.ustadz.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Ustadz tidak ditemukan.');
    await this.prisma.ustadz.delete({ where: { id } });
    return { message: 'Ustadz dihapus.' };
  }

  // ===== Kelas / Halaqah =====
  findAllKelas(tenantId: string) {
    return this.prisma.kelas.findMany({
      where: { tenantId },
      include: {
        waliKelas: { select: { id: true, nama: true } },
        tahunAjaran: { select: { id: true, nama: true } },
        _count: { select: { santris: true } },
      },
      orderBy: { tingkat: 'asc' },
    });
  }

  createKelas(tenantId: string, dto: CreateKelasDto) {
    return this.prisma.kelas.create({
      data: { tenantId, ...dto },
    });
  }

  async updateKelas(tenantId: string, id: string, dto: UpdateKelasDto) {
    const found = await this.prisma.kelas.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Kelas tidak ditemukan.');
    return this.prisma.kelas.update({ where: { id }, data: dto });
  }

  async removeKelas(tenantId: string, id: string) {
    const found = await this.prisma.kelas.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Kelas tidak ditemukan.');
    await this.prisma.kelas.delete({ where: { id } });
    return { message: 'Kelas dihapus.' };
  }

  // ===== Mata Pelajaran =====
  findAllMapel(tenantId: string) {
    return this.prisma.mataPelajaran.findMany({
      where: { tenantId },
      orderBy: { namaMapel: 'asc' },
    });
  }

  createMapel(tenantId: string, dto: CreateMapelDto) {
    return this.prisma.mataPelajaran.create({ data: { tenantId, ...dto } });
  }

  async updateMapel(tenantId: string, id: string, dto: UpdateMapelDto) {
    const found = await this.prisma.mataPelajaran.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Mapel tidak ditemukan.');
    return this.prisma.mataPelajaran.update({ where: { id }, data: dto });
  }

  async removeMapel(tenantId: string, id: string) {
    const found = await this.prisma.mataPelajaran.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Mapel tidak ditemukan.');
    await this.prisma.mataPelajaran.delete({ where: { id } });
    return { message: 'Mapel dihapus.' };
  }

  // ===== Tahun Ajaran =====
  findAllTahunAjaran(tenantId: string) {
    return this.prisma.tahunAjaran.findMany({
      where: { tenantId },
      orderBy: { nama: 'desc' },
    });
  }

  createTahunAjaran(tenantId: string, dto: CreateTahunAjaranDto) {
    return this.prisma.tahunAjaran.create({ data: { tenantId, ...dto } });
  }

    async setTahunAjaranAktif(tenantId: string, id: string) {
    // Pastikan tahun ajaran dengan id ini memang milik tenant yang login —
    // tanpa cek ini, admin tenant lain bisa mengaktifkan tahun ajaran
    // milik tenant lain (celah kritis isolasi data, lihat PRD bagian 8).
    const milikTenant = await this.prisma.tahunAjaran.findFirst({
      where: { id, tenantId },
    });
    if (!milikTenant) throw new NotFoundException('Tahun ajaran tidak ditemukan.');

    await this.prisma.$transaction([
      this.prisma.tahunAjaran.updateMany({
        where: { tenantId },
        data: { aktif: false },
      }),
      this.prisma.tahunAjaran.update({
        where: { id },
        data: { aktif: true },
      }),
    ]);
    return { message: 'Tahun ajaran aktif diperbarui.' };
  }
}