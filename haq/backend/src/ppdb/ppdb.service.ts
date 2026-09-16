import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { StatusPendaftaran } from '@prisma/client';
import {
  CreatePlacementTestDto,
  DaftarPpdbDto,
  QueryPpdbDto,
  UpdatePendaftaranDto,
} from './dto/ppdb.dto';

@Injectable()
export class PpdbService {
  constructor(private prisma: PrismaService) {}

  async daftar(dto: DaftarPpdbDto) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { kodeTenant: dto.kodeTenant },
    });
    if (!tenant) {
      throw new NotFoundException(
        'Pondok dengan kode tersebut tidak ditemukan. Periksa kembali kode PPDB.',
      );
    }
    if (tenant.status !== 'AKTIF') {
      throw new BadRequestException('Pondok ini belum membuka PPDB online.');
    }

    const pendaftaran = await this.prisma.pendaftaran.create({
      data: {
        tenantId: tenant.id,
        nama: dto.nama,
        jenisKelamin: dto.jenisKelamin,
        tanggalLahir: dto.tanggalLahir ? new Date(dto.tanggalLahir) : null,
        asalSekolah: dto.asalSekolah,
        noHp: dto.noHp,
        email: dto.email,
        alamat: dto.alamat,
        jalur: dto.jalur,
        fotoUrl: dto.fotoUrl,
        kartuKeluargaUrl: dto.kartuKeluargaUrl,
        aktaLahirUrl: dto.aktaLahirUrl,
      },
    });

    await this.prisma.notifikasi.create({
      data: {
        tenantId: tenant.id,
        jenis: 'SISTEM',
        pesan: `Pendaftar baru PPDB: ${dto.nama}. Segera tinjau di menu PPDB.`,
      },
    });

    return {
      id: pendaftaran.id,
      noPendaftaran: this.noPendaftaran(tenant.kodeTenant, pendaftaran.id),
      nama: pendaftaran.nama,
      status: pendaftaran.status,
      message:
        'Pendaftaran berhasil dikirim. Panitia pondok akan meninjau dan menghubungi Anda.',
    };
  }

  async lookup(kodeTenant: string) {
    const tenant = await this.prisma.tenant.findUnique({
      where: { kodeTenant },
      select: {
        id: true,
        namaPondok: true,
        kodeTenant: true,
        logoUrl: true,
        status: true,
        kuotaSantriPpdb: true,
        statusGelombangPpdb: true,
      },
    });
    if (!tenant) {
      throw new NotFoundException(
        'Pondok dengan kode tersebut tidak ditemukan. Periksa kembali kode PPDB.',
      );
    }
    if (tenant.status !== 'AKTIF') {
      throw new BadRequestException('Pondok ini belum membuka PPDB online.');
    }

    const jumlahDiterima = await this.prisma.pendaftaran.count({
      where: { tenantId: tenant.id, status: StatusPendaftaran.DITERIMA },
    });
    const sisaKuota =
      tenant.kuotaSantriPpdb != null
        ? Math.max(tenant.kuotaSantriPpdb - jumlahDiterima, 0)
        : null;

    return {
      namaPondok: tenant.namaPondok,
      kodeTenant: tenant.kodeTenant,
      logoUrl: tenant.logoUrl,
      gelombang: {
        status: tenant.statusGelombangPpdb,
        kuota: tenant.kuotaSantriPpdb,
        sisaKuota,
      },
    };
  }

  async findAll(tenantId: string, q: QueryPpdbDto) {
    const where: any = { tenantId };
    if (q.status) where.status = q.status;
    if (q.q) {
      where.OR = [
        { nama: { contains: q.q } },
        { email: { contains: q.q } },
        { noHp: { contains: q.q } },
      ];
    }
    const list = await this.prisma.pendaftaran.findMany({
      where,
      orderBy: { tanggalDaftar: 'desc' },
      include: { ujian: true },
    });
    return list.map((p) => ({ ...p, noPendaftaran: this.noPendaftaranLabel(p.id) }));
  }

  async findOne(tenantId: string, id: string) {
    const p = await this.prisma.pendaftaran.findFirst({
      where: { id, tenantId },
      include: { ujian: true },
    });
    if (!p) throw new NotFoundException('Pendaftaran tidak ditemukan.');
    return p;
  }

  async updateStatus(tenantId: string, id: string, dto: UpdatePendaftaranDto) {
    const p = await this.prisma.pendaftaran.findFirst({
      where: { id, tenantId },
      include: { tenant: true },
    });
    if (!p) throw new NotFoundException('Pendaftaran tidak ditemukan.');

    const nextStatus = dto.status ?? p.status;
    const updated = await this.prisma.pendaftaran.update({
      where: { id },
      data: { status: nextStatus, catatan: dto.catatan ?? p.catatan },
    });

    if (nextStatus === StatusPendaftaran.DITERIMA) {
      await this.createSantriDariPendaftaran(p);
    }

    if (nextStatus === StatusPendaftaran.DITERIMA || nextStatus === StatusPendaftaran.DITOLAK) {
      await this.prisma.notifikasi.create({
        data: {
          tenantId,
          jenis: 'SISTEM',
          pesan:
            nextStatus === StatusPendaftaran.DITERIMA
              ? `Selamat, ${p.nama} dinyatakan DITERIMA.`
              : `Kami mohon maaf, ${p.nama} belum diterima.`,
        },
      });
    }

    return { ...updated, message: 'Status pendaftaran diperbarui.' };
  }

  private async createSantriDariPendaftaran(p: {
    id: string;
    tenantId: string;
    nama: string;
    jenisKelamin: string;
    tanggalLahir?: Date | null;
  }) {
    const tahun = new Date().getFullYear();
    const jumlah = await this.prisma.santri.count({
      where: { tenantId: p.tenantId, tahunMasuk: tahun },
    });
    const nis = `${tahun}${String(jumlah + 1).padStart(4, '0')}`;

    const nisExists = await this.prisma.santri.findUnique({
      where: { tenantId_nis: { tenantId: p.tenantId, nis } },
    });
    if (nisExists) {
      throw new ConflictException('Gagal membuat NIS. Coba lagi.');
    }

    return this.prisma.santri.create({
      data: {
        tenantId: p.tenantId,
        nis,
        nama: p.nama,
        jenisKelamin: p.jenisKelamin,
        tanggalLahir: p.tanggalLahir ?? null,
        tahunMasuk: tahun,
      },
    });
  }

  private noPendaftaranLabel(id: string) {
    return `PPDB-${id.slice(-6).toUpperCase()}`;
  }

  private noPendaftaran(kodeTenant: string, id: string) {
    return `PPDB-${kodeTenant.toUpperCase()}-${id.slice(-6).toUpperCase()}`;
  }

  // ===== Placement Test =====
  async createPlacementTest(tenantId: string, pendaftaranId: string, dto: CreatePlacementTestDto) {
    const p = await this.prisma.pendaftaran.findFirst({
      where: { id: pendaftaranId, tenantId },
    });
    if (!p) throw new NotFoundException('Pendaftaran tidak ditemukan.');

    const existing = await this.prisma.placementTest.findUnique({
      where: { pendaftaranId },
    });
    if (existing) {
      throw new ConflictException('Placement test untuk pendaftar ini sudah ada.');
    }

    return this.prisma.placementTest.create({
      data: {
        tenantId,
        pendaftaranId,
        mapelId: dto.mapelId,
        nilai: dto.nilai,
        hasil: dto.hasil,
        catatan: dto.catatan,
        tanggal: dto.tanggal ? new Date(dto.tanggal) : new Date(),
      },
    });
  }

  async getPlacementTest(tenantId: string, pendaftaranId: string) {
    const test = await this.prisma.placementTest.findFirst({
      where: { pendaftaranId, tenantId },
    });
    if (!test) throw new NotFoundException('Placement test belum diisi.');
    return test;
  }

  async updatePlacementTest(tenantId: string, pendaftaranId: string, dto: CreatePlacementTestDto) {
    const test = await this.prisma.placementTest.findFirst({
      where: { pendaftaranId, tenantId },
    });
    if (!test) throw new NotFoundException('Placement test belum diisi.');

    return this.prisma.placementTest.update({
      where: { id: test.id },
      data: {
        mapelId: dto.mapelId ?? test.mapelId,
        nilai: dto.nilai ?? test.nilai,
        hasil: dto.hasil ?? test.hasil,
        catatan: dto.catatan ?? test.catatan,
        tanggal: dto.tanggal ? new Date(dto.tanggal) : test.tanggal,
      },
    });
  }
}
