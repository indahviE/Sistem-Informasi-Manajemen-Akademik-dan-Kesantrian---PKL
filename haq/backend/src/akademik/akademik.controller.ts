import { Body, Controller, ForbiddenException, Get, Post, Query, UseGuards } from '@nestjs/common';
import { AkademikService } from './akademik.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles, Public } from '../common/decorators/roles.decorator';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';
import {
  BulkAbsensiDto,
  CreateAbsensiDto,
  CreateNilaiDto,
  CreateTahfidzDto,
  QueryAbsensiDto,
} from './dto/akademik.dto';
import { JenisNilai, Role } from '@prisma/client';
import { WaliService } from '../wali/wali.service'; 

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class AkademikController {
  constructor(
    private akademikService: AkademikService,
    private waliService: WaliService,   
  ) {}

  // ===== Absensi =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ, Role.MUSYRIF, Role.MUSYRIF)
  @Get('absensi')
  findAllAbsensi(@TenantId() tenantId: string, @Query() q: QueryAbsensiDto) {
    return this.akademikService.findAllAbsensi(tenantId, q);
  }

  @Roles(Role.ADMIN, Role.USTADZ, Role.MUSYRIF)
  @Post('absensi')
  createAbsensi(@TenantId() tenantId: string, @Body() dto: CreateAbsensiDto, @CurrentUser() user: RequestUser) {
    return this.akademikService.createAbsensi(tenantId, dto, user);
  }

  @Roles(Role.ADMIN, Role.USTADZ)
  @Post('absensi/bulk')
  bulkAbsensi(@TenantId() tenantId: string, @Body() dto: BulkAbsensiDto, @CurrentUser() user: RequestUser) {
    return this.akademikService.bulkAbsensi(tenantId, dto, user);
  }

  // ===== Nilai =====
    @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ, Role.WALI_SANTRI)
  @Get('nilai')
  async findAllNilai(
    @TenantId() tenantId: string,
    @CurrentUser() user: RequestUser,
    @Query('santriId') santriId?: string,
    @Query('mapelId') mapelId?: string,
    @Query('jenis') jenis?: JenisNilai,
  ) {
    let allowed: string[] | undefined;
    if (user.role === Role.WALI_SANTRI) {
      allowed = await this.waliService.getSantriIds(user.userId);
      if (santriId && !allowed.includes(santriId)) {
        throw new ForbiddenException('Anda tidak memiliki akses ke data santri ini.');
      }
    }
    return this.akademikService.findAllNilai(tenantId, santriId, mapelId, jenis, allowed);
  }

  @Roles(Role.ADMIN, Role.USTADZ)
  @Post('nilai')
  createNilai(@TenantId() tenantId: string, @Body() dto: CreateNilaiDto, @CurrentUser() user: RequestUser) {
    return this.akademikService.createNilai(tenantId, dto, user);
  }

  // ===== Tahfidz =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ, Role.WALI_SANTRI)
  @Get('tahfidz')
  async findAllTahfidz(
    @TenantId() tenantId: string,
    @CurrentUser() user: RequestUser,
    @Query('santriId') santriId?: string,
  ) {
    let allowed: string[] | undefined;
    if (user.role === Role.WALI_SANTRI) {
      allowed = await this.waliService.getSantriIds(user.userId);
      if (santriId && !allowed.includes(santriId)) {
        throw new ForbiddenException('Anda tidak memiliki akses ke data santri ini.');
      }
    }
    return this.akademikService.findAllTahfidz(tenantId, santriId, allowed);
  }

  @Roles(Role.ADMIN, Role.USTADZ)
  @Post('tahfidz')
  createTahfidz(@TenantId() tenantId: string, @Body() dto: CreateTahfidzDto, @CurrentUser() user: RequestUser) {
    return this.akademikService.createTahfidz(tenantId, dto, user);
  }
}