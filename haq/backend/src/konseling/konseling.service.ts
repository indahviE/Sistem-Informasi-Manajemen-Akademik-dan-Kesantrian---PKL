import { ForbiddenException, Injectable, NotFoundException } from '@nestjs/common';
import { Role } from '@prisma/client';
import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKonselingDto, UpdateKonselingDto } from './dto/konseling.dto';

/** Role yang boleh melihat semua catatan, termasuk yang rahasia. */
const SEMUA: Role[] = [Role.ADMIN, Role.PIMPINAN];

@Injectable()
export class KonselingService {
  constructor(private prisma: PrismaService) {}

  private async assertSantri(tenantId: string, santriId: string) {
    const found = await this.prisma.santri.findFirst({ where: { id: santriId, tenantId } });
    if (!found) throw new NotFoundException('Santri tidak ditemukan di pondok ini.');
    return found;
  }

  /**
 * Ustadz (guru) hanya boleh mengonseling santri di kelas yang dia walikan
 * atau dia ampu (ustadz_mengajar). Role lain tidak dibatasi.
 * Aturannya sama dengan SantriService.santriIdsBinaan.
 */
private async assertSantriBoleh(tenantId: string, santriId: string, user: RequestUser) {
  const santri = await this.assertSantri(tenantId, santriId);
  if (user.role !== Role.USTADZ) return santri;

  const ustadz = await this.prisma.ustadz.findFirst({
    where: { tenantId, userId: user.userId },
    select: { id: true },
  });
  const boleh = ustadz
    ? await this.prisma.santri.findFirst({
        where: {
          id: santriId,
          tenantId,
          OR: [
            { kelas: { waliKelasId: ustadz.id } },
            { kelas: { UstadzMengajar: { some: { ustadzId: ustadz.id } } } },
          ],
        },
        select: { id: true },
      })
    : null;

  if (!boleh) throw new ForbiddenException('Santri ini bukan binaan Anda.');
  return santri;
}

  /**
   * Filter visibilitas.
   * Admin/Pimpinan: semua catatan.
   * Role lain: catatan umum + catatan yang dia buat + catatan yang dia jadi konselornya.
   */
  private visibilitas(user: RequestUser) {
    if (SEMUA.includes(user.role)) return {};
    return {
      OR: [
        { privat: false },
        { createdById: user.userId },
        { konselor: { userId: user.userId } },
      ],
    };
  }

  /** Hanya pembuat, konselor, atau Admin yang boleh mengubah/menghapus. */
  private async assertBolehUbah(tenantId: string, id: string, user: RequestUser) {
    const found = await this.prisma.konseling.findFirst({
      where: { id, tenantId },
      include: { konselor: { select: { userId: true } } },
    });
    if (!found) throw new NotFoundException('Catatan konseling tidak ditemukan.');

    const pemilik =
      found.createdById === user.userId || found.konselor?.userId === user.userId;
    if (user.role !== Role.ADMIN && !pemilik) {
      throw new ForbiddenException('Anda tidak berhak mengubah catatan ini.');
    }
    return found;
  }

  async findAllKonseling(tenantId: string, user: RequestUser, santriId?: string) {
    return this.prisma.konseling.findMany({
      where: {
        tenantId,
        ...(santriId ? { santriId } : {}),
        ...this.visibilitas(user),
      },
      include: {
        santri: {
          select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } },
        },
        konselor: { select: { id: true, nama: true } },
        createdBy: { select: { id: true, nama: true } },
      },
      orderBy: { tanggal: 'desc' },
    });
  }

  async createKonseling(tenantId: string, dto: CreateKonselingDto, user: RequestUser) {
    await this.assertSantriBoleh(tenantId, dto.santriId, user);

    let konselorId = dto.konselorId ?? null;
    if (konselorId) {
      const konselor = await this.prisma.ustadz.findFirst({ where: { id: konselorId, tenantId } });
      if (!konselor) throw new NotFoundException('Konselor tidak ditemukan.');
    } else {
      // Ustadz/Musyrif tidak bisa GET /ustadz, jadi konselor = akun yang login.
      const diri = await this.prisma.ustadz.findFirst({ where: { tenantId, userId: user.userId } });
      konselorId = diri?.id ?? null;
    }

    return this.prisma.konseling.create({
      data: {
        tenantId,
        santriId: dto.santriId,
        tanggal: dto.tanggal ? new Date(dto.tanggal) : new Date(),
        konselorId,
        createdById: user.userId,
        topik: dto.topik,
        catatan: dto.catatan,
        tindakLanjut: dto.tindakLanjut ?? null,
        privat: dto.privat ?? true,
      },
      include: {
        santri: { select: { id: true, nama: true, nis: true } },
        konselor: { select: { id: true, nama: true } },
        createdBy: { select: { id: true, nama: true } },
      },
    });
  }

  async updateKonseling(tenantId: string, id: string, dto: UpdateKonselingDto, user: RequestUser) {
    await this.assertBolehUbah(tenantId, id, user);
    return this.prisma.konseling.update({
      where: { id },
      data: {
        tanggal: dto.tanggal ? new Date(dto.tanggal) : undefined,
        konselorId: dto.konselorId ?? undefined,
        topik: dto.topik,
        catatan: dto.catatan,
        tindakLanjut: dto.tindakLanjut,
        privat: dto.privat,
      },
    });
  }

  async removeKonseling(tenantId: string, id: string, user: RequestUser) {
    await this.assertBolehUbah(tenantId, id, user);
    return this.prisma.konseling.delete({ where: { id } });
  }
}