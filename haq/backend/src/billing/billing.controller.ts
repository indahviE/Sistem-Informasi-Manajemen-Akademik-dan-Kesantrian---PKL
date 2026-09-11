import { Body, Controller, Delete, Get, Param, Patch, Post, UseGuards } from '@nestjs/common';
import { BillingService } from './billing.service';
import { JwtAuthGuard } from '../auth/guards/jwt-auth.guard';
import { RolesGuard } from '../auth/guards/roles.guard';
import { Roles } from '../common/decorators/roles.decorator';
import { Role } from '@prisma/client';
import { TenantId, CurrentUser, RequestUser } from '../common/decorators/current-user.decorator';
import {
  AssignSubscriptionDto,
  CreateInvoiceDto,
  CreatePaketDto,
  UpdateInvoiceDto,
  UpdatePaketDto,
  UpdateSubscriptionDto,
} from './dto/billing.dto';

@UseGuards(JwtAuthGuard, RolesGuard)
@Controller()
export class BillingController {
  constructor(private billingService: BillingService) {}

  // ===== Paket =====
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.PIMPINAN)
  @Get('paket')
  findAllPaket() {
    return this.billingService.findAllPaket();
  }

  @Roles(Role.SUPER_ADMIN)
  @Post('paket')
  createPaket(@Body() dto: CreatePaketDto) {
    return this.billingService.createPaket(dto);
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch('paket/:id')
  updatePaket(@Param('id') id: string, @Body() dto: UpdatePaketDto) {
    return this.billingService.updatePaket(id, dto);
  }

  @Roles(Role.SUPER_ADMIN)
  @Delete('paket/:id')
  removePaket(@Param('id') id: string) {
    return this.billingService.removePaket(id);
  }

  // ===== Subscription =====
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.PIMPINAN)
  @Get('subscriptions')
  findAllSubscription(@CurrentUser() user: RequestUser, @TenantId() tenantId?: string) {
    return this.billingService.findAllSubscription(user.role === Role.SUPER_ADMIN, tenantId);
  }

  @Roles(Role.SUPER_ADMIN)
  @Post('subscriptions')
  assignSubscription(@Body() dto: AssignSubscriptionDto) {
    return this.billingService.assignSubscription(dto);
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch('subscriptions/:id')
  updateSubscription(@Param('id') id: string, @Body() dto: UpdateSubscriptionDto) {
    return this.billingService.updateSubscription(id, dto);
  }

  // ===== Invoice =====
  @Roles(Role.SUPER_ADMIN, Role.ADMIN, Role.PIMPINAN)
  @Get('invoices')
  findAllInvoice(@CurrentUser() user: RequestUser, @TenantId() tenantId?: string) {
    return this.billingService.findAllInvoice(user.role === Role.SUPER_ADMIN, tenantId);
  }

  @Roles(Role.SUPER_ADMIN)
  @Post('invoices')
  createInvoice(@Body() dto: CreateInvoiceDto) {
    return this.billingService.createInvoice(dto);
  }

  @Roles(Role.SUPER_ADMIN)
  @Patch('invoices/:id')
  updateInvoice(@Param('id') id: string, @Body() dto: UpdateInvoiceDto) {
    return this.billingService.updateInvoice(id, dto);
  }
}
