import { Injectable } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';

@Injectable()
export class NotifikasiService {
  constructor(private prisma: PrismaService) {}

  async myNotifikasis(userId: string, tenantId: string | undefined) {
    return this.prisma.notifikasi.findMany({
      where: tenantId ? { tenantId, OR: [{ userId }, { userId: null }] } : { userId },
      orderBy: { tanggal: 'desc' },
      take: 100,
    });
  }

  async unreadCount(userId: string, tenantId: string | undefined) {
    return this.prisma.notifikasi.count({
      where: tenantId ? { tenantId, OR: [{ userId }, { userId: null }] } : { userId },
    });
  }

  async markRead(userId: string, id: string) {
    return this.prisma.notifikasi.updateMany({
      where: { id, OR: [{ userId }] },
      data: { statusBaca: true },
    });
  }

  async markAllRead(userId: string, tenantId: string | undefined) {
    return this.prisma.notifikasi.updateMany({
      where: tenantId ? { tenantId, OR: [{ userId }, { userId: null }] } : { userId },
      data: { statusBaca: true },
    });
  }
}