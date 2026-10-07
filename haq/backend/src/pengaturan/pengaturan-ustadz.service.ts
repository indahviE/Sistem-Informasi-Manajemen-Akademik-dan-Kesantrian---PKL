import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { UpdateNotifikasiUstadzDto } from './pengaturan-ustadz.dto';

const NOTIF_KEYS = [
  'pengingatAbsensi',
  'pengingatNilai',
  'jadwalMengajar',
  'pengumumanPondok',
] as const;

@Injectable()
export class PengaturanUstadzService {
  constructor(private prisma: PrismaService) {}

  private notifDari(setting: any): Record<string, boolean> {
    const out: Record<string, boolean> = {};
    for (const k of NOTIF_KEYS) out[k] = setting?.[k] ?? true;
    return out;
  }

  async getUstadz(userId: string, tenantId: string) {
    const [profil, tenant, setting] = await Promise.all([
      this.prisma.user.findUnique({
        where: { id: userId },
        select: { nama: true, email: true, noHp: true, role: true },
      }),
      this.prisma.tenant.findUnique({
        where: { id: tenantId },
        select: { namaPondok: true },
      }),
      this.prisma.userNotifSetting.findUnique({ where: { userId } }),
    ]);

    if (!profil) throw new NotFoundException('Pengguna tidak ditemukan');

    return { profil, tenant, notifikasi: this.notifDari(setting) };
  }

  async updateNotifikasi(userId: string, dto: UpdateNotifikasiUstadzDto) {
    const data: Record<string, boolean> = {};
    for (const k of NOTIF_KEYS) {
      if (typeof dto[k] === 'boolean') data[k] = dto[k] as boolean;
    }
    const saved = await this.prisma.userNotifSetting.upsert({
      where: { userId },
      update: data,
      create: { userId, ...data },
    });
    return { notifikasi: this.notifDari(saved) };
  }
}