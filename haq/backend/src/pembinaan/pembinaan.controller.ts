import { Body, Controller, Get, Param, Patch, Post, Query, UseGuards } from '@nestjs/common';
import { PembinaanService } from './pembinaan.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';
import {
  CreateKeadaanDaruratDto,
  CreatePembinaanIbadahDto,
  CreatePembinaanKarakterDto,
  QueryPembinaanDto,
  UpdateKeadaanDaruratDto,
} from './dto/pembinaan.dto';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class PembinaanController {
  constructor(private pembinaanService: PembinaanService) {}

  // ===== Pembinaan Karakter =====
  @Roles(Role.ADMIN, Role.MUSYRIF, Role.USTADZ, Role.PIMPINAN, Role.WALI_SANTRI)
  @Get('pembinaan-karakter')
  findAllPembinaanKarakter(
    @TenantId() tenantId: string,
    @Query() q: QueryPembinaanDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.pembinaanService.findAllPembinaanKarakter(tenantId, q, user);
  }

  @Roles(Role.ADMIN, Role.MUSYRIF, Role.USTADZ, Role.PIMPINAN)
  @Post('pembinaan-karakter')
  createPembinaanKarakter(
    @TenantId() tenantId: string,
    @Body() dto: CreatePembinaanKarakterDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.pembinaanService.createPembinaanKarakter(tenantId, dto, user);
  }

  // ===== Pembinaan Ibadah =====
  @Roles(Role.ADMIN, Role.MUSYRIF, Role.PIMPINAN, Role.WALI_SANTRI)
  @Get('pembinaan-ibadah')
  findAllPembinaanIbadah(
    @TenantId() tenantId: string,
    @Query() q: QueryPembinaanDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.pembinaanService.findAllPembinaanIbadah(tenantId, q, user);
  }

  @Roles(Role.ADMIN, Role.MUSYRIF, Role.PIMPINAN)
  @Post('pembinaan-ibadah')
  createPembinaanIbadah(
    @TenantId() tenantId: string,
    @Body() dto: CreatePembinaanIbadahDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.pembinaanService.createPembinaanIbadah(tenantId, dto, user);
  }

  // ===== Keadaan Darurat =====
  @Roles(Role.ADMIN, Role.MUSYRIF, Role.USTADZ, Role.PIMPINAN)
  @Get('keadaan-darurat')
  findAllKeadaanDarurat(@TenantId() tenantId: string) {
    return this.pembinaanService.findAllKeadaanDarurat(tenantId);
  }

  @Roles(Role.ADMIN, Role.MUSYRIF, Role.USTADZ, Role.PIMPINAN)
  @Post('keadaan-darurat')
  createKeadaanDarurat(
    @TenantId() tenantId: string,
    @Body() dto: CreateKeadaanDaruratDto,
    @CurrentUser() user: RequestUser,
  ) {
    return this.pembinaanService.createKeadaanDarurat(tenantId, dto, user);
  }

  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Patch('keadaan-darurat/:id')
  updateKeadaanDarurat(
    @TenantId() tenantId: string,
    @Param('id') id: string,
    @Body() dto: UpdateKeadaanDaruratDto,
  ) {
    return this.pembinaanService.updateKeadaanDarurat(tenantId, id, dto);
  }
}