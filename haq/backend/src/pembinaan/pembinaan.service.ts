import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import {
  CreateKeadaanDaruratDto,
  CreatePembinaanIbadahDto,
  CreatePembinaanKarakterDto,
  QueryPembinaanDto,
  UpdateKeadaanDaruratDto,
} from './dto/pembinaan.dto';
import { JenisNotifikasi, Prisma, Role } from '@prisma/client';

const SANTRI_SELECT = {
  id: true,
  nama: true,
  nis: true,
  kelas: { select: { namaKelas: true } },
};

@Injectable()
export class PembinaanService {
  constructor(private prisma: PrismaService) {}

  private async assertSantri(tenantId: string, santriId: string) {
    const found = await this.prisma.santri.findFirst({ where: { id: santriId, tenantId } });
    if (!found) throw new NotFoundException('Santri tidak ditemukan di pondok ini.');
    return found;
  }

  private async getAllowedSantriIdsForWali(tenantId: string, userId: string): Promise<string[]> {
    const walis = await this.prisma.waliSantri.findMany({
      where: { tenantId, userId },
      select: { santris: { select: { id: true } } },
    });
    return walis.flatMap((w) => w.santris.map((s) => s.id));
  }

  private async buildSantriScope(
    tenantId: string,
    user: RequestUser,
    querySantriId?: string,
  ): Promise<Prisma.StringFilter | string | undefined> {
    if (user.role === Role.WALI_SANTRI) {
      const allowedIds = await this.getAllowedSantriIdsForWali(tenantId, user.userId);
      return { in: allowedIds };
    }
    return querySantriId;
  }

  private async notifyStaff(tenantId: string, jenis: JenisNotifikasi, pesan: string) {
    const staff = await this.prisma.user.findMany({
      where: { tenantId, role: { in: [Role.ADMIN, Role.PIMPINAN] }, status: 'AKTIF' },
      select: { id: true },
    });
    for (const s of staff) {
      await this.prisma.notifikasi.create({ data: { tenantId, userId: s.id, jenis, pesan } });
    }
  }

  // ===== Pembinaan Karakter =====
  async findAllPembinaanKarakter(tenantId: string, query: QueryPembinaanDto, user: RequestUser) {
    const santriId = await this.buildSantriScope(tenantId, user, query.santriId);
    return this.prisma.pembinaanKarakter.findMany({
      where: { tenantId, ...(santriId ? { santriId } : {}) },
      include: { santri: { select: SANTRI_SELECT } },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createPembinaanKarakter(tenantId: string, dto: CreatePembinaanKarakterDto, user: RequestUser) {
    await this.assertSantri(tenantId, dto.santriId);
    return this.prisma.pembinaanKarakter.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        tanggal: new Date(dto.tanggal),
        kategori: dto.kategori,
        catatan: dto.catatan,
        pelaporId: user.userId,
      },
      include: { santri: { select: SANTRI_SELECT } },
    });
  }

  // ===== Pembinaan Ibadah =====
  async findAllPembinaanIbadah(tenantId: string, query: QueryPembinaanDto, user: RequestUser) {
    const santriId = await this.buildSantriScope(tenantId, user, query.santriId);
    return this.prisma.pembinaanIbadah.findMany({
      where: { tenantId, ...(santriId ? { santriId } : {}) },
      include: { santri: { select: SANTRI_SELECT } },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createPembinaanIbadah(tenantId: string, dto: CreatePembinaanIbadahDto, user: RequestUser) {
    await this.assertSantri(tenantId, dto.santriId);
    return this.prisma.pembinaanIbadah.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        tanggal: new Date(dto.tanggal),
        jenisIbadah: dto.jenisIbadah,
        status: dto.status ?? 'HADIR',
        catatan: dto.catatan,
        pelaporId: user.userId,
      },
      include: { santri: { select: SANTRI_SELECT } },
    });
  }

  // ===== Keadaan Darurat =====
  async findAllKeadaanDarurat(tenantId: string) {
    return this.prisma.keadaanDarurat.findMany({
      where: { tenantId },
      include: { santri: { select: SANTRI_SELECT } },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createKeadaanDarurat(tenantId: string, dto: CreateKeadaanDaruratDto, user: RequestUser) {
    let santri: { id: string; nama: string } | null = null;
    if (dto.santriId) {
      santri = await this.assertSantri(tenantId, dto.santriId);
    }
    const created = await this.prisma.keadaanDarurat.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        jenis: dto.jenis,
        lokasi: dto.lokasi,
        deskripsi: dto.deskripsi,
        pelaporId: user.userId,
      },
      include: { santri: { select: SANTRI_SELECT } },
    });
    await this.notifyStaff(
      tenantId,
      JenisNotifikasi.DARURAT,
      santri
        ? `Laporan darurat: ${dto.jenis} — ${santri.nama}.`
        : `Laporan darurat: ${dto.jenis}.`,
    );
    return created;
  }

  async updateKeadaanDarurat(tenantId: string, id: string, dto: UpdateKeadaanDaruratDto) {
    const found = await this.prisma.keadaanDarurat.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Laporan keadaan darurat tidak ditemukan.');
    return this.prisma.keadaanDarurat.update({
      where: { id },
      data: { status: dto.status, tindakLanjut: dto.tindakLanjut },
    });
  }
}