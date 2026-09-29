import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  BulkAbsensiDto,
  CreateAbsensiDto,
  CreateNilaiDto,
  CreateTahfidzDto,
  QueryAbsensiDto,
} from './dto/akademik.dto';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { JenisNilai, Role } from '@prisma/client';

@Injectable()
export class AkademikService {
  constructor(private prisma: PrismaService) {}

  private assertSantri(tenantId: string, santriId: string) {
    return this.prisma.santri.findFirst({ where: { id: santriId, tenantId } });
  }

  // ===== Absensi =====
  async findAllAbsensi(tenantId: string, query: QueryAbsensiDto) {
    const where: any = {
      tenantId,
      ...(query.santriId ? { santriId: query.santriId } : {}),
      ...(query.kelasId ? { santri: { kelasId: query.kelasId } } : {}),
      ...(query.mapelId ? { mapelId: query.mapelId } : {}),
      ...(query.startDate || query.endDate
        ? {
            tanggal: {
              ...(query.startDate ? { gte: new Date(query.startDate) } : {}),
              ...(query.endDate ? { lte: new Date(query.endDate) } : {}),
            },
          }
        : {}),
    };

    return this.prisma.absensi.findMany({
      where,
      include: {
        santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } },
        mapel: { select: { id: true, namaMapel: true } },
      },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createAbsensi(tenantId: string, dto: CreateAbsensiDto, user: RequestUser) {
    await this.assertSantriInTenant(tenantId, dto.santriId);
    return this.prisma.absensi.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        kelasId: dto.kelasId,
        mapelId: dto.mapelId,
        tanggal: new Date(dto.tanggal),
        status: dto.status,
        catatan: dto.catatan,
        inputOleh: user.userId,
      },
    });
  }

  async bulkAbsensi(tenantId: string, dto: BulkAbsensiDto, user: RequestUser) {
    const tanggal = new Date(dto.tanggal);
    const mapelId = dto.mapelId ?? null;

    // 1 santri = 1 entri (kalau dobel, yang terakhir dipakai)
    const itemMap = new Map<string, BulkAbsensiDto['items'][number]>();
    for (const i of dto.items) itemMap.set(i.santriId, i);
    const ids = [...itemMap.keys()];

    const valid = await this.prisma.santri.count({ where: { tenantId, id: { in: ids } } });
    if (valid !== ids.length) {
      throw new NotFoundException('Ada santri yang tidak ditemukan di pondok ini.');
    }

    // Rekap untuk kelas + mapel + tanggal ini sudah ada?
    const existing = await this.prisma.absensi.findMany({
      where: {
        tenantId,
        mapelId,
        tanggal,
        OR: [{ kelasId: dto.kelasId }, { santriId: { in: ids } }],
      },
      select: { id: true, santriId: true },
    });

    // Sudah direkap = terkunci; hanya ADMIN yang boleh mengubah
    if (existing.length > 0 && user.role !== Role.ADMIN) {
      throw new ForbiddenException('Absensi sudah direkap. Hanya admin yang dapat mengubahnya.');
    }

    const existingMap = new Map<string, string>();
    for (const e of existing) existingMap.set(e.santriId, e.id);

    await this.prisma.$transaction(
      [...itemMap.values()].map((item) => {
        const existingId = existingMap.get(item.santriId);
        return existingId
          ? this.prisma.absensi.update({
              where: { id: existingId },
              data: { status: item.status, catatan: item.catatan, inputOleh: user.userId },
            })
          : this.prisma.absensi.create({
              data: {
                tenantId,
                santriId: item.santriId,
                kelasId: dto.kelasId,
                mapelId: dto.mapelId,
                tanggal,
                status: item.status,
                catatan: item.catatan,
                inputOleh: user.userId,
              },
            });
      }),
    );

    return { count: itemMap.size, message: 'Absensi massal disimpan.' };
  }

  // ===== Nilai =====
  async findAllNilai(
    tenantId: string,
    santriId?: string,
    mapelId?: string,
    jenis?: JenisNilai,
    allowedSantriIds?: string[],
  ) {
    const santriFilter = allowedSantriIds
      ? santriId
        ? { santriId }
        : { santriId: { in: allowedSantriIds } }
      : santriId
        ? { santriId }
        : {};
    return this.prisma.nilai.findMany({
      where: {
        tenantId,
        ...santriFilter,
        ...(mapelId ? { mapelId } : {}),
        ...(jenis ? { jenis } : {}),
      },
      include: {
        santri: { select: { id: true, nama: true, nis: true } },
        mapel: { select: { id: true, namaMapel: true } },
      },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createNilai(tenantId: string, dto: CreateNilaiDto, user: RequestUser) {
    await this.assertSantriInTenant(tenantId, dto.santriId);
    return this.prisma.nilai.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        mapelId: dto.mapelId,
        jenis: dto.jenis,
        nilai: dto.nilai,
        keterangan: dto.keterangan,
        tanggal: new Date(dto.tanggal),
        inputOleh: user.userId,
      },
    });
  }

  // ===== Tahfidz =====
  async findAllTahfidz(tenantId: string, santriId?: string, allowedSantriIds?: string[]) {
    const santriFilter = allowedSantriIds
      ? santriId
        ? { santriId }
        : { santriId: { in: allowedSantriIds } }
      : santriId
        ? { santriId }
        : {};
    return this.prisma.capaianTahfidz.findMany({
      where: { tenantId, ...santriFilter },
      include: { santri: { select: { id: true, nama: true, nis: true } } },
      orderBy: { tanggalSetor: 'desc' },
    });
  }

  async createTahfidz(tenantId: string, dto: CreateTahfidzDto, user: RequestUser) {
    await this.assertSantriInTenant(tenantId, dto.santriId);
    return this.prisma.capaianTahfidz.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        juz: dto.juz,
        halaman: dto.halaman,
        catatanUstadz: dto.catatanUstadz,
        tanggalSetor: new Date(dto.tanggalSetor),
        inputOleh: user.userId,
      },
    });
  }

  private async assertSantriInTenant(tenantId: string, santriId: string) {
    const found = await this.assertSantri(tenantId, santriId);
    if (!found) throw new NotFoundException('Santri tidak ditemukan di pondok ini.');
    return found;
  }
}