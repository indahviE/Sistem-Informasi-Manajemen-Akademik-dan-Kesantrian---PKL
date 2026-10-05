import {
  BadRequestException,
  ConflictException,
  ForbiddenException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { SimpanRemedialDto } from './dto/simpan-remedial.dto';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import {
  BukaKunciDto,
  CreateKelulusanDto,
  CreateRemedialDto,
  CreateUjianDto,
  GenerateRaporDto,
  InputNilaiUjianDto,
  UpdateKelulusanDto,
  UpdateRemedialDto,
  UpdateUjianDto,
} from './dto/penilaian.dto';
import {
  AuditKategori,
  AuditTingkat,
  PredikatKelulusan,
  Prisma,
  Role,
  SantriStatus,
  StatusKehadiranUjian,
  StatusRapor,
  Ujian,
} from '@prisma/client';

type Actor = { id: string | null; nama: string | null; role: string | null };

@Injectable()
export class PenilaianService {
  constructor(private prisma: PrismaService) {}

  // ===== HELPER =====
  private async assertSantri(tenantId: string, santriId: string) {
    const found = await this.prisma.santri.findFirst({ where: { id: santriId, tenantId } });
    if (!found) throw new NotFoundException('Santri tidak ditemukan di pondok ini.');
    return found;
  }

  // Dibuat toleran terhadap bentuk RequestUser (id / userId / sub). Rapikan setelah bentuk aslinya dipastikan.
  private actor(user?: RequestUser): Actor {
    const u = (user ?? {}) as any;
    return {
      id: u.id ?? u.userId ?? u.sub ?? null,
      nama: u.nama ?? u.name ?? null,
      role: u.role ?? null,
    };
  }

  private async getUjianRingkas(tenantId: string, id: string): Promise<Ujian> {
    const ujian = await this.prisma.ujian.findFirst({ where: { id, tenantId } });
    if (!ujian) throw new NotFoundException('Ujian tidak ditemukan.');
    return ujian;
  }

  // Ustadz hanya boleh mengelola ujian yang ia buat. Admin/Pimpinan bebas. Ujian lama (dibuatOleh kosong) terbuka.
  private assertBolehKelola(ujian: Ujian, actor: Actor) {
    if (actor.role === Role.USTADZ && ujian.dibuatOleh && ujian.dibuatOleh !== actor.id) {
      throw new ForbiddenException('Ujian ini dibuat oleh pengguna lain. Anda tidak bisa mengubah nilainya.');
    }
  }

  private assertTerbuka(ujian: Ujian) {
    if (ujian.dikunciPada) {
      throw new ConflictException(
        'Nilai ujian ini sudah dikunci. Buka kunci terlebih dahulu (alasan wajib diisi) jika perlu perbaikan.',
      );
    }
  }

  private async assertUjianTerbukaById(tenantId: string, ujianId?: string | null) {
    if (!ujianId) return;
    const ujian = await this.prisma.ujian.findFirst({ where: { id: ujianId, tenantId } });
    if (ujian) this.assertTerbuka(ujian);
  }

  private audit(
    tenantId: string,
    actor: Actor,
    action: string,
    ujianId: string,
    judul: string,
    deskripsi: string,
    data?: Record<string, unknown>,
    tingkat: AuditTingkat = AuditTingkat.INFO,
  ): Prisma.AuditLogUncheckedCreateInput {
    return {
      tenantId,
      userId: actor.id,
      userNama: actor.nama,
      userRole: actor.role,
      action,
      entity: 'Ujian',
      entityId: ujianId,
      kategori: AuditKategori.DATA,
      tingkat,
      judul,
      deskripsi,
      data: data as Prisma.InputJsonValue | undefined,
    };
  }

  private normalisasiNilai(item: InputNilaiUjianDto): { status: StatusKehadiranUjian; nilai: number | null } {
    const status = item.status ?? StatusKehadiranUjian.HADIR;
    if (status === StatusKehadiranUjian.HADIR) {
      if (item.nilai === undefined || item.nilai === null) {
        throw new BadRequestException('Nilai wajib diisi untuk santri yang hadir.');
      }
      return { status, nilai: item.nilai };
    }
    // SAKIT / IZIN / ALPA: tidak ada nilai (jalur ujian susulan, bukan "di bawah KKM")
    return { status, nilai: null };
  }

  // ===== UJIAN =====
  async findAllUjian(
  tenantId: string,
  kelasId?: string,
  user?: RequestUser,
  hanyaSaya = false,
) {
  const actor = this.actor(user);

  const list = await this.prisma.ujian.findMany({
    where: {
      tenantId,
      ...(kelasId ? { kelasId } : {}),
      // filter per ustadz: hanya aktif kalau dashboard minta ?saya=true
      ...(hanyaSaya && actor.id
        ? { OR: [{ dibuatOleh: actor.id }, { dibuatOleh: null }] }
        : {}),
    },
    include: {
      mapel: { select: { id: true, namaMapel: true } },
      kelas: { select: { id: true, namaKelas: true } },
      _count: { select: { nilais: true } },
    },
    orderBy: { createdAt: 'desc' },
  });

  // jumlah santri aktif per kelas
  const kelasIds = [...new Set(list.map((u) => u.kelasId).filter(Boolean))] as string[];
  const grup = kelasIds.length
    ? await this.prisma.santri.groupBy({
        by: ['kelasId'],
        where: { tenantId, status: SantriStatus.AKTIF, kelasId: { in: kelasIds } },
        _count: { _all: true },
      })
    : [];
  const perKelas = new Map(grup.map((g) => [g.kelasId, g._count._all]));

  // ujian "Semua kelas" (kelasId kosong) = seluruh santri aktif di pondok
  const totalSemua = list.some((u) => !u.kelasId)
    ? await this.prisma.santri.count({ where: { tenantId, status: SantriStatus.AKTIF } })
    : 0;

  return list.map((u) => ({
    ...u,
    terkunci: !!u.dikunciPada,
    totalSantri: u.kelasId ? perKelas.get(u.kelasId) ?? 0 : totalSemua,
  }));
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
    return { ...ujian, terkunci: !!ujian.dikunciPada };
  }

  async createUjian(tenantId: string, dto: CreateUjianDto, user?: RequestUser) {
    const actor = this.actor(user);
    return this.prisma.ujian.create({
      data: {
        tenantId,
        nama: dto.nama,
        jenis: dto.jenis ?? 'ULANGAN',
        mapelId: dto.mapelId ?? null,
        kelasId: dto.kelasId ?? null,
        tanggal: dto.tanggal ? new Date(dto.tanggal) : null,
        durasiMenit: dto.durasiMenit ?? null,
        kkm: dto.kkm ?? 75,
        dibuatOleh: actor.id,
      },
      include: {
        mapel: { select: { id: true, namaMapel: true } },
        kelas: { select: { id: true, namaKelas: true } },
      },
    });
  }

  async updateUjian(tenantId: string, id: string, dto: UpdateUjianDto, user?: RequestUser) {
    const actor = this.actor(user);
    const found = await this.getUjianRingkas(tenantId, id);
    this.assertBolehKelola(found, actor);
    this.assertTerbuka(found);
    return this.prisma.ujian.update({
      where: { id },
      data: {
        nama: dto.nama,
        jenis: dto.jenis,
        mapelId: dto.mapelId ?? undefined,
        kelasId: dto.kelasId ?? undefined,
        tanggal: dto.tanggal ? new Date(dto.tanggal) : undefined,
        durasiMenit: dto.durasiMenit,
        kkm: dto.kkm,
      },
    });
  }

  async removeUjian(tenantId: string, id: string, user?: RequestUser) {
    const actor = this.actor(user);
    const found = await this.getUjianRingkas(tenantId, id);
    this.assertBolehKelola(found, actor);
    this.assertTerbuka(found);
    await this.prisma.nilaiUjian.deleteMany({ where: { ujianId: id } });
    await this.prisma.remedial.updateMany({ where: { ujianId: id }, data: { ujianId: null } });
    return this.prisma.ujian.delete({ where: { id } });
  }

  // ===== KUNCI & BUKA KUNCI =====
  async kunciUjian(tenantId: string, ujianId: string, user?: RequestUser) {
    const actor = this.actor(user);
    const ujian = await this.getUjianRingkas(tenantId, ujianId);
    this.assertBolehKelola(ujian, actor);
    if (ujian.dikunciPada) throw new ConflictException('Nilai ujian ini sudah dikunci.');

    const nilais = await this.prisma.nilaiUjian.findMany({ where: { ujianId, tenantId } });
    if (nilais.length === 0) throw new BadRequestException('Belum ada nilai yang diinput untuk ujian ini.');

    // Semua santri aktif di kelas harus punya nilai atau keterangan kehadiran (sakit/izin/alpa)
        // Semua santri aktif yang menjadi peserta (satu kelas, atau seluruh pondok bila "Semua kelas")
    // harus punya nilai atau keterangan kehadiran (sakit/izin/alpa)
    const aktif = await this.prisma.santri.findMany({
      where: {
        tenantId,
        status: SantriStatus.AKTIF,
        ...(ujian.kelasId ? { kelasId: ujian.kelasId } : {}),
      },
      select: { id: true, nama: true },
    });
    const sudah = new Set(nilais.map((n) => n.santriId));
    const kosong = aktif.filter((s) => !sudah.has(s.id));
    if (kosong.length > 0) {
      const contoh = kosong.slice(0, 5).map((s) => s.nama).join(', ');
      throw new BadRequestException(
        `${kosong.length} santri belum punya nilai atau keterangan kehadiran: ${contoh}${kosong.length > 5 ? ', dst.' : ''}.`,
      );
    }

    // Remedial yang sudah dijadwalkan harus sudah diisi nilai perbaikannya
    const remedials = await this.prisma.remedial.findMany({ where: { tenantId, ujianId } });
    const belumSelesai = remedials.filter((r) => r.nilaiRemedial === null).length;
    if (belumSelesai > 0) {
      throw new BadRequestException(
        `${belumSelesai} remedial belum diisi nilai perbaikannya. Isi nilainya, atau hapus remedial yang tidak jadi dilaksanakan.`,
      );
    }

    const kkm = ujian.kkm ?? 75;
    const hadir = nilais.filter((n) => n.status === StatusKehadiranUjian.HADIR && n.nilai !== null);
    const dibawahKkm = hadir.filter((n) => (n.nilai as number) < kkm);
    const idRemedial = new Set(remedials.map((r) => r.santriId));
    const ringkasan = {
      kkm,
      totalPeserta: nilais.length,
      tuntasLangsung: hadir.length - dibawahKkm.length,
      dibawahKkm: dibawahKkm.length,
      ikutRemedial: dibawahKkm.filter((n) => idRemedial.has(n.santriId)).length,
      tanpaRemedial: dibawahKkm.filter((n) => !idRemedial.has(n.santriId)).length,
      perluSusulan: nilais.length - hadir.length,
    };

    const sekarang = new Date();
    const [updated] = await this.prisma.$transaction([
      this.prisma.ujian.update({
        where: { id: ujianId },
        data: { dikunciPada: sekarang, dikunciOleh: actor.id },
      }),
      this.prisma.auditLog.create({
        data: this.audit(
          tenantId,
          actor,
          'UJIAN_KUNCI',
          ujianId,
          'Nilai ujian dikunci',
          `Nilai ujian "${ujian.nama}" dikunci.`,
          ringkasan,
        ),
      }),
    ]);
    return { ...updated, terkunci: true, ringkasan };
  }

  async bukaKunciUjian(tenantId: string, ujianId: string, dto: BukaKunciDto, user?: RequestUser) {
    const actor = this.actor(user);
    const ujian = await this.getUjianRingkas(tenantId, ujianId);
    this.assertBolehKelola(ujian, actor);
    if (!ujian.dikunciPada) throw new ConflictException('Nilai ujian ini belum dikunci.');

    const alasan = dto.alasan.trim();
    if (alasan.length < 10) throw new BadRequestException('Alasan buka kunci minimal 10 karakter.');

    // Jika nilai sudah masuk rapor yang terbit, hanya Admin/Pimpinan yang boleh membuka kunci
    if (ujian.periode) {
      const peserta = await this.prisma.nilaiUjian.findMany({
        where: { ujianId, tenantId },
        select: { santriId: true },
      });
      const raporTerbit = await this.prisma.rapor.count({
        where: {
          tenantId,
          periode: ujian.periode,
          status: StatusRapor.TERBIT,
          santriId: { in: peserta.map((p) => p.santriId) },
        },
      });
      if (raporTerbit > 0 && actor.role !== Role.ADMIN && actor.role !== Role.PIMPINAN) {
        throw new ForbiddenException('Nilai sudah masuk rapor yang terbit. Hanya Admin atau Pimpinan yang bisa membuka kunci.');
      }
    }

    const [updated] = await this.prisma.$transaction([
      this.prisma.ujian.update({
        where: { id: ujianId },
        data: { dikunciPada: null, dikunciOleh: null },
      }),
      this.prisma.auditLog.create({
        data: this.audit(
          tenantId,
          actor,
          'UJIAN_BUKA_KUNCI',
          ujianId,
          'Kunci nilai ujian dibuka',
          `Kunci nilai ujian "${ujian.nama}" dibuka. Alasan: ${alasan}`,
          {
            alasan,
            dikunciPadaSebelumnya: ujian.dikunciPada.toISOString(),
            dikunciOlehSebelumnya: ujian.dikunciOleh,
          },
          AuditTingkat.WARNING,
        ),
      }),
    ]);
    return { ...updated, terkunci: false };
  }

  // ===== NILAI UJIAN =====
  async listNilaiUjian(tenantId: string, ujianId: string) {
    await this.getUjianRingkas(tenantId, ujianId);
    return this.prisma.nilaiUjian.findMany({
      where: { ujianId, tenantId },
      include: { santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } } },
      orderBy: { santri: { nama: 'asc' } },
    });
  }

  private async simpanNilai(tenantId: string, ujian: Ujian, dto: InputNilaiUjianDto, actor: Actor) {
    const { status, nilai } = this.normalisasiNilai(dto);
    const ujianId = ujian.id;
    const lama = await this.prisma.nilaiUjian.findUnique({
      where: { ujianId_santriId: { ujianId, santriId: dto.santriId } },
    });
    const berubah = !!lama && (lama.nilai !== nilai || lama.status !== status);

    return this.prisma.$transaction(async (tx) => {
      const hasil = await tx.nilaiUjian.upsert({
        where: { ujianId_santriId: { ujianId, santriId: dto.santriId } },
        create: {
          tenantId,
          ujianId,
          santriId: dto.santriId,
          nilai,
          status,
          catatan: dto.catatan,
          inputOleh: actor.id,
        },
        update: { nilai, status, catatan: dto.catatan, inputOleh: actor.id },
        include: { santri: { select: { id: true, nama: true, nis: true } } },
      });

      if (lama && berubah) {
        await tx.auditLog.create({
          data: this.audit(
            tenantId,
            actor,
            'NILAI_UJIAN_UBAH',
            ujianId,
            'Nilai ujian diubah',
            `Nilai ${hasil.santri.nama} pada ujian "${ujian.nama}" diubah.`,
            {
              santriId: dto.santriId,
              lama: { nilai: lama.nilai, status: lama.status },
              baru: { nilai, status },
            },
          ),
        });
        // Jaga agar nilai awal di remedial yang belum selesai tetap sinkron dengan nilai terbaru
        await tx.remedial.updateMany({
          where: { ujianId, santriId: dto.santriId, nilaiRemedial: null },
          data: { nilaiAwal: nilai },
        });
      }
      return hasil;
    });
  }

  async inputNilaiUjian(tenantId: string, ujianId: string, dto: InputNilaiUjianDto, user?: RequestUser) {
    const actor = this.actor(user);
    const ujian = await this.getUjianRingkas(tenantId, ujianId);
    this.assertBolehKelola(ujian, actor);
    this.assertTerbuka(ujian);
    await this.assertSantri(tenantId, dto.santriId);
    return this.simpanNilai(tenantId, ujian, dto, actor);
  }

  async inputNilaiUjianBulk(tenantId: string, ujianId: string, items: InputNilaiUjianDto[], user?: RequestUser) {
    const actor = this.actor(user);
    const ujian = await this.getUjianRingkas(tenantId, ujianId);
    this.assertBolehKelola(ujian, actor);
    this.assertTerbuka(ujian);

    // Validasi semua item dulu supaya tidak ada yang tersimpan separuh jalan
    items.forEach((item, i) => {
      try {
        this.normalisasiNilai(item);
      } catch (e) {
        throw new BadRequestException(`Baris ${i + 1}: ${(e as Error).message}`);
      }
    });
    const ids = [...new Set(items.map((i) => i.santriId))];
    const ditemukan = await this.prisma.santri.count({ where: { tenantId, id: { in: ids } } });
    if (ditemukan !== ids.length) throw new NotFoundException('Ada santri yang tidak ditemukan di pondok ini.');

    const hasil = [];
    for (const item of items) {
      hasil.push(await this.simpanNilai(tenantId, ujian, item, actor));
    }
    return hasil;
  }

  async removeNilaiUjian(tenantId: string, ujianId: string, nilaiId: string, user?: RequestUser) {
    const actor = this.actor(user);
    const ujian = await this.getUjianRingkas(tenantId, ujianId);
    this.assertBolehKelola(ujian, actor);
    this.assertTerbuka(ujian);
    const found = await this.prisma.nilaiUjian.findFirst({
      where: { id: nilaiId, ujianId, tenantId },
      include: { santri: { select: { nama: true } } },
    });
    if (!found) throw new NotFoundException('Nilai tidak ditemukan.');

    const [deleted] = await this.prisma.$transaction([
      this.prisma.nilaiUjian.delete({ where: { id: nilaiId } }),
      this.prisma.auditLog.create({
        data: this.audit(
          tenantId,
          actor,
          'NILAI_UJIAN_HAPUS',
          ujianId,
          'Nilai ujian dihapus',
          `Nilai ${found.santri.nama} pada ujian "${ujian.nama}" dihapus.`,
          { santriId: found.santriId, lama: { nilai: found.nilai, status: found.status } },
        ),
      }),
    ]);
    return deleted;
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
      this.assertTerbuka(ujian);
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
    await this.assertUjianTerbukaById(tenantId, found.ujianId);
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
    await this.assertUjianTerbukaById(tenantId, found.ujianId);
    return this.prisma.remedial.delete({ where: { id } });
  }

  async listRemedialUjian(tenantId: string, ujianId: string) {
    return this.prisma.remedial.findMany({
      where: { tenantId, ujianId },
      include: { santri: { select: { id: true, nama: true, nis: true } } },
      orderBy: { createdAt: 'desc' },
    });
  }

  async simpanRemedialUjian(tenantId: string, ujianId: string, dto: SimpanRemedialDto, user?: RequestUser) {
    const actor = this.actor(user);
    const { santriId, keterangan, status, catatan, nilaiRemedial, jadwal, ruang, tenggat } = dto;

    const [ujian, santri] = await Promise.all([
      this.prisma.ujian.findFirst({ where: { id: ujianId, tenantId } }),
      this.prisma.santri.findFirst({ where: { id: santriId, tenantId } }),
    ]);
    if (!ujian) throw new NotFoundException('Ujian tidak ditemukan');
    if (!santri) throw new NotFoundException('Santri tidak ditemukan');
    this.assertBolehKelola(ujian, actor);
    this.assertTerbuka(ujian);

    const KKM = ujian.kkm ?? 75;

    // Remedial hanya untuk santri yang hadir dan nilainya di bawah KKM
    const nilaiUtama = await this.prisma.nilaiUjian.findUnique({
      where: { ujianId_santriId: { ujianId, santriId } },
    });
    if (!nilaiUtama || nilaiUtama.status !== StatusKehadiranUjian.HADIR || nilaiUtama.nilai === null) {
      throw new BadRequestException(
        'Santri ini belum punya nilai ujian. Santri yang sakit/izin/alpa memakai jalur ujian susulan, bukan remedial.',
      );
    }
    if (nilaiUtama.nilai >= KKM) {
      throw new BadRequestException(`Nilai santri (${nilaiUtama.nilai}) sudah mencapai KKM ${KKM}, tidak perlu remedial.`);
    }

    if (nilaiRemedial !== undefined && nilaiRemedial !== null) {
      if (Number(nilaiRemedial) < 0 || Number(nilaiRemedial) > 100) {
        throw new BadRequestException('Nilai perbaikan harus antara 0 sampai 100.');
      }
    }
    if (status === 'TUNTAS' && !(Number(nilaiRemedial) >= KKM)) {
      throw new BadRequestException(`Status Tuntas butuh nilai perbaikan minimal KKM ${KKM}`);
    }

    const data = {
      keterangan: keterangan.trim(),
      status,
      hasil: status,
      catatan,
      nilaiRemedial,
      jadwal: jadwal ? new Date(jadwal) : undefined,
      tenggat: tenggat ? new Date(tenggat) : undefined,
      ruang,
    };

    return this.prisma.remedial.upsert({
      where: { ujianId_santriId: { ujianId, santriId } },
      update: data,
      create: {
        ...data,
        tenantId,
        ujianId,
        santriId,
        mapelId: ujian.mapelId,
        nilaiAwal: nilaiUtama.nilai,
      },
    });
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