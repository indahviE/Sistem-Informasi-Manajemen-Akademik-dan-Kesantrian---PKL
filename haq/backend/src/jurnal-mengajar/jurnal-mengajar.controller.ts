import { Body, Controller, Delete, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';
import { JurnalMengajarService } from './jurnal-mengajar.service';
import {
  CreateJurnalMengajarDto,
  QueryJurnalMengajarDto,
  UpdateJurnalMengajarDto,
} from './dto/jurnal-mengajar.dto';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('jurnal-mengajar')
export class JurnalMengajarController {
  constructor(private jurnalService: JurnalMengajarService) {}

  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ)
  @Get()
  findAll(@TenantId() tenantId: string, @Query() q: QueryJurnalMengajarDto) {
    return this.jurnalService.findAll(tenantId, q);
  }

  @Roles(Role.ADMIN, Role.USTADZ)
  @Post()
  create(
    @TenantId() tenantId: string,
    @Body() dto: CreateJurnalMengajarDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.jurnalService.create(tenantId, dto, user);
  }

  @Roles(Role.ADMIN, Role.USTADZ)
  @Patch(':id')
  update(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() dto: UpdateJurnalMengajarDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.jurnalService.update(tenantId, id, dto, user);
  }

  @Roles(Role.ADMIN, Role.USTADZ)
  @Delete(':id')
  remove(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @CurrentUser() user: RequestUser,
  ) {
    return this.jurnalService.remove(tenantId, id, user);
  }
}