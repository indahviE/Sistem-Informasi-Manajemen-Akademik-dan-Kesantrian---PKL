// src/mudir/mudir.controller.ts  (FILE BARU, khusus role PIMPINAN / Mudir)
//
// Semua endpoint dikunci @Roles(Role.PIMPINAN) dan memakai tenantId dari token,
// bukan dari query, supaya Mudir tidak bisa membuka data pondok lain.
//
// CATATAN: cara mengambil tenantId dari request di sini memakai req.user.tenantId
// (pola umum JwtStrategy). Kalau di proyekmu pakai decorator lain (mis. @CurrentUser()),
// ganti bagian getTenantId() saja.

import { Controller, ForbiddenException, Get, Query, Req, UseGuards } from '@nestjs/common';
import { Role } from '@prisma/client';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Granularitas, MudirService } from './mudir.service';

@Controller('mudir')
@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.PIMPINAN)
export class MudirController {
  constructor(private mudirService: MudirService) {}

  private getTenantId(req: any): string {
    const tenantId = req?.user?.tenantId;
    if (!tenantId) throw new ForbiddenException('Akun ini tidak terhubung ke pondok');
    return tenantId;
  }

  // GET /mudir/akademik?tahunAjaranId=&dari=&sampai=
  @Get('akademik')
  akademik(
    @Req() req: any,
    @Query('tahunAjaranId') tahunAjaranId?: string,
    @Query('dari') dari?: string,
    @Query('sampai') sampai?: string,
  ) {
    return this.mudirService.ringkasanAkademik(this.getTenantId(req), tahunAjaranId, dari, sampai);
  }

  // GET /mudir/tren?tahunAjaranId=&granularitas=minggu|bulan&dari=&sampai=
  @Get('tren')
  tren(
    @Req() req: any,
    @Query('tahunAjaranId') tahunAjaranId?: string,
    @Query('granularitas') granularitas?: string,
    @Query('dari') dari?: string,
    @Query('sampai') sampai?: string,
  ) {
    const g: Granularitas = granularitas === 'minggu' ? 'minggu' : 'bulan';
    return this.mudirService.tren(this.getTenantId(req), tahunAjaranId, g, dari, sampai);
  }

  // GET /mudir/laporan?tahunAjaranId=&dari=&sampai=
  @Get('laporan')
  laporan(
    @Req() req: any,
    @Query('tahunAjaranId') tahunAjaranId?: string,
    @Query('dari') dari?: string,
    @Query('sampai') sampai?: string,
  ) {
    return this.mudirService.laporan(this.getTenantId(req), tahunAjaranId, dari, sampai);
  }
}