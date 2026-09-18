import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { PengaturanService } from './pengaturan.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import {
  CreateSubAdminDto,
  UpdateKebijakanOnboardingDto,
  UpdateNotifikasiDto,
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

  @Get('sub-admin')
  getSubAdmins() {
    return this.pengaturanService.getSubAdmins();
  }

  @Post('sub-admin')
  inviteSubAdmin(@Body() dto: CreateSubAdminDto) {
    return this.pengaturanService.createSubAdmin(dto);
  }

  @Delete('sub-admin/:id')
  removeSubAdmin(@Param('id') id: string) {
    return this.pengaturanService.removeSubAdmin(id);
  }
}