import { Module } from '@nestjs/common';
import { ConfigModule } from '@nestjs/config';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { PrismaModule } from './prisma/prisma.module';
import { AuthModule } from './auth/auth.module';
import { TenantsModule } from './tenants/tenants.module';
import { UsersModule } from './users/users.module';
import { SantriModule } from './santri/santri.module';
import { MasterDataModule } from './cabang/master-data.module';
import { AkademikModule } from './akademik/akademik.module';
import { KesantrianModule } from './kesantrian/kesantrian.module';
import { NotifikasiModule } from './notifikasi/notifikasi.module';
import { DashboardModule } from './dashboard/dashboard.module';
import { WaliModule } from './wali/wali.module';
import { PpdbModule } from './ppdb/ppdb.module';
import { KurikulumModule } from './kurikulum/kurikulum.module';
import { PenilaianModule } from './penilaian/penilaian.module';
import { KonselingModule } from './konseling/konseling.module';
import { BillingModule } from './billing/billing.module';
import { JwtPublicGlobalGuard } from './auth/guards/jwt-public.global.guard';
import { RolesGuard } from './auth/guards/roles.guard';
import { TenantIsolationGuard } from './auth/guards/tenant-isolation.guard';
import { AuditLogInterceptor } from './common/interceptors/audit-log.interceptor';
import { PembinaanModule } from './pembinaan/pembinaan.module';

@Module({
  imports: [
    ConfigModule.forRoot({ isGlobal: true }),
    PrismaModule,
    AuthModule,
    TenantsModule,
    UsersModule,
    SantriModule,
    MasterDataModule,
    AkademikModule,
    KesantrianModule,
    NotifikasiModule,
    DashboardModule,
    WaliModule,
    PpdbModule,
    KurikulumModule,
    PenilaianModule,
    KonselingModule,
    BillingModule,
    PembinaanModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: JwtPublicGlobalGuard },
    { provide: APP_GUARD, useClass: TenantIsolationGuard },
    { provide: APP_GUARD, useClass: RolesGuard },
    { provide: APP_INTERCEPTOR, useClass: AuditLogInterceptor },
  ],
})
export class AppModule {}
