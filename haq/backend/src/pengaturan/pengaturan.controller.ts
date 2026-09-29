import { Body, Controller, Get, Patch, UseGuards } from '@nestjs/common';
import { PengaturanService } from './pengaturan.service';
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
  UpdateProfilDto,
} from './dto/pengaturan.dto';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('pengaturan')
export class PengaturanController {
  constructor(private pengaturanService: PengaturanService) {}

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

  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.PIMPINAN)
  @Patch('profil')
  updateProfil(@CurrentUser() user: RequestUser, @Body() dto: UpdateProfilDto) {
    return this.pengaturanService.updateProfil(user.userId, dto);
  }

  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.PIMPINAN)
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
}