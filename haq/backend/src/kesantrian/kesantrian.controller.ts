import { Body, Controller, Get, Param, Patch, Post, Put, Query, UseGuards } from '@nestjs/common';
import { KesantrianService } from './kesantrian.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';
import {
  CreateKesehatanDto,
  CreateKunjunganDto,
  CreatePelanggaranDto,
  CreatePerizinanDto,
  CreateTataTertibDto,
  QueryKesantrianDto,
  UpdatePelanggaranDto,
  UpdatePerizinanDto,
} from './dto/kesantrian.dto';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class KesantrianController {
  constructor(private kesantrianService: KesantrianService) {}

  // ===== Pelanggaran =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF, Role.WALI_SANTRI)
  @Get('pelanggaran')
  findAllPelanggaran(@TenantId() tenantId: string, @Query() q: QueryKesantrianDto) {
    return this.kesantrianService.findAllPelanggaran(tenantId, q);
  }

  @Roles(Role.ADMIN, Role.MUSYRIF)
  @Post('pelanggaran')
  createPelanggaran(@TenantId() tenantId: string, @Body() dto: CreatePelanggaranDto, @CurrentUser() user: RequestUser) {
    return this.kesantrianService.createPelanggaran(tenantId, dto, user);
  }

  @Roles(Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF)
  @Patch('pelanggaran/:id')
  updatePelanggaran(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdatePelanggaranDto) {
    return this.kesantrianService.updatePelanggaran(tenantId, id, dto);
  }

  // ===== Perizinan =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF, Role.WALI_SANTRI)
  @Get('perizinan')
  findAllPerizinan(@TenantId() tenantId: string, @Query() q: QueryKesantrianDto) {
    return this.kesantrianService.findAllPerizinan(tenantId, q);
  }

  @Roles(Role.ADMIN, Role.MUSYRIF)
  @Post('perizinan')
  createPerizinan(@TenantId() tenantId: string, @Body() dto: CreatePerizinanDto, @CurrentUser() user: RequestUser) {
    return this.kesantrianService.createPerizinan(tenantId, dto, user);
  }

  @Roles(Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF)
  @Patch('perizinan/:id')
  updatePerizinan(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdatePerizinanDto, @CurrentUser() user: RequestUser) {
    return this.kesantrianService.updatePerizinan(tenantId, id, dto, user);
  }

  // ===== Kesehatan =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF, Role.WALI_SANTRI)
  @Get('kesehatan')
  findAllKesehatan(@TenantId() tenantId: string, @Query() q: QueryKesantrianDto) {
    return this.kesantrianService.findAllKesehatan(tenantId, q);
  }

  @Roles(Role.ADMIN, Role.MUSYRIF)
  @Post('kesehatan')
  createKesehatan(@TenantId() tenantId: string, @Body() dto: CreateKesehatanDto, @CurrentUser() user: RequestUser) {
    return this.kesantrianService.createKesehatan(tenantId, dto, user);
  }

  // ===== Rekam Medis =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF, Role.WALI_SANTRI)
  @Get('rekam-medis/:santriId')
  getRekamMedis(@TenantId() tenantId: string, @Param('santriId') santriId: string) {
    return this.kesantrianService.getRekamMedis(tenantId, santriId);
  }

  @Roles(Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF)
  @Put('rekam-medis/:santriId')
  upsertRekamMedis(@TenantId() tenantId: string, @Param('santriId') santriId: string, @Body() dto: any) {
    return this.kesantrianService.upsertRekamMedis(tenantId, santriId, dto);
  }

  // ===== Kunjungan Wali =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF)
  @Get('kunjungan')
  findAllKunjungan(@TenantId() tenantId: string, @Query() q: QueryKesantrianDto) {
    return this.kesantrianService.findAllKunjungan(tenantId, q);
  }

  @Roles(Role.ADMIN, Role.MUSYRIF)
  @Post('kunjungan')
  createKunjungan(@TenantId() tenantId: string, @Body() dto: CreateKunjunganDto) {
    return this.kesantrianService.createKunjungan(tenantId, dto);
  }

  // ===== Tata Tertib =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.MUSYRIF, Role.USTADZ, Role.WALI_SANTRI, Role.SANTRI)
  @Get('tata-tertib')
  findAllTataTertib(@TenantId() tenantId: string) {
    return this.kesantrianService.findAllTataTertib(tenantId);
  }

  @Roles(Role.ADMIN)
  @Post('tata-tertib')
  createTataTertib(@TenantId() tenantId: string, @Body() dto: CreateTataTertibDto) {
    return this.kesantrianService.createTataTertib(tenantId, dto);
  }
}