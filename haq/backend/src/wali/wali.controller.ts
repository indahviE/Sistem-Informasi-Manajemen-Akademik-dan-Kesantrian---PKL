import { Body, Controller, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { WaliService } from './wali.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';
import { CreateWaliDto, LinkWaliUserDto } from './dto/wali.dto';
import { Role } from '@prisma/client';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller('wali')
export class WaliController {
  constructor(private waliService: WaliService) {}

  @Roles(Role.ADMIN, Role.PIMPINAN, Role.USTADZ, Role.MUSYRIF)
  @Get()
  findAll(@TenantId() tenantId: string) {
    return this.waliService.findAll(tenantId);
  }

  @Roles(Role.ADMIN)
  @Post()
  create(@TenantId() tenantId: string, @Body() dto: CreateWaliDto) {
    return this.waliService.create(tenantId, dto);
  }

  @Roles(Role.ADMIN)
  @Patch(':id')
  update(@TenantId() tenantId: string, @Param('id') id: string, @Body() dto: CreateWaliDto) {
    return this.waliService.update(tenantId, id, dto);
  }

  @Roles(Role.ADMIN)
  @Post('link-user')
  linkUser(@TenantId() tenantId: string, @Body() dto: LinkWaliUserDto) {
    return this.waliService.linkUser(tenantId, dto);
  }

  @Roles(Role.WALI_SANTRI)
  @Get('me')
  myProfile(@CurrentUser() user: RequestUser) {
    return this.waliService.myProfile(user.userId);
  }
}