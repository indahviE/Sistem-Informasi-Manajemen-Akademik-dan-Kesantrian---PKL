import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import {
  CreateKesehatanDto,
  CreateKunjunganDto,
  CreatePelanggaranDto,
  CreatePerizinanDto,
  CreateTataTertibDto,
  QueryKesantrianDto,
  UpdatePelanggaranDto,
  UpdatePerizinanDto,
} from './dto/kesantrian.dto';
import { JenisNotifikasi, Prisma, Role } from '@prisma/client';
@Injectable()
export class KesantrianService {
  constructor(private prisma: PrismaService) {}

  private async assertSantri(tenantId: string, santriId: string) {
    const found = await this.prisma.santri.findFirst({ where: { id: santriId, tenantId }, include: { wali: true } });
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

  private async notifyWali(
    tenantId: string,
    wali: { id: string } | null | undefined,
    jenis: JenisNotifikasi,
    pesan: string,
  ) {
    if (!wali) return;
    const waliUser = await this.prisma.waliSantri.findFirst({
      where: { id: wali.id },
      include: { user: true },
    });
    const userIds = waliUser?.user ? [waliUser.user.id] : [];
    for (const userId of userIds) {
      await this.prisma.notifikasi.create({ data: { tenantId, userId, jenis, pesan } });
    }
  }

  // ===== Pelanggaran =====
  async findAllPelanggaran(tenantId: string, query: QueryKesantrianDto, user: RequestUser) {
  const santriId = await this.buildSantriScope(tenantId, user, query.santriId);
  return this.prisma.pelanggaran.findMany({
    where: {
      tenantId,
      ...(santriId ? { santriId } : {}),
      ...(query.kelasId ? { santri: { kelasId: query.kelasId } } : {}),
      },
      include: {
        santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } },
      },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createPelanggaran(tenantId: string, dto: CreatePelanggaranDto, user: RequestUser) {
    const santri = await this.assertSantri(tenantId, dto.santriId);
    const created = await this.prisma.pelanggaran.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        jenisPelanggaran: dto.jenisPelanggaran,
        poin: dto.poin,
        tanggal: new Date(dto.tanggal),
        pelaporId: user.userId,
        tindakLanjut: dto.tindakLanjut,
      },
    });
    await this.notifyWali(
      tenantId,
      santri.wali,
      JenisNotifikasi.PELANGGARAN,
      `${santri.nama} tercatat pelanggaran: ${dto.jenisPelanggaran} (${dto.poin} poin).`,
    );
    return created;
  }

  async updatePelanggaran(tenantId: string, id: string, dto: UpdatePelanggaranDto) {
    const found = await this.prisma.pelanggaran.findFirst({ where: { id, tenantId } });
    if (!found) throw new NotFoundException('Pelanggaran tidak ditemukan.');
    return this.prisma.pelanggaran.update({ where: { id }, data: dto });
  }

  // ===== Perizinan =====
    async findAllPerizinan(tenantId: string, query: QueryKesantrianDto, user: RequestUser) {
    const santriId = await this.buildSantriScope(tenantId, user, query.santriId);
    return this.prisma.perizinan.findMany({
      where: {
        tenantId,
        ...(santriId ? { santriId } : {}),
      },
      include: {
        santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } },
      },
      orderBy: { tanggalKeluar: 'desc' },
    });
  }

  async createPerizinan(tenantId: string, dto: CreatePerizinanDto, user: RequestUser) {
    const santri = await this.assertSantri(tenantId, dto.santriId);
    const created = await this.prisma.perizinan.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        jenis: dto.jenis,
        tanggalKeluar: new Date(dto.tanggalKeluar),
        tanggalKembali: dto.tanggalKembali ? new Date(dto.tanggalKembali) : null,
        alasan: dto.alasan,
        catatan: dto.catatan,
      },
    });
    await this.notifyWali(
      tenantId,
      santri.wali,
      JenisNotifikasi.PERIZINAN,
      `${santri.nama} mengajukan izin ${dto.jenis === 'PULANG' ? 'pulang' : 'keluar'} dengan alasan: ${dto.alasan}.`,
    );
    return created;
  }

  async updatePerizinan(tenantId: string, id: string, dto: UpdatePerizinanDto, user: RequestUser) {
    const found = await this.prisma.perizinan.findFirst({
      where: { id, tenantId },
      include: { santri: { include: { wali: true } } },
    });
    if (!found) throw new NotFoundException('Perizinan tidak ditemukan.');

    let tanggalKembali = dto.tanggalKembali ? new Date(dto.tanggalKembali) : found.tanggalKembali;
    let statusApproval = dto.statusApproval;

    if (statusApproval === 'KEMBALI' && tanggalKembali && found.tanggalKeluar) {
      const telat = tanggalKembali > found.tanggalKeluar && found.jenis === 'PULANG';
      if (telat) {
        statusApproval = 'TELAT';
      }
    }

    const updated = await this.prisma.perizinan.update({
      where: { id },
      data: {
        statusApproval,
        tanggalKembali,
        disetujuiOleh: dto.disetujuiOleh || user.userId,
        catatan: dto.catatan,
      },
    });

    await this.notifyWali(
      tenantId,
      found.santri.wali,
      JenisNotifikasi.PERIZINAN,
      `Status izin ${found.santri.nama} diperbarui menjadi ${statusApproval}.`,
    );
    return updated;
  }

  // ===== Kesehatan =====
  async findAllKesehatan(tenantId: string, query: QueryKesantrianDto) {
    return this.prisma.kesehatanLog.findMany({
      where: {
        tenantId,
        ...(query.santriId ? { santriId: query.santriId } : {}),
        ...(query.kelasId ? { santri: { kelasId: query.kelasId } } : {}),
      },
      include: { santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } } },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createKesehatan(tenantId: string, dto: CreateKesehatanDto, user: RequestUser) {
    const santri = await this.assertSantri(tenantId, dto.santriId);
    const created = await this.prisma.kesehatanLog.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        keluhan: dto.keluhan,
        diagnosa: dto.diagnosa,
        tindakan: dto.tindakan,
        obat: dto.obat,
        tempat: dto.tempat ?? 'UKS',
        tanggal: new Date(dto.tanggal),
        status: dto.status ?? 'RAWAT_JALAN',
        inputOleh: user.userId,
      },
    });
    await this.notifyWali(
      tenantId,
      santri.wali,
      JenisNotifikasi.KESEHATAN,
      `${santri.nama} sedang sakit: ${dto.keluhan}.`,
    );
    return created;
  }

  // ===== Kunjungan Wali =====
  async findAllKunjungan(tenantId: string, query: QueryKesantrianDto) {
    return this.prisma.kunjunganWali.findMany({
      where: {
        tenantId,
        ...(query.santriId ? { santriId: query.santriId } : {}),
      },
      include: {
        santri: { select: { id: true, nama: true, nis: true } },
        wali: { select: { id: true, nama: true, hubungan: true } },
      },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createKunjungan(tenantId: string, dto: CreateKunjunganDto) {
    await this.assertSantri(tenantId, dto.santriId);
    return this.prisma.kunjunganWali.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        waliId: dto.waliId,
        tanggal: new Date(dto.tanggal),
        catatan: dto.catatan,
      },
    });
  }

  // ===== Tata Tertib =====
  async findAllTataTertib(tenantId: string) {
    return this.prisma.tataTertib.findMany({
      where: { tenantId, aktif: true },
      orderBy: { createdAt: 'desc' },
    });
  }

  async createTataTertib(tenantId: string, dto: CreateTataTertibDto) {
    return this.prisma.tataTertib.create({
      data: { tenantId, judul: dto.judul, isi: dto.isi },
    });
  }

  // ===== Rekam Medis =====
  async getRekamMedis(tenantId: string, santriId: string) {
    await this.assertSantri(tenantId, santriId);
    const rekam = await this.prisma.rekamMedis.findFirst({
      where: { santriId, tenantId },
    });
    if (!rekam) {
      return {
        santriId,
        golonganDarah: null,
        alergi: null,
        riwayatPenyakit: null,
        tinggiBadan: null,
        beratBadan: null,
        catatanKhusus: null,
        kosong: true,
      };
    }
    return rekam;
  }

  async upsertRekamMedis(tenantId: string, santriId: string, dto: any) {
    await this.assertSantri(tenantId, santriId);
    const data = {
      golonganDarah: dto.golonganDarah ?? null,
      alergi: dto.alergi ?? null,
      riwayatPenyakit: dto.riwayatPenyakit ?? null,
      tinggiBadan: dto.tinggiBadan != null ? Number(dto.tinggiBadan) : null,
      beratBadan: dto.beratBadan != null ? Number(dto.beratBadan) : null,
      catatanKhusus: dto.catatanKhusus ?? null,
    };
    return this.prisma.rekamMedis.upsert({
      where: { santriId },
      create: { tenantId, santriId, ...data },
      update: data,
    });
  }
}