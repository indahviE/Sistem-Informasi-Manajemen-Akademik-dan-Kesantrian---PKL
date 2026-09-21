import { Controller, Get, Query, UseGuards } from '@nestjs/common';
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
}