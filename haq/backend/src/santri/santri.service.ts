import { ConflictException, Injectable, NotFoundException } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateSantriDto, QuerySantriDto, UpdateSantriDto } from './dto/santri.dto';

@Injectable()
export class SantriService {
  constructor(private prisma: PrismaService) {}

  /**
   * ID santri binaan seorang ustadz = santri di kelas yang dia jadi wali kelasnya
   * ATAU kelas yang dia ampu (tabel ustadz_mengajar). Harus sama dengan
   * santriIdsBinaan di akademik.service.ts.
   */
  private async santriIdsBinaan(tenantId: string, userId: string): Promise<string[]> {
    const ustadz = await this.prisma.ustadz.findFirst({
      where: { tenantId, userId },
      select: { id: true },
    });
    if (!ustadz) return [];
    const mengajar = await this.prisma.ustadzMengajar.findMany({
      where: { tenantId, ustadzId: ustadz.id },
      select: { kelasId: true },
    });
    const kelasIdsDiampu = [...new Set(mengajar.map((m) => m.kelasId))];
    const santris = await this.prisma.santri.findMany({
      where: {
        tenantId,
        OR: [
          { kelas: { waliKelasId: ustadz.id } },
          { kelasId: { in: kelasIdsDiampu } },
        ],
      },
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

  async findOne(tenantId: string, id: string, user?: RequestUser) {
    // Wali hanya boleh melihat anaknya sendiri.
    let waliId: string | undefined;
    if (user?.role === Role.WALI_SANTRI) {
      const wali = await this.prisma.waliSantri.findFirst({
        where: { tenantId, userId: user.userId },
        select: { id: true },
      });
      // Pesan sengaja sama dengan "tidak ditemukan" supaya tidak membocorkan
      // apakah santri dengan ID itu ada.
      if (!wali) throw new NotFoundException('Santri tidak ditemukan.');
      waliId = wali.id;
    }

    const santri = await this.prisma.santri.findFirst({
      where: { id, tenantId, ...(waliId ? { waliId } : {}) },
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

  /** NIS otomatis: tahun masuk (4 digit) + nomor urut 4 digit per tahun, mis. 20260001. */
  private async buatNisBerikutnya(tenantId: string, tahunMasuk: number): Promise<string> {
    const prefix = String(tahunMasuk);
    const pola = new RegExp(`^${prefix}\\d{4}$`);

    const rows = await this.prisma.santri.findMany({
      where: { tenantId, nis: { startsWith: prefix } },
      select: { nis: true },
    });

    let maks = 0;
    for (const r of rows) {
      if (!pola.test(r.nis)) continue; // abaikan NIS berformat lain
      const n = parseInt(r.nis.slice(prefix.length), 10);
      if (n > maks) maks = n;
    }

    return prefix + String(maks + 1).padStart(4, '0');
  }

  async create(tenantId: string, dto: CreateSantriDto) {
    const manual = dto.nis?.trim();

    // Coba ulang kalau dua admin menyimpan bersamaan dan NIS otomatisnya bentrok.
    for (let percobaan = 0; percobaan < 5; percobaan++) {
      const nis =
        manual ||
        (await this.buatNisBerikutnya(tenantId, dto.tahunMasuk ?? new Date().getFullYear()));
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
            tahunMasuk: dto.tahunMasuk ?? new Date().getFullYear(),
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