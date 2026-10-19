import { Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { NotifikasiService } from './notifikasi.service';
import { NotifikasiScheduler } from './notifikasi.scheduler';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('notifikasi')
export class NotifikasiController {
  constructor(
    private notifikasiService: NotifikasiService,
    private scheduler: NotifikasiScheduler,
  ) {}

  @Get()
  myNotifikasis(@CurrentUser() user: RequestUser, @TenantId() tenantId: string | undefined) {
    return this.notifikasiService.myNotifikasis(user.userId, tenantId);
  }

  @Get('unread-count')
  unreadCount(@CurrentUser() user: RequestUser, @TenantId() tenantId: string | undefined) {
    return this.notifikasiService.unreadCount(user.userId, tenantId);
  }

  /** Dipanggil dashboard ustadz saat dibuka: cek absensi & nilai yang belum beres. */
  @Post('cek-pengingat')
  async cekPengingat(@CurrentUser() user: RequestUser, @TenantId() tenantId: string | undefined) {
    if (!tenantId) return { ok: true };
    await this.scheduler.cekPengingatUntukUser(user.userId, tenantId);
    return { ok: true };
  }

  @Patch(':id/read')
  markRead(@CurrentUser() user: RequestUser, @TenantId() tenantId: string | undefined, @Param('id') id: string) {
    return this.notifikasiService.markRead(user.userId, tenantId, id);
  }

  @Post('read-all')
  markAllRead(@CurrentUser() user: RequestUser, @TenantId() tenantId: string | undefined) {
    return this.notifikasiService.markAllRead(user.userId, tenantId);
  }
}