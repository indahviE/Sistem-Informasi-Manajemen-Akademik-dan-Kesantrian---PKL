import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { MasterDataService } from './master-data.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { TenantId } from '../common/decorators/current-user.decorator';
import {
  CreateKelasDto,
  CreateMapelDto,
  CreateTahunAjaranDto,
  CreateUstadzDto,
  UpdateKelasDto,
  UpdateMapelDto,
  UpdateUstadzDto,
} from './dto/master.dto';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class MasterDataController {
  constructor(private masterService: MasterDataService) {}

  // ===== Ustadz =====
  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Get('ustadz')
  findAllUstadz(@TenantId() tenantId: string, @Query('jenis') jenis?: string) {
    return this.masterService.findAllUstadz(tenantId, jenis);
  }

  @Roles(Role.ADMIN)
  @Post('ustadz')
  createUstadz(@TenantId() tenantId: string, @Body() dto: CreateUstadzDto) {
    return this.masterService.createUstadz(tenantId, dto);
  }

  @Roles(Role.ADMIN)
  @Patch('ustadz/:id')
  updateUstadz(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateUstadzDto) {
    return this.masterService.updateUstadz(tenantId, id, dto);
  }

  @Roles(Role.ADMIN)
  @Delete('ustadz/:id')
  removeUstadz(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.masterService.removeUstadz(tenantId, id);
  }

  // ===== Kelas =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ, Role.MUSYRIF)
  @Get('kelas')
  findAllKelas(@TenantId() tenantId: string) {
    return this.masterService.findAllKelas(tenantId);
  }

  @Roles(Role.ADMIN)
  @Post('kelas')
  createKelas(@TenantId() tenantId: string, @Body() dto: CreateKelasDto) {
    return this.masterService.createKelas(tenantId, dto);
  }

  @Roles(Role.ADMIN)
  @Patch('kelas/:id')
  updateKelas(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateKelasDto) {
    return this.masterService.updateKelas(tenantId, id, dto);
  }

  @Roles(Role.ADMIN)
  @Delete('kelas/:id')
  removeKelas(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.masterService.removeKelas(tenantId, id);
  }

  // ===== Mapel =====
  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ)
  @Get('mapel')
  findAllMapel(@TenantId() tenantId: string) {
    return this.masterService.findAllMapel(tenantId);
  }

  @Roles(Role.ADMIN)
  @Post('mapel')
  createMapel(@TenantId() tenantId: string, @Body() dto: CreateMapelDto) {
    return this.masterService.createMapel(tenantId, dto);
  }

  @Roles(Role.ADMIN)
  @Patch('mapel/:id')
  updateMapel(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateMapelDto) {
    return this.masterService.updateMapel(tenantId, id, dto);
  }

  @Roles(Role.ADMIN)
  @Delete('mapel/:id')
  removeMapel(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.masterService.removeMapel(tenantId, id);
  }

  // ===== Tahun Ajaran =====
  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Get('tahun-ajaran')
  findAllTahunAjaran(@TenantId() tenantId: string) {
    return this.masterService.findAllTahunAjaran(tenantId);
  }

  @Roles(Role.ADMIN)
  @Post('tahun-ajaran')
  createTahunAjaran(@TenantId() tenantId: string, @Body() dto: CreateTahunAjaranDto) {
    return this.masterService.createTahunAjaran(tenantId, dto);
  }

  @Roles(Role.ADMIN)
  @Post('tahun-ajaran/:id/aktif')
  setAktif(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.masterService.setTahunAjaranAktif(tenantId, id);
  }
}