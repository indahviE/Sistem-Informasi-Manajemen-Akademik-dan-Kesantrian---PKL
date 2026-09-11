import { Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { NotifikasiService } from './notifikasi.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';

@UseGuards(JwtAuthGuard)
@Controller('notifikasi')
export class NotifikasiController {
  constructor(private notifikasiService: NotifikasiService) {}

  @Get()
  myNotifikasis(@CurrentUser() user: RequestUser, @TenantId() tenantId: string | undefined) {
    return this.notifikasiService.myNotifikasis(user.userId, tenantId);
  }

  @Get('unread-count')
  unreadCount(@CurrentUser() user: RequestUser, @TenantId() tenantId: string | undefined) {
    return this.notifikasiService.unreadCount(user.userId, tenantId);
  }

  @Patch(':id/read')
  markRead(@CurrentUser() user: RequestUser, @Param('id') id: string) {
    return this.notifikasiService.markRead(user.userId, id);
  }

  @Post('read-all')
  markAllRead(@CurrentUser() user: RequestUser, @TenantId() tenantId: string | undefined) {
    return this.notifikasiService.markAllRead(user.userId, tenantId);
  }
}