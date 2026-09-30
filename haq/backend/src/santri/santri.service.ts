import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateSantriDto, QuerySantriDto, UpdateSantriDto } from './dto/santri.dto';

@Injectable()
export class SantriService {
  constructor(private prisma: PrismaService) {}

  /** ID santri binaan seorang ustadz = santri di kelas yang dia jadi wali kelasnya. */
  private async santriIdsBinaan(tenantId: string, userId: string): Promise<string[]> {
    const ustadz = await this.prisma.ustadz.findFirst({
      where: { tenantId, userId },
      select: { id: true },
    });
    if (!ustadz) return [];
    const santris = await this.prisma.santri.findMany({
      where: { tenantId, kelas: { waliKelasId: ustadz.id } },
      select: { id: true },
    });
    return santris.map((s) => s.id);
  }

  async findAll(tenantId: string, query: QuerySantriDto, user: RequestUser) {
    const { kelasId, search, binaan, page = 1, perPage = 20 } = query;
    const where: any = {
      tenantId,
      ...(kelasId ? { kelasId } : {}),
      ...(search
        ? { OR: [{ nama: { contains: search } }, { nis: { contains: search } }] }
        : {}),
    };

    // Filter khusus USTADZ: hanya santri di kelas yang ia ampu
    if (binaan === 'true' && user.role === Role.USTADZ) {
      const ids = await this.santriIdsBinaan(tenantId, user.userId);
      where.id = { in: ids.length ? ids : ['__none__'] };
    }
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

  /** NIS otomatis: 11 digit, mulai 01234567890, naik 1 dari NIS terbesar di tenant. */
  private async buatNisBerikutnya(tenantId: string): Promise<string> {
    const AWAL = 1234567890n; // "01234567890"
    const LEBAR = 11;

    const rows = await this.prisma.santri.findMany({
      where: { tenantId },
      select: { nis: true },
    });

    let maks: bigint | null = null;
    for (const r of rows) {
      if (!/^\d{11}$/.test(r.nis)) continue; // abaikan NIS berformat lain
      const n = BigInt(r.nis);
      if (maks === null || n > maks) maks = n;
    }

    const berikut = maks === null ? AWAL : maks + 1n;
    return berikut.toString().padStart(LEBAR, '0');
  }

  async create(tenantId: string, dto: CreateSantriDto) {
    const manual = dto.nis?.trim();

    // Coba ulang kalau dua admin menyimpan bersamaan dan NIS otomatisnya bentrok.
    for (let percobaan = 0; percobaan < 5; percobaan++) {
      const nis = manual || (await this.buatNisBerikutnya(tenantId));
      try {
        return await this.prisma.santri.create({
          data: {
            tenantId,
            nis,
            nama: dto.nama,
            jenisKelamin: dto.jenisKelamin,
            tanggalLahir: dto.tanggalLahir ? new Date(dto.tanggalLahir) : undefined,
            kelasId: dto.kelasId,
            asrama: dto.asrama,
            waliId: dto.waliId,
            tahunMasuk: dto.tahunMasuk,
          },
        });
      } catch (e: any) {
        if (e?.code === 'P2002') {
          if (manual) throw new ConflictException('NIS sudah dipakai santri lain.');
          continue; // NIS otomatis bentrok, hitung ulang
        }
        throw e;
      }
    }
    throw new ConflictException('Gagal membuat NIS otomatis, coba simpan lagi.');
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