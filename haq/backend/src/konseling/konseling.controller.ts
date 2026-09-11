import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { KonselingService } from './konseling.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';
import { CreateKonselingDto, UpdateKonselingDto } from './dto/konseling.dto';

const AKSES = [Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF, Role.USTADZ];

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('konseling')
export class KonselingController {
  constructor(private konselingService: KonselingService) {}

  @Roles(...AKSES)
  @Get()
  findAll(@TenantId() tenantId: string, @Query('santriId') santriId?: string) {
    return this.konselingService.findAllKonseling(tenantId, santriId);
  }

  @Roles(...AKSES)
  @Post()
  create(@TenantId() tenantId: string, @Body() dto: CreateKonselingDto, @CurrentUser() user: RequestUser) {
    return this.konselingService.createKonseling(tenantId, dto, user);
  }

  @Roles(...AKSES)
  @Patch(':id')
  update(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateKonselingDto) {
    return this.konselingService.updateKonseling(tenantId, id, dto);
  }

  @Roles(...AKSES)
  @Delete(':id')
  remove(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.konselingService.removeKonseling(tenantId, id);
  }
}