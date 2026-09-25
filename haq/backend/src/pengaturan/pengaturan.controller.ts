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
  UpdateNotifikasiDto,
  UpdateProfilDto,
} from './dto/pengaturan.dto';

@UseGuards(JwtAuthGuard, RolesGuard)
@Roles(Role.SUPER_ADMIN)
@Controller('pengaturan')
export class PengaturanController {
  constructor(private pengaturanService: PengaturanService) {}

  @Get()
  getSettings() {
    return this.pengaturanService.getSettings();
  }

  @Patch('kebijakan-onboarding')
  updateKebijakan(@Body() dto: UpdateKebijakanOnboardingDto) {
    return this.pengaturanService.updateKebijakanOnboarding(dto);
  }

  @Patch('notifikasi')
  updateNotifikasi(@Body() dto: UpdateNotifikasiDto) {
    return this.pengaturanService.updateNotifikasi(dto);
  }

  @Patch('profil')
  updateProfil(@CurrentUser() user: RequestUser, @Body() dto: UpdateProfilDto) {
    return this.pengaturanService.updateProfil(user.userId, dto);
  }

  @Patch('ubah-password')
  ubahPassword(@CurrentUser() user: RequestUser, @Body() dto: UbahPasswordDto) {
    return this.pengaturanService.ubahPassword(user.userId, dto);
  }
}