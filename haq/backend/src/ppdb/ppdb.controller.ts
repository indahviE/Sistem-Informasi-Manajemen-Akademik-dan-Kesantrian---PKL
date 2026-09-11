import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { PpdbService } from './ppdb.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Public, Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { TenantId } from '../common/decorators/current-user.decorator';
import {
  CreatePlacementTestDto,
  DaftarPpdbDto,
  QueryPpdbDto,
  UpdatePendaftaranDto,
} from './dto/ppdb.dto';

@Controller('ppdb')
export class PpdbController {
  constructor(private ppdbService: PpdbService) {}

  @Public()
  @Post('daftar')
  daftar(@Body() dto: DaftarPpdbDto) {
    return this.ppdbService.daftar(dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Get()
  findAll(@TenantId() tenantId: string, @Query() q: QueryPpdbDto) {
    return this.ppdbService.findAll(tenantId, q);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Get(':id')
  findOne(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.ppdbService.findOne(tenantId, id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Patch(':id')
  updateStatus(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdatePendaftaranDto) {
    return this.ppdbService.updateStatus(tenantId, id, dto);
  }

  // ===== Placement Test =====
  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ)
  @Get(':id/placement-test')
  getPlacementTest(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.ppdbService.getPlacementTest(tenantId, id);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ)
  @Post(':id/placement-test')
  createPlacementTest(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() dto: CreatePlacementTestDto,
  ) {
    return this.ppdbService.createPlacementTest(tenantId, id, dto);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ)
  @Patch(':id/placement-test')
  updatePlacementTest(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() dto: CreatePlacementTestDto,
  ) {
    return this.ppdbService.updatePlacementTest(tenantId, id, dto);
  }
}