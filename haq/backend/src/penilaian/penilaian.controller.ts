import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { PenilaianService } from './penilaian.service';
import { SimpanRemedialDto } from './dto/simpan-remedial.dto';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';
import {
  BukaKunciDto,
  CreateKelulusanDto,
  CreateRemedialDto,
  CreateUjianDto,
  GenerateRaporDto,
  InputNilaiUjianDto,
  UpdateKelulusanDto,
  UpdateRemedialDto,
  UpdateUjianDto,
} from './dto/penilaian.dto';

const PENGELOLA = [Role.ADMIN, Role.PIMPINAN, Role.USTADZ, Role.MUSYRIF];
const WRITE = [Role.ADMIN, Role.PIMPINAN, Role.USTADZ];
const TERBATAS = [Role.ADMIN, Role.PIMPINAN, Role.WALI_SANTRI];

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class PenilaianController {
  constructor(private penilaianService: PenilaianService) {}

  // ===== Ujian =====
  @Roles(...PENGELOLA)
  @Get('ujian')
  findAllUjian(
    @TenantId() tenantId: string,
    @CurrentUser() user: RequestUser,
    @Query('kelasId') kelasId?: string,
    @Query('saya') saya?: string,
  ) {
    return this.penilaianService.findAllUjian(tenantId, kelasId, user, saya === 'true');
  }

  @Roles(...PENGELOLA)
  @Get('ujian/:id')
  getUjian(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.penilaianService.getUjian(tenantId, id);
  }

  @Roles(...WRITE)
  @Post('ujian')
  createUjian(@TenantId() tenantId: string, @Body() dto: CreateUjianDto, @CurrentUser() user: RequestUser) {
    return this.penilaianService.createUjian(tenantId, dto, user);
  }

  @Roles(...WRITE)
  @Patch('ujian/:id')
  updateUjian(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() dto: UpdateUjianDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.penilaianService.updateUjian(tenantId, id, dto, user);
  }

  @Roles(...WRITE)
  @Delete('ujian/:id')
  removeUjian(@TenantId() tenantId: string, @Param('id') id: string, @CurrentUser() user: RequestUser) {
    return this.penilaianService.removeUjian(tenantId, id, user);
  }

  // ===== Kunci Nilai =====
  @Roles(...WRITE)
  @Post('ujian/:id/kunci')
  kunciUjian(@TenantId() tenantId: string, @Param('id') id: string, @CurrentUser() user: RequestUser) {
    return this.penilaianService.kunciUjian(tenantId, id, user);
  }

  @Roles(...WRITE)
  @Post('ujian/:id/buka-kunci')
  bukaKunciUjian(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() dto: BukaKunciDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.penilaianService.bukaKunciUjian(tenantId, id, dto, user);
  }

  // ===== Nilai Ujian =====
  @Roles(...PENGELOLA)
  @Get('ujian/:id/nilai')
  listNilaiUjian(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.penilaianService.listNilaiUjian(tenantId, id);
  }

  @Roles(...WRITE)
  @Post('ujian/:id/nilai')
  inputNilaiUjian(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() dto: InputNilaiUjianDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.penilaianService.inputNilaiUjian(tenantId, id, dto, user);
  }

  @Roles(...WRITE)
  @Post('ujian/:id/nilai/bulk')
  inputNilaiUjianBulk(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() body: { items: InputNilaiUjianDto[] },
    @CurrentUser() user: RequestUser,
  ) {
    return this.penilaianService.inputNilaiUjianBulk(tenantId, id, body.items ?? [], user);
  }

  @Roles(...WRITE)
  @Delete('ujian/:id/nilai/:nilaiId')
  removeNilaiUjian(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Param('nilaiId') nilaiId: string,
    @CurrentUser() user: RequestUser,
  ) {
    return this.penilaianService.removeNilaiUjian(tenantId, id, nilaiId, user);
  }

  // ===== Remedial per Ujian =====
  @Roles(...PENGELOLA)
  @Get('ujian/:id/remedial')
  listRemedialUjian(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.penilaianService.listRemedialUjian(tenantId, id);
  }

  @Roles(...WRITE)
  @Post('ujian/:id/remedial')
  simpanRemedialUjian(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() dto: SimpanRemedialDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.penilaianService.simpanRemedialUjian(tenantId, id, dto, user);
  }

  // ===== Remedial =====
  @Roles(...PENGELOLA)
  @Get('remedial')
  findAllRemedial(@TenantId() tenantId: string, @Query('santriId') santriId?: string) {
    return this.penilaianService.findAllRemedial(tenantId, santriId);
  }

  @Roles(...WRITE)
  @Post('remedial')
  createRemedial(@TenantId() tenantId: string, @Body() dto: CreateRemedialDto) {
    return this.penilaianService.createRemedial(tenantId, dto);
  }

  @Roles(...WRITE)
  @Patch('remedial/:id')
  updateRemedial(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateRemedialDto) {
    return this.penilaianService.updateRemedial(tenantId, id, dto);
  }

  @Roles(...WRITE)
  @Delete('remedial/:id')
  removeRemedial(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.penilaianService.removeRemedial(tenantId, id);
  }

  // ===== Rapor =====
  @Roles(...TERBATAS)
  @Get('rapor')
  findAllRapor(@TenantId() tenantId: string, @Query('santriId') santriId?: string, @Query('periode') periode?: string) {
    return this.penilaianService.findAllRapor(tenantId, santriId, periode);
  }

  @Roles(...TERBATAS)
  @Get('rapor/:id')
  getRapor(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.penilaianService.getRapor(tenantId, id);
  }

  @Roles(...WRITE)
  @Post('rapor/generate')
  generateRapor(@TenantId() tenantId: string, @Body() dto: GenerateRaporDto) {
    return this.penilaianService.generateRapor(tenantId, dto);
  }

  @Roles(...WRITE)
  @Patch('rapor/:id/terbit')
  terbitRapor(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.penilaianService.terbitRapor(tenantId, id);
  }

  @Roles(...WRITE)
  @Delete('rapor/:id')
  removeRapor(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.penilaianService.removeRapor(tenantId, id);
  }

  // ===== Kelulusan & Wisuda Tahfidz =====
  @Roles(...TERBATAS)
  @Get('kelulusan')
  findAllKelulusan(@TenantId() tenantId: string) {
    return this.penilaianService.findAllKelulusan(tenantId);
  }

  @Roles(...WRITE)
  @Post('kelulusan')
  createKelulusan(@TenantId() tenantId: string, @Body() dto: CreateKelulusanDto) {
    return this.penilaianService.createKelulusan(tenantId, dto);
  }

  @Roles(...WRITE)
  @Patch('kelulusan/:id')
  updateKelulusan(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateKelulusanDto) {
    return this.penilaianService.updateKelulusan(tenantId, id, dto);
  }

  @Roles(...WRITE)
  @Delete('kelulusan/:id')
  removeKelulusan(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.penilaianService.removeKelulusan(tenantId, id);
  }
}