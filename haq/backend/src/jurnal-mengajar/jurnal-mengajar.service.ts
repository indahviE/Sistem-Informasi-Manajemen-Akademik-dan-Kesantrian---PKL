import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import {
  CreateJurnalMengajarDto,
  QueryJurnalMengajarDto,
  UpdateJurnalMengajarDto,
} from './dto/jurnal-mengajar.dto';

@Injectable()
export class JurnalMengajarService {
  constructor(private prisma: PrismaService) {}

  private readonly include = {
    kelas: { select: { id: true, namaKelas: true } },
    mapel: { select: { id: true, namaMapel: true } },
  };

  private async assertKelas(tenantId: string, kelasId: string) {
    const kelas = await this.prisma.kelas.findFirst({ where: { id: kelasId, tenantId } });
    if (!kelas) throw new NotFoundException('Kelas tidak ditemukan di pondok ini.');
  }

  private async assertMapel(tenantId: string, mapelId?: string) {
    if (!mapelId) return;
    const mapel = await this.prisma.mataPelajaran.findFirst({ where: { id: mapelId, tenantId } });
    if (!mapel) throw new NotFoundException('Mata pelajaran tidak ditemukan di pondok ini.');
  }

  // Ambil jurnal milik tenant ini; ustadz hanya boleh mengubah/menghapus miliknya, admin bebas.
  private async getEditable(tenantId: string, id: string, user: RequestUser) {
    const jurnal = await this.prisma.jurnalMengajar.findFirst({ where: { id, tenantId } });
    if (!jurnal) throw new NotFoundException('Jurnal tidak ditemukan.');
    if (user.role !== Role.ADMIN && jurnal.inputOleh !== user.userId) {
      throw new ForbiddenException('Anda hanya dapat mengubah jurnal milik sendiri.');
    }
    return jurnal;
  }

  // inputOleh hanya berisi userId (tanpa relasi), jadi nama penulis dilampirkan manual.
  private async attachPenulis<T extends { inputOleh: string }>(tenantId: string, rows: T[]) {
    const ids = [...new Set(rows.map((r) => r.inputOleh))];
    const users = ids.length
      ? await this.prisma.user.findMany({
          where: { id: { in: ids }, tenantId },
          select: { id: true, nama: true },
        })
      : [];
    const map = new Map(users.map((u) => [u.id, u]));
    return rows.map((r) => ({ ...r, penulis: map.get(r.inputOleh) ?? null }));
  }

  async findAll(tenantId: string, query: QueryJurnalMengajarDto) {
    const rows = await this.prisma.jurnalMengajar.findMany({
      where: {
        tenantId,
        ...(query.kelasId ? { kelasId: query.kelasId } : {}),
        ...(query.startDate || query.endDate
          ? {
              tanggal: {
                ...(query.startDate ? { gte: new Date(query.startDate) } : {}),
                ...(query.endDate ? { lte: new Date(query.endDate) } : {}),
              },
            }
          : {}),
      },
      include: this.include,
      orderBy: [{ tanggal: 'desc' }, { createdAt: 'desc' }],
    });
    return this.attachPenulis(tenantId, rows);
  }

  async create(tenantId: string, dto: CreateJurnalMengajarDto, user: RequestUser) {
    await this.assertKelas(tenantId, dto.kelasId);
    await this.assertMapel(tenantId, dto.mapelId);
    const created = await this.prisma.jurnalMengajar.create({
      data: {
        tenantId,
        kelasId: dto.kelasId,
        mapelId: dto.mapelId || null,
        tanggal: new Date(dto.tanggal),
        materi: dto.materi.trim(),
        catatan: dto.catatan?.trim() || null,
        inputOleh: user.userId,
      },
      include: this.include,
    });
    return (await this.attachPenulis(tenantId, [created]))[0];
  }

  async update(tenantId: string, id: string, dto: UpdateJurnalMengajarDto, user: RequestUser) {
    await this.getEditable(tenantId, id, user);
    if (dto.kelasId) await this.assertKelas(tenantId, dto.kelasId);
    if (dto.mapelId) await this.assertMapel(tenantId, dto.mapelId);
    const updated = await this.prisma.jurnalMengajar.update({
      where: { id },
      data: {
        ...(dto.tanggal !== undefined && { tanggal: new Date(dto.tanggal) }),
        ...(dto.kelasId !== undefined && { kelasId: dto.kelasId }),
        ...(dto.mapelId !== undefined && { mapelId: dto.mapelId || null }),
        ...(dto.materi !== undefined && { materi: dto.materi.trim() }),
        ...(dto.catatan !== undefined && { catatan: dto.catatan.trim() || null }),
      },
      include: this.include,
    });
    return (await this.attachPenulis(tenantId, [updated]))[0];
  }

  async remove(tenantId: string, id: string, user: RequestUser) {
    await this.getEditable(tenantId, id, user);
    await this.prisma.jurnalMengajar.delete({ where: { id } });
    return { success: true };
  }
}