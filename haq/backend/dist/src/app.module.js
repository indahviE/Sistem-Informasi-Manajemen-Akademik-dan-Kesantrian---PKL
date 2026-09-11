"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AppModule = void 0;
const common_1 = require("@nestjs/common");
const config_1 = require("@nestjs/config");
const core_1 = require("@nestjs/core");
const prisma_module_1 = require("./prisma/prisma.module");
const auth_module_1 = require("./auth/auth.module");
const tenants_module_1 = require("./tenants/tenants.module");
const users_module_1 = require("./users/users.module");
const santri_module_1 = require("./santri/santri.module");
const master_data_module_1 = require("./cabang/master-data.module");
const akademik_module_1 = require("./akademik/akademik.module");
const kesantrian_module_1 = require("./kesantrian/kesantrian.module");
const notifikasi_module_1 = require("./notifikasi/notifikasi.module");
const dashboard_module_1 = require("./dashboard/dashboard.module");
const wali_module_1 = require("./wali/wali.module");
const ppdb_module_1 = require("./ppdb/ppdb.module");
const kurikulum_module_1 = require("./kurikulum/kurikulum.module");
const penilaian_module_1 = require("./penilaian/penilaian.module");
const konseling_module_1 = require("./konseling/konseling.module");
const billing_module_1 = require("./billing/billing.module");
const jwt_public_global_guard_1 = require("./auth/guards/jwt-public.global.guard");
const roles_guard_1 = require("./auth/guards/roles.guard");
const tenant_isolation_guard_1 = require("./auth/guards/tenant-isolation.guard");
const audit_log_interceptor_1 = require("./common/interceptors/audit-log.interceptor");
let AppModule = class AppModule {
};
exports.AppModule = AppModule;
exports.AppModule = AppModule = __decorate([
    (0, common_1.Module)({
        imports: [
            config_1.ConfigModule.forRoot({ isGlobal: true }),
            prisma_module_1.PrismaModule,
            auth_module_1.AuthModule,
            tenants_module_1.TenantsModule,
            users_module_1.UsersModule,
            santri_module_1.SantriModule,
            master_data_module_1.MasterDataModule,
            akademik_module_1.AkademikModule,
            kesantrian_module_1.KesantrianModule,
            notifikasi_module_1.NotifikasiModule,
            dashboard_module_1.DashboardModule,
            wali_module_1.WaliModule,
            ppdb_module_1.PpdbModule,
            kurikulum_module_1.KurikulumModule,
            penilaian_module_1.PenilaianModule,
            konseling_module_1.KonselingModule,
            billing_module_1.BillingModule,
        ],
        providers: [
            { provide: core_1.APP_GUARD, useClass: jwt_public_global_guard_1.JwtPublicGlobalGuard },
            { provide: core_1.APP_GUARD, useClass: tenant_isolation_guard_1.TenantIsolationGuard },
            { provide: core_1.APP_GUARD, useClass: roles_guard_1.RolesGuard },
            { provide: core_1.APP_INTERCEPTOR, useClass: audit_log_interceptor_1.AuditLogInterceptor },
        ],
    })
], AppModule);
//# sourceMappingURL=app.module.js.map