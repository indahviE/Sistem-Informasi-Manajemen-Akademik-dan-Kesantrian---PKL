import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { PengaturanService } from './pengaturan.service';
import { PengaturanUstadzService } from './pengaturan-ustadz.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, RequestUser } from '../common/decorators/current-user.decorator';
import { Role } from '@prisma/client';
import {
  UbahPasswordDto,
  UpdateKebijakanOnboardingDto,
  UpdateNotifikasiAdminDto,
  UpdateNotifikasiDto,
  UpdateNotifikasiWaliDto,
  UpdateProfilDto,
} from './dto/pengaturan.dto';
import { UpdateNotifikasiUstadzDto } from './pengaturan-ustadz.dto';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('pengaturan')
export class PengaturanController {
  constructor(
    private pengaturanService: PengaturanService,
    private pengaturanUstadzService: PengaturanUstadzService,
  ) {}

  // ===== Khusus Super Admin (setting platform) =====

  @Roles(Role.SUPER_ADMIN)
  @Get()
  getSettings() {
    return this.pengaturanService.getSettings();
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch('kebijakan-onboarding')
  updateKebijakan(@Body() dto: UpdateKebijakanOnboardingDto) {
    return this.pengaturanService.updateKebijakanOnboarding(dto);
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch('notifikasi')
  updateNotifikasi(@Body() dto: UpdateNotifikasiDto) {
    return this.pengaturanService.updateNotifikasi(dto);
  }

  // ===== Dipakai bersama (Super Admin + Admin Lembaga) =====

  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.PIMPINAN, Role.WALI_SANTRI, Role.USTADZ)
  @Patch('profil')
  updateProfil(@CurrentUser() user: RequestUser, @Body() dto: UpdateProfilDto) {
    return this.pengaturanService.updateProfil(user.userId, dto);
  }

  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.PIMPINAN, Role.WALI_SANTRI, Role.USTADZ)
  @Patch('ubah-password')
  ubahPassword(@CurrentUser() user: RequestUser, @Body() dto: UbahPasswordDto) {
    return this.pengaturanService.ubahPassword(user.userId, dto);
  }

  // ===== Khusus Admin Lembaga =====

  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Get('admin')
  getAdminSettings(@CurrentUser() user: RequestUser) {
    return this.pengaturanService.getAdminSettings(user.userId);
  }

  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Patch('admin/notifikasi')
  updateAdminNotifikasi(
    @CurrentUser() user: RequestUser,
    @Body() dto: UpdateNotifikasiAdminDto,
  ) {
    return this.pengaturanService.updateAdminNotifikasi(user.userId, dto);
  }

  // ===== Khusus Wali Santri =====

  @Roles(Role.WALI_SANTRI)
  @Get('wali')
  getWaliSettings(@CurrentUser() user: RequestUser) {
    return this.pengaturanService.getWaliSettings(user.userId);
  }

  @Roles(Role.WALI_SANTRI)
  @Patch('wali/notifikasi')
  updateWaliNotifikasi(
    @CurrentUser() user: RequestUser,
    @Body() dto: UpdateNotifikasiWaliDto,
  ) {
    return this.pengaturanService.updateWaliNotifikasi(user.userId, dto);
  }

  // ===== Khusus Ustadz =====

  @Roles(Role.USTADZ)
  @Get('ustadz')
  getUstadz(@CurrentUser() user: RequestUser) {
    return this.pengaturanUstadzService.getUstadz(user.userId, user.tenantId as string);
  }

  @Roles(Role.USTADZ)
  @Patch('ustadz/notifikasi')
  updateUstadzNotifikasi(
    @CurrentUser() user: RequestUser,
    @Body() dto: UpdateNotifikasiUstadzDto,
  ) {
    return this.pengaturanUstadzService.updateNotifikasi(user.userId, dto);
  }
}