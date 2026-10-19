import { Controller, ForbiddenException, Get, Query, Req, UseGuards } from '@nestjs/common'; // BARU: ForbiddenException, Req
import { Role } from '@prisma/client';
import { AuditService } from './audit.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';

@Controller('audit-log')
export class AuditController {
  constructor(private auditService: AuditService) {}

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @Get()
  list(
    @Query('q') q?: string,
    @Query('kategori') kategori?: string,
    @Query('tingkat') tingkat?: string,
    @Query('tenantId') tenantId?: string,
    @Query('hari') hari?: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    return this.auditService.list({ q, kategori, tingkat, tenantId, hari, cursor, limit });
  }

  // BARU: log audit khusus pondok milik Mudir. tenantId dari token, bukan dari query.
  // GET /audit-log/pondok?q=&kategori=&tingkat=&hari=&cursor=&limit=
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.PIMPINAN)
  @Get('pondok')
  listPondok(
    @Req() req: any,
    @Query('q') q?: string,
    @Query('kategori') kategori?: string,
    @Query('tingkat') tingkat?: string,
    @Query('hari') hari?: string,
    @Query('cursor') cursor?: string,
    @Query('limit') limit?: string,
  ) {
    const tenantId = req?.user?.tenantId;
    if (!tenantId) throw new ForbiddenException('Akun ini tidak terhubung ke pondok');
    return this.auditService.listTenant(tenantId, { q, kategori, tingkat, hari, cursor, limit });
  }
}