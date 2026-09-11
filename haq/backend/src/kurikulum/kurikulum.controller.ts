import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { KurikulumService } from './kurikulum.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { TenantId } from '../common/decorators/current-user.decorator';
import {
  CreateKurikulumDto,
  CreateRppDto,
  CreateSilabusDto,
  UpdateKurikulumDto,
  UpdateRppDto,
  UpdateSilabusDto,
} from './dto/kurikulum.dto';

const VIEW = [Role.ADMIN, Role.PIMPINAN, Role.USTADZ];
const WRITE = [Role.ADMIN, Role.PIMPINAN];

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class KurikulumController {
  constructor(private kurikulumService: KurikulumService) {}

  // ===== Kurikulum =====
  @Roles(...VIEW)
  @Get('kurikulum')
  findAllKurikulum(@TenantId() tenantId: string) {
    return this.kurikulumService.findAllKurikulum(tenantId);
  }

  @Roles(...WRITE)
  @Post('kurikulum')
  createKurikulum(@TenantId() tenantId: string, @Body() dto: CreateKurikulumDto) {
    return this.kurikulumService.createKurikulum(tenantId, dto);
  }

  @Roles(...WRITE)
  @Patch('kurikulum/:id')
  updateKurikulum(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateKurikulumDto) {
    return this.kurikulumService.updateKurikulum(tenantId, id, dto);
  }

  @Roles(...WRITE)
  @Delete('kurikulum/:id')
  removeKurikulum(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.kurikulumService.removeKurikulum(tenantId, id);
  }

  // ===== Silabus =====
  @Roles(...VIEW)
  @Get('silabus')
  findAllSilabus(@TenantId() tenantId: string) {
    return this.kurikulumService.findAllSilabus(tenantId);
  }

  @Roles(...WRITE)
  @Post('silabus')
  createSilabus(@TenantId() tenantId: string, @Body() dto: CreateSilabusDto) {
    return this.kurikulumService.createSilabus(tenantId, dto);
  }

  @Roles(...WRITE)
  @Patch('silabus/:id')
  updateSilabus(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateSilabusDto) {
    return this.kurikulumService.updateSilabus(tenantId, id, dto);
  }

  @Roles(...WRITE)
  @Delete('silabus/:id')
  removeSilabus(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.kurikulumService.removeSilabus(tenantId, id);
  }

  // ===== RPP =====
  @Roles(...VIEW)
  @Get('rpp')
  findAllRpp(@TenantId() tenantId: string) {
    return this.kurikulumService.findAllRpp(tenantId);
  }

  @Roles(...WRITE)
  @Post('rpp')
  createRpp(@TenantId() tenantId: string, @Body() dto: CreateRppDto) {
    return this.kurikulumService.createRpp(tenantId, dto);
  }

  @Roles(...WRITE)
  @Patch('rpp/:id')
  updateRpp(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateRppDto) {
    return this.kurikulumService.updateRpp(tenantId, id, dto);
  }

  @Roles(...WRITE)
  @Delete('rpp/:id')
  removeRpp(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.kurikulumService.removeRpp(tenantId, id);
  }
}