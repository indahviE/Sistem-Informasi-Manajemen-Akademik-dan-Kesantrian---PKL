import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import {
  CreateKelulusanDto,
  CreateRemedialDto,
  CreateUjianDto,
  GenerateRaporDto,
  InputNilaiUjianDto,
  UpdateKelulusanDto,
  UpdateRemedialDto,
  UpdateUjianDto,
} from './dto/penilaian.dto';
import { PredikatKelulusan, Prisma, StatusRapor } from '@prisma/client';

@Injectable()
export class PenilaianService {
  constructor(private prisma: PrismaService) {}

  private async assertSantri(tenantId: string, santriId: string) {
    const found = await this.prisma.santri.findFirst({ where: { id: santriId, tenantId } });
    if (!found) throw new NotFoundException('Santri tidak ditemukan di pondok ini.');
    return found;
  }

  // ===== UJIAN =====
  async findAllUjian(tenantId: string, kelasId?: string) {
    return this.prisma.ujian.findMany({
      where: { tenantId, ...(kelasId ? { kelasId } : {}) },
      include: {
        mapel: { select: { id: true, namaMapel: true } },
        kelas: { select: { id: true, namaKelas: true } },
        _count: { select: { nilais: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async getUjian(tenantId: string, id: string) {
    const ujian = await this.prisma.ujian.findFirst({
      where: { id, tenantId },
      include: {
        mapel: { select: { id: true, namaMapel: true } },
        kelas: { select: { id: true, namaKelas: true } },
        nilais: {
          include: { santri: { select: { id: true, nama: true, nis: true } } },
          orderBy: { createdAt: 'asc' },
        },
      },
    });
    if (!ujian) throw new NotFoundException('Ujian tidak ditemukan.');
    return ujian;
  }

  async createUjian(tenantId: string, dto: CreateUjianDto) {
    return this.prisma.ujian.create({
      data: {
        tenantId,
        nama: dto.nama,
        jenis: dto.jenis ?? 'ULANGAN',
        mapelId: dto.mapelId ?? null,
        kelasId: dto.kelasId ?? null,
        tanggal: dto.tanggal ? new Date(dto.tanggal) : null,
        durasiMenit: dto.durasiMenit ?? null,
      },
      include: {
        mapel: { select: { id: true, namaMapel: true } },
        kelas: { select: { id: true, namaKelas: true } },
      },
    });
  }

  async updateUjian(tenantId: string, id: string, dto: UpdateUjianDto) {
    const found = await this.prisma.ujian.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Ujian tidak ditemukan.');
    return this.prisma.ujian.update({
      where: { id },
      data: {
        nama: dto.nama,
        jenis: dto.jenis,
        mapelId: dto.mapelId ?? undefined,
        kelasId: dto.kelasId ?? undefined,
        tanggal: dto.tanggal ? new Date(dto.tanggal) : undefined,
        durasiMenit: dto.durasiMenit,
      },
    });
  }

  async removeUjian(tenantId: string, id: string) {
    const found = await this.prisma.ujian.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Ujian tidak ditemukan.');
    await this.prisma.nilaiUjian.deleteMany({ where: { ujianId: id } });
    await this.prisma.remedial.updateMany({ where: { ujianId: id }, data: { ujianId: null } });
    return this.prisma.ujian.delete({ where: { id } });
  }

  // ===== NILAI UJIAN =====
  async listNilaiUjian(tenantId: string, ujianId: string) {
    await this.getUjian(tenantId, ujianId);
    return this.prisma.nilaiUjian.findMany({
      where: { ujianId, tenantId },
      include: { santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } } },
      orderBy: { santri: { nama: 'asc' } },
    });
  }

  async inputNilaiUjian(tenantId: string, ujianId: string, dto: InputNilaiUjianDto) {
    await this.getUjian(tenantId, ujianId);
    await this.assertSantri(tenantId, dto.santriId);
    return this.prisma.nilaiUjian.upsert({
      where: { ujianId_santriId: { ujianId, santriId: dto.santriId } },
      create: { tenantId, ujianId, santriId: dto.santriId, nilai: dto.nilai, catatan: dto.catatan },
      update: { nilai: dto.nilai, catatan: dto.catatan },
      include: { santri: { select: { id: true, nama: true, nis: true } } },
    });
  }

  async inputNilaiUjianBulk(tenantId: string, ujianId: string, items: InputNilaiUjianDto[], user: RequestUser) {
    await this.getUjian(tenantId, ujianId);
    const created = [];
    for (const item of items) {
      created.push(await this.inputNilaiUjian(tenantId, ujianId, item));
    }
    return created;
  }

  async removeNilaiUjian(tenantId: string, ujianId: string, nilaiId: string) {
    const found = await this.prisma.nilaiUjian.findFirst({ where: { id: nilaiId, ujianId, tenantId } });
    if (!found) throw new NotFoundException('Nilai tidak ditemukan.');
    return this.prisma.nilaiUjian.delete({ where: { id: nilaiId } });
  }

  // ===== REMEDIAL =====
  async findAllRemedial(tenantId: string, santriId?: string) {
    return this.prisma.remedial.findMany({
      where: { tenantId, ...(santriId ? { santriId } : {}) },
      include: {
        santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } },
        ujian: { select: { id: true, nama: true } },
        mapel: { select: { id: true, namaMapel: true } },
      },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createRemedial(tenantId: string, dto: CreateRemedialDto) {
    await this.assertSantri(tenantId, dto.santriId);
    if (dto.ujianId) {
      const ujian = await this.prisma.ujian.findFirst({ where: { id: dto.ujianId, tenantId } });
      if (!ujian) throw new NotFoundException('Ujian tidak ditemukan.');
    }
    return this.prisma.remedial.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        ujianId: dto.ujianId ?? null,
        mapelId: dto.mapelId ?? null,
        keterangan: dto.keterangan,
        hasil: dto.hasil ?? 'PROSES',
        tanggal: dto.tanggal ? new Date(dto.tanggal) : new Date(),
      },
      include: {
        santri: { select: { id: true, nama: true, nis: true } },
        ujian: { select: { id: true, nama: true } },
      },
    });
  }

  async updateRemedial(tenantId: string, id: string, dto: UpdateRemedialDto) {
    const found = await this.prisma.remedial.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Remedial tidak ditemukan.');
    return this.prisma.remedial.update({
      where: { id },
      data: {
        keterangan: dto.keterangan,
        hasil: dto.hasil,
        tanggal: dto.tanggal ? new Date(dto.tanggal) : undefined,
      },
    });
  }

  async removeRemedial(tenantId: string, id: string) {
    const found = await this.prisma.remedial.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Remedial tidak ditemukan.');
    return this.prisma.remedial.delete({ where: { id } });
  }

  // ===== RAPOR =====
  async findAllRapor(tenantId: string, santriId?: string, periode?: string) {
    return this.prisma.rapor.findMany({
      where: { tenantId, ...(santriId ? { santriId } : {}), ...(periode ? { periode } : {}) },
      include: { santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } } },
      orderBy: { periode: 'desc' },
    });
  }

  async getRapor(tenantId: string, id: string) {
    const rapor = await this.prisma.rapor.findFirst({
      where: { id, tenantId },
      include: { santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } } },
    });
    if (!rapor) throw new NotFoundException('Rapor tidak ditemukan.');
    return rapor;
  }

  async generateRapor(tenantId: string, dto: GenerateRaporDto) {
    const santri = await this.assertSantri(tenantId, dto.santriId);

    const nilaiGroup = await this.prisma.nilai.groupBy({
      by: ['mapelId'],
      where: { tenantId, santriId: dto.santriId },
      _avg: { nilai: true },
    });
    const mapelIds = nilaiGroup.map((n) => n.mapelId).filter(Boolean) as string[];
    const mapels = await this.prisma.mataPelajaran.findMany({ where: { tenantId, id: { in: mapelIds } } });
    const mapelMap = new Map(mapels.map((m) => [m.id, m.namaMapel]));

    const nilaiUjianGroup = await this.prisma.nilaiUjian.groupBy({
      by: ['ujianId'],
      where: { tenantId, santriId: dto.santriId },
      _avg: { nilai: true },
    });
    const ujianIds = nilaiUjianGroup.map((n) => n.ujianId).filter(Boolean) as string[];
    const ujians = await this.prisma.ujian.findMany({
      where: { tenantId, id: { in: ujianIds } },
      include: { mapel: { select: { namaMapel: true } } },
    });
    const ujianMap = new Map(ujians.map((u) => [u.id, u.mapel?.namaMapel ?? u.nama]));

    const kehadiran = await this.prisma.absensi.count({
      where: { tenantId, santriId: dto.santriId, status: 'HADIR' },
    });
    const totalAbsensi = await this.prisma.absensi.count({
      where: { tenantId, santriId: dto.santriId },
    });

    const ringkasan: Prisma.JsonObject = {
      mapel: nilaiGroup
        .filter((n) => mapelMap.get(n.mapelId))
        .map((n) => ({ mapel: mapelMap.get(n.mapelId), rataRata: Number(n._avg.nilai?.toFixed(1) ?? 0) })),
      ujian: nilaiUjianGroup
        .filter((n) => ujianMap.get(n.ujianId))
        .map((n) => ({ ujian: ujianMap.get(n.ujianId), rataRata: Number(n._avg.nilai?.toFixed(1) ?? 0) })),
      kehadiran: { hadir: kehadiran, total: totalAbsensi },
    };

    const rataRata = nilaiGroup.length
      ? Number((nilaiGroup.reduce((s, n) => s + (n._avg.nilai ?? 0), 0) / nilaiGroup.length).toFixed(1))
      : null;

    const status = dto.status === 'TERBIT' ? StatusRapor.TERBIT : StatusRapor.DRAFT;

    return this.prisma.rapor.upsert({
      where: { tenantId_santriId_periode: { tenantId, santriId: dto.santriId, periode: dto.periode } },
      create: { tenantId, santriId: dto.santriId, periode: dto.periode, ringkasan, rataRata, status },
      update: { ringkasan, rataRata, status },
      include: { santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } } },
    });
  }

  async terbitRapor(tenantId: string, id: string) {
    const found = await this.prisma.rapor.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Rapor tidak ditemukan.');
    return this.prisma.rapor.update({ where: { id }, data: { status: StatusRapor.TERBIT } });
  }

  async removeRapor(tenantId: string, id: string) {
    const found = await this.prisma.rapor.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Rapor tidak ditemukan.');
    return this.prisma.rapor.delete({ where: { id } });
  }

  // ===== KELULUSAN =====
  async findAllKelulusan(tenantId: string) {
    return this.prisma.kelulusan.findMany({
      where: { tenantId },
      include: { santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } } },
      orderBy: { tanggalKelulusan: 'desc' },
    });
  }

  async createKelulusan(tenantId: string, dto: CreateKelulusanDto) {
    await this.assertSantri(tenantId, dto.santriId);
    let predikat: PredikatKelulusan | undefined;
    if (dto.predikat) {
      predikat = PredikatKelulusan[dto.predikat as keyof typeof PredikatKelulusan];
      if (!predikat) throw new BadRequestException('Predikat tidak valid.');
    }
    return this.prisma.kelulusan.upsert({
      where: { tenantId_santriId: { tenantId, santriId: dto.santriId } },
      create: {
        tenantId,
        santriId: dto.santriId,
        status: dto.status ?? 'LULUS',
        tanggalKelulusan: dto.tanggalKelulusan ? new Date(dto.tanggalKelulusan) : new Date(),
        predikat,
        juzYangDiHafal: dto.juzYangDiHafal ?? null,
        catatan: dto.catatan ?? null,
      },
      update: {
        status: dto.status,
        tanggalKelulusan: dto.tanggalKelulusan ? new Date(dto.tanggalKelulusan) : undefined,
        predikat,
        juzYangDiHafal: dto.juzYangDiHafal,
        catatan: dto.catatan,
      },
      include: { santri: { select: { id: true, nama: true, nis: true } } },
    });
  }

  async updateKelulusan(tenantId: string, id: string, dto: UpdateKelulusanDto) {
    const found = await this.prisma.kelulusan.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Data kelulusan tidak ditemukan.');
    let predikat: PredikatKelulusan | undefined;
    if (dto.predikat) {
      predikat = PredikatKelulusan[dto.predikat as keyof typeof PredikatKelulusan];
      if (!predikat) throw new BadRequestException('Predikat tidak valid.');
    }
    return this.prisma.kelulusan.update({
      where: { id },
      data: {
        status: dto.status,
        tanggalKelulusan: dto.tanggalKelulusan ? new Date(dto.tanggalKelulusan) : undefined,
        predikat,
        juzYangDiHafal: dto.juzYangDiHafal,
        catatan: dto.catatan,
      },
    });
  }

  async removeKelulusan(tenantId: string, id: string) {
    const found = await this.prisma.kelulusan.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Data kelulusan tidak ditemukan.');
    return this.prisma.kelulusan.delete({ where: { id } });
  }
}