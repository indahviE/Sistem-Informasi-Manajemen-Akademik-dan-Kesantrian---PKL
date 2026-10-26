import { BadRequestException, ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  BulkAbsensiDto,
  BulkNilaiDto,
  CreateAbsensiDto,
  CreateNilaiDto,
  CreateTahfidzDto,
  QueryAbsensiDto,
} from './dto/akademik.dto';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { juzEndAbs, juzStartAbs, toAbs, validateSetoran } from './quran-meta';
import { JenisNilai, Role } from '@prisma/client';

@Injectable()
export class AkademikService {
  constructor(private prisma: PrismaService) {}

  private assertSantri(tenantId: string, santriId: string) {
    return this.prisma.santri.findFirst({ where: { id: santriId, tenantId } });
  }

  // ===== Absensi =====
  async findAllAbsensi(tenantId: string, query: QueryAbsensiDto, allowedSantriIds?: string[]) {
    // Wali: hanya boleh melihat anaknya sendiri
    const santriFilter = allowedSantriIds
      ? query.santriId
        ? { santriId: query.santriId }
        : { santriId: { in: allowedSantriIds } }
      : query.santriId
        ? { santriId: query.santriId }
        : {};

    const where: any = {
      tenantId,
      ...santriFilter,
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
    // Ustadz hanya boleh mengabsen kelas yang ia menjadi wali kelasnya
    if (user.role === Role.USTADZ) {
      const ustadz = await this.prisma.ustadz.findFirst({
        where: { tenantId, userId: user.userId },
        select: { id: true },
      });
      const mengajar = ustadz
        ? await this.prisma.ustadzMengajar.findMany({
            where: { tenantId, ustadzId: ustadz.id },
            select: { kelasId: true },
          })
        : [];
      const kelas = await this.prisma.kelas.findFirst({
        where: {
          id: dto.kelasId,
          tenantId,
          OR: [
            { waliKelasId: ustadz?.id ?? '__none__' },
            { id: { in: mengajar.map((m) => m.kelasId) } },
          ],
        },
        select: { id: true },
      });
      if (!kelas) {
        throw new ForbiddenException('Ini bukan kelas yang Anda ampu.');
      }
      // Semua santri yang dikirim harus benar-benar anggota kelas tersebut
      const idsKirim = [...new Set(dto.items.map((i) => i.santriId))];
      const anggota = await this.prisma.santri.count({
        where: { tenantId, kelasId: dto.kelasId, id: { in: idsKirim } },
      });
      if (anggota !== idsKirim.length) {
        throw new ForbiddenException('Ada santri yang bukan anggota kelas ini.');
      }
    }

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

  // ===== Detail kelas (daftar santri) =====
  async findKelasDetail(tenantId: string, id: string) {
    const kelas = await this.prisma.kelas.findFirst({
      where: { id, tenantId },
      include: {
        waliKelas: { select: { id: true, nama: true } },
        santris: {
          select: { id: true, nis: true, nama: true, jenisKelamin: true, status: true },
          orderBy: { nama: 'asc' },
        },
        _count: { select: { santris: true } },
      },
    });
    if (!kelas) throw new NotFoundException('Kelas tidak ditemukan.');
    return kelas;
  }

  // ===== Nilai =====
  async findAllNilai(
    tenantId: string,
    santriId?: string,
    mapelId?: string,
    jenis?: JenisNilai,
    allowedSantriIds?: string[],
    tahunAjaranId?: string,
  ) {
    // Wali: hanya boleh melihat anaknya sendiri
    const santriFilter = allowedSantriIds
      ? santriId
        ? { santriId }
        : { santriId: { in: allowedSantriIds } }
      : santriId
        ? { santriId }
        : {};

    // Default: tahun ajaran aktif. Kirim "semua" untuk melihat seluruh tahun.
    let taFilter = {};
    if (tahunAjaranId !== 'semua') {
      const taId = tahunAjaranId ?? (await this.tahunAjaranAktifId(tenantId));
      if (taId) taFilter = { tahunAjaranId: taId };
    }

    return this.prisma.nilai.findMany({
      where: {
        tenantId,
        ...santriFilter,
        ...taFilter,
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

  /** Skill hanya berlaku untuk BAHASA_ARAB; selain itu selalu "" supaya unique tetap konsisten. */
  private normalSkill(jenis: JenisNilai, skill?: string): string {
    return jenis === 'BAHASA_ARAB' ? (skill?.trim().toLowerCase() ?? '') : '';
  }

  /** ID tahun ajaran yang sedang aktif di pondok ini (null kalau belum ada). */
  private async tahunAjaranAktifId(tenantId: string): Promise<string | null> {
    const ta = await this.prisma.tahunAjaran.findFirst({
      where: { tenantId, aktif: true },
      select: { id: true },
      orderBy: { nama: 'desc' },
    });
    return ta?.id ?? null;
  }

  // DIUBAH: dari create() menjadi upsert(), supaya nilai yang sama di hari yang
  // sama tidak lagi error karena unique constraint (santri + mapel + jenis + tanggal).
  async createNilai(tenantId: string, dto: CreateNilaiDto, user: RequestUser) {
    await this.assertSantriInTenant(tenantId, dto.santriId);
    await this.assertUstadzMengajar(tenantId, user, dto.mapelId, [dto.santriId]);
    const tanggal = new Date(String(dto.tanggal).slice(0, 10)); // tanggal saja, tanpa jam
    const skill = this.normalSkill(dto.jenis, dto.skill);
    const tahunAjaranId = await this.tahunAjaranAktifId(tenantId);
    return this.prisma.nilai.upsert({
      where: {
        santriId_mapelId_jenis_skill_tanggal: {
          santriId: dto.santriId,
          mapelId: dto.mapelId,
          jenis: dto.jenis,
          skill,
          tanggal,
        },
      },
      create: {
        tenantId,
        santriId: dto.santriId,
        mapelId: dto.mapelId,
        tahunAjaranId,
        jenis: dto.jenis,
        skill,
        nilai: dto.nilai,
        keterangan: dto.keterangan,
        tanggal,
        inputOleh: user.userId,
      },
      update: {
        nilai: dto.nilai,
        keterangan: dto.keterangan,
        inputOleh: user.userId,
        tahunAjaranId,
      },
    });
  }

  // Ustadz hanya boleh mengisi nilai mapel + kelas yang ia ajar (tabel ustadz_mengajar).
  // Admin bebas. Kelas ditentukan dari kelas masing-masing santri.
  private async assertUstadzMengajar(
    tenantId: string,
    user: RequestUser,
    mapelId: string,
    santriIds: string[],
  ) {
    if (user.role !== Role.USTADZ) return;
    const ustadz = await this.prisma.ustadz.findFirst({
      where: { tenantId, userId: user.userId },
      select: { id: true },
    });
    const tugas = ustadz
      ? await this.prisma.ustadzMengajar.findMany({
          where: { tenantId, ustadzId: ustadz.id, mapelId },
          select: { kelasId: true },
        })
      : [];
    const kelasIds = [...new Set(tugas.map((t) => t.kelasId))];
    const ids = [...new Set(santriIds)];
    const sah = await this.prisma.santri.count({
      where: { tenantId, id: { in: ids }, kelasId: { in: kelasIds } },
    });
    if (sah !== ids.length) {
      throw new ForbiddenException('Anda tidak mengajar mapel ini di kelas santri tersebut.');
    }
  }

  // BARU: simpan banyak nilai sekaligus. Satu transaksi, upsert per santri.
  // Tanggal selalu hari ini menurut WIB (ditentukan server, bukan dari HP).
  async bulkNilai(tenantId: string, dto: BulkNilaiDto, user: RequestUser) {
    const mapel = await this.prisma.mataPelajaran.findFirst({
      where: { id: dto.mapelId, tenantId },
      select: { id: true },
    });
    if (!mapel) throw new NotFoundException('Mata pelajaran tidak ditemukan di pondok ini.');

    // 1 santri = 1 entri (kalau dobel, yang terakhir dipakai)
    const itemMap = new Map<string, BulkNilaiDto['items'][number]>();
    for (const i of dto.items) itemMap.set(i.santriId, i);
    const ids = [...itemMap.keys()];

    const valid = await this.prisma.santri.count({ where: { tenantId, id: { in: ids } } });
    if (valid !== ids.length) {
      throw new NotFoundException('Ada santri yang tidak ditemukan di pondok ini.');
    }
    await this.assertUstadzMengajar(tenantId, user, dto.mapelId, ids);

    const tanggal = this.tanggalHariIniWib();
    const skill = this.normalSkill(dto.jenis, dto.skill);
    const tahunAjaranId = await this.tahunAjaranAktifId(tenantId);

    // Satu transaksi: semua tersimpan, atau tidak sama sekali
    await this.prisma.$transaction(
      [...itemMap.values()].map((item) => {
        const keterangan = item.catatan?.trim() || null;
        return this.prisma.nilai.upsert({
          where: {
            santriId_mapelId_jenis_skill_tanggal: {
              santriId: item.santriId,
              mapelId: dto.mapelId,
              jenis: dto.jenis,
              skill,
              tanggal,
            },
          },
          create: {
            tenantId,
            santriId: item.santriId,
            mapelId: dto.mapelId,
            tahunAjaranId,
            jenis: dto.jenis,
            skill,
            nilai: item.nilai,
            keterangan,
            tanggal,
            inputOleh: user.userId,
          },
          update: { nilai: item.nilai, keterangan, inputOleh: user.userId, tahunAjaranId },
        });
      }),
    );

    return { count: itemMap.size, message: 'Nilai disimpan.' };
  }

  // ===== Tahfidz =====

  /**
   * ID santri binaan seorang ustadz = santri di kelas yang dia jadi wali kelasnya
   * ATAU kelas yang dia ampu (tabel ustadz_mengajar). Harus sama dengan
   * santriIdsBinaan di santri.service.ts.
   */
  private async santriIdsBinaan(tenantId: string, user: RequestUser): Promise<string[]> {
    const ustadz = await this.prisma.ustadz.findFirst({
      where: { tenantId, userId: user.userId },
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

  /** Tanggal hari ini menurut WIB, disimpan sebagai tengah malam UTC. */
  private tanggalHariIniWib(): Date {
    const wib = new Date(Date.now() + 7 * 60 * 60 * 1000);
    return new Date(`${wib.toISOString().slice(0, 10)}T00:00:00.000Z`);
  }

  async findAllTahfidz(
    tenantId: string,
    santriId?: string,
    allowedSantriIds?: string[],
    user?: RequestUser,
  ) {
    let allowed = allowedSantriIds;

    // Ustadz hanya boleh melihat santri binaannya
    if (user?.role === Role.USTADZ) {
      allowed = await this.santriIdsBinaan(tenantId, user);
      if (santriId && !allowed.includes(santriId)) {
        throw new ForbiddenException('Santri ini bukan binaan Anda.');
      }
    }

    const santriFilter = allowed
      ? santriId
        ? { santriId }
        : { santriId: { in: allowed } }
      : santriId
        ? { santriId }
        : {};

    return this.prisma.capaianTahfidz.findMany({
      where: { tenantId, ...santriFilter },
      include: { santri: { select: { id: true, nama: true, nis: true } } },
      orderBy: [{ tanggalSetor: 'desc' }, { createdAt: 'desc' }],
    });
  }

  async createTahfidz(tenantId: string, dto: CreateTahfidzDto, user: RequestUser) {
    await this.assertSantriInTenant(tenantId, dto.santriId);

    if (user.role === Role.USTADZ) {
      const binaan = await this.santriIdsBinaan(tenantId, user);
      if (!binaan.includes(dto.santriId)) {
        throw new ForbiddenException('Santri ini bukan binaan Anda.');
      }
    }

    const adaAyat =
      dto.suratMulai != null || dto.ayatMulai != null ||
      dto.suratSelesai != null || dto.ayatSelesai != null;

    // ---- Jalur baru: surat & ayat ----
    if (adaAyat) {
      const { suratMulai, ayatMulai, suratSelesai, ayatSelesai } = dto;
      if (suratMulai == null || ayatMulai == null || suratSelesai == null || ayatSelesai == null) {
        throw new BadRequestException('Surat dan ayat mulai/selesai harus diisi lengkap.');
      }
      const err = validateSetoran(dto.juz, suratMulai, ayatMulai, suratSelesai, ayatSelesai);
      if (err) throw new BadRequestException(err);

      const ayatAbsMulai = toAbs(suratMulai, ayatMulai);
      const ayatAbsSelesai = toAbs(suratSelesai, ayatSelesai);

      // Estimasi halaman 1..20 di dalam juz. Hanya supaya kolom lama & layar lama
      // tetap jalan; progres dan khatam yang baru memakai ayatAbs.
      const awalJuz = juzStartAbs(dto.juz);
      const ukuranJuz = juzEndAbs(dto.juz) - awalJuz + 1;
      const keHalaman = (abs: number) =>
        Math.min(20, Math.max(1, Math.ceil(((abs - awalJuz + 1) * 20) / ukuranJuz)));

      return this.prisma.capaianTahfidz.create({
        data: {
          tenantId,
          santriId: dto.santriId,
          juz: dto.juz,
          halaman: keHalaman(ayatAbsSelesai),
          halamanMulai: keHalaman(ayatAbsMulai),
          halamanSelesai: keHalaman(ayatAbsSelesai),
          suratMulai,
          ayatMulai,
          suratSelesai,
          ayatSelesai,
          ayatAbsMulai,
          ayatAbsSelesai,
          jenis: dto.jenis ?? 'ZIYADAH',
          kualitas: dto.kualitas,
          catatanUstadz: dto.catatanUstadz,
          tanggalSetor: this.tanggalHariIniWib(),
          inputOleh: user.userId,
        },
      });
    }

    // ---- Jalur lama: halaman (klien lama yang belum diperbarui) ----
    const mulai = dto.halamanMulai ?? dto.halamanSelesai ?? dto.halaman;
    const selesai = dto.halamanSelesai ?? dto.halamanMulai ?? dto.halaman;
    if (mulai == null || selesai == null) {
      throw new BadRequestException('Halaman atau surat/ayat wajib diisi.');
    }
    if (mulai > selesai) {
      throw new BadRequestException('Halaman mulai tidak boleh lebih besar dari halaman selesai.');
    }

    return this.prisma.capaianTahfidz.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        juz: dto.juz,
        halaman: selesai,
        halamanMulai: mulai,
        halamanSelesai: selesai,
        jenis: dto.jenis ?? 'ZIYADAH',
        kualitas: dto.kualitas,
        catatanUstadz: dto.catatanUstadz,
        tanggalSetor: this.tanggalHariIniWib(),
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