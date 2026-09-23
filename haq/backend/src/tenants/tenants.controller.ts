import { Body, Controller, Get, Param, Patch, Post, Query, Req, UseGuards } from '@nestjs/common';
import { TenantsService } from './tenants.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Public, Roles } from '../common/decorators/roles.decorator';
import { Role, TenantStatus } from '@prisma/client';
import { ApproveTenantDto, SignupTenantDto, UpdateBrandingDto } from './dto/tenant.dto';
import { CurrentUser, RequestUser, TenantId } from '../common/decorators/current-user.decorator';

@Controller('tenants')
export class TenantsController {
  constructor(private tenantsService: TenantsService) {}

  @Public()
  @Post('signup')
  signup(@Body() dto: SignupTenantDto, @Req() req: { ip?: string }) {
    return this.tenantsService.signup(dto, req.ip);
  }

  @Public()
  @Get('check-slug')
  checkSlug(@Query('kode') kode: string) {
    return this.tenantsService
      .isSlugAvailable(kode)
      .then((available) => ({ available }));
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @Get()
  findAll(@Query('status') status?: TenantStatus) {
    return this.tenantsService.findAll(status);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @Post('approve')
  approve(@Body() dto: ApproveTenantDto, @CurrentUser() user: RequestUser, @Req() req: { ip?: string }) {
    return this.tenantsService.approve(dto.tenantId, user, req.ip);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @Post('suspend')
  suspend(@Body() dto: ApproveTenantDto, @CurrentUser() user: RequestUser, @Req() req: { ip?: string }) {
    return this.tenantsService.suspend(dto.tenantId, user, req.ip);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @Post('archive')
  archive(@Body() dto: ApproveTenantDto, @CurrentUser() user: RequestUser, @Req() req: { ip?: string }) {
    return this.tenantsService.archive(dto.tenantId, user, req.ip);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @Post('unarchive')
  unarchive(@Body() dto: ApproveTenantDto, @CurrentUser() user: RequestUser, @Req() req: { ip?: string }) {
    return this.tenantsService.unarchive(dto.tenantId, user, req.ip);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.SUPER_ADMIN)
  @Post('delete-pending')
  deletePending(@Body() dto: ApproveTenantDto, @CurrentUser() user: RequestUser, @Req() req: { ip?: string }) {
    return this.tenantsService.deletePending(dto.tenantId, user, req.ip);
  }

  @UseGuards(JwtAuthGuard)
  @Get('me')
  getMyTenant(@TenantId() tenantId: string | undefined) {
    return tenantId
      ? this.tenantsService.getByTenantId(tenantId)
      : { note: 'Super Admin tidak memiliki tenant' };
  }

  @Public()
  @Get('branding')
  getBranding(@Query('kodeTenant') kodeTenant: string) {
    return this.tenantsService.getBranding(kodeTenant);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Get('branding/me')
  getMyBranding(@TenantId() tenantId: string) {
    return this.tenantsService.getMyBranding(tenantId);
  }

  @UseGuards(JwtAuthGuard, RolesGuard)
  @Roles(Role.ADMIN, Role.PIMPINAN)
  @Patch('branding')
  updateBranding(@TenantId() tenantId: string, @Body() dto: UpdateBrandingDto) {
    return this.tenantsService.updateBranding(tenantId, dto);
  }
}