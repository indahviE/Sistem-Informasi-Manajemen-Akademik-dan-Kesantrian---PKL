import { Injectable, NotFoundException } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
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
  async findAllUstadz(tenantId: string, jenis?: string) {
    const list = await this.prisma.ustadz.findMany({
      where: { tenantId, ...(jenis ? { jenis: jenis as any } : {}) },
      include: { kelasDiampu: { select: { id: true, namaKelas: true } } },
      orderBy: { nama: 'asc' },
    });

    // Ustadz.userId tidak punya relasi Prisma, jadi akun diambil terpisah (1 query).
    const userIds = list.map((u) => u.userId).filter((x): x is string => !!x);
    const users = userIds.length
      ? await this.prisma.user.findMany({
          where: { id: { in: userIds }, tenantId },
          select: { id: true, email: true, status: true },
        })
      : [];
    const byId = new Map(users.map((u) => [u.id, u]));

    return list.map((u) => ({ ...u, akun: u.userId ? byId.get(u.userId) ?? null : null }));
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
  /**
   * Daftar kelas. Kalau `diampu` true dan yang login USTADZ, hanya kelas yang
   * ia menjadi wali kelasnya. Role lain / tanpa `diampu` = semua kelas (seperti semula).
   */
  async findAllKelas(tenantId: string, user?: RequestUser, diampu = false) {
    const where: any = { tenantId };

    if (diampu && user?.role === Role.USTADZ) {
      const ustadz = await this.prisma.ustadz.findFirst({
        where: { userId: user.userId, tenantId },
      });
      where.waliKelasId = ustadz?.id ?? '__none__';
    }

    return this.prisma.kelas.findMany({
      where,
      include: {
        waliKelas: { select: { id: true, nama: true } },
        tahunAjaran: { select: { id: true, nama: true } },
        _count: { select: { santris: true } },
      },
      orderBy: { tingkat: 'asc' },
    });
  }

  /** Pastikan ustadz yang dipilih sebagai wali kelas milik tenant yang sama. */
  private async cekWaliKelas(tenantId: string, waliKelasId?: string | null) {
    if (!waliKelasId) return;
    const ustadz = await this.prisma.ustadz.findFirst({ where: { id: waliKelasId, tenantId } });
    if (!ustadz) throw new NotFoundException('Ustadz untuk wali kelas tidak ditemukan.');
  }

  async createKelas(tenantId: string, dto: CreateKelasDto) {
    await this.cekWaliKelas(tenantId, dto.waliKelasId);
    return this.prisma.kelas.create({
      data: { tenantId, ...dto },
    });
  }

  async updateKelas(tenantId: string, id: string, dto: UpdateKelasDto) {
    const found = await this.prisma.kelas.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Kelas tidak ditemukan.');
    await this.cekWaliKelas(tenantId, dto.waliKelasId);
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