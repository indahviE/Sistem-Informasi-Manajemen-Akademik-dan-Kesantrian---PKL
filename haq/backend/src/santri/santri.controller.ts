import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { SantriService } from './santri.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { TenantId } from '../common/decorators/current-user.decorator';
import { CreateSantriDto, QuerySantriDto, UpdateSantriDto } from './dto/santri.dto';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('santri')
export class SantriController {
  constructor(private santriService: SantriService) {}

  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ, Role.MUSYRIF)
  @Get()
  findAll(@TenantId() tenantId: string, @Query() query: QuerySantriDto) {
    return this.santriService.findAll(tenantId, query);
  }

  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ, Role.MUSYRIF)
  @Get(':id')
  findOne(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.santriService.findOne(tenantId, id);
  }

  @Roles(Role.ADMIN)
  @Post()
  create(@TenantId() tenantId: string, @Body() dto: CreateSantriDto) {
    return this.santriService.create(tenantId, dto);
  }

  @Roles(Role.ADMIN)
  @Patch(':id')
  update(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: UpdateSantriDto) {
    return this.santriService.update(tenantId, id, dto);
  }

  @Roles(Role.ADMIN)
  @Delete(':id')
  remove(@TenantId() tenantId: string, @Param('id') id: string) {
    return this.santriService.remove(tenantId, id);
  }
}