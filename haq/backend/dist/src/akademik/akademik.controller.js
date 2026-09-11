"use strict";
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
var __param = (this && this.__param) || function (paramIndex, decorator) {
    return function (target, key) { decorator(target, key, paramIndex); }
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.AkademikController = void 0;
const common_1 = require("@nestjs/common");
const akademik_service_1 = require("./akademik.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const roles_guard_1 = require("../auth/guards/roles.guard");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const akademik_dto_1 = require("./dto/akademik.dto");
const client_1 = require("@prisma/client");
let AkademikController = class AkademikController {
    constructor(akademikService) {
        this.akademikService = akademikService;
    }
    findAllAbsensi(tenantId, q) {
        return this.akademikService.findAllAbsensi(tenantId, q);
    }
    createAbsensi(tenantId, dto, user) {
        return this.akademikService.createAbsensi(tenantId, dto, user);
    }
    bulkAbsensi(tenantId, dto, user) {
        return this.akademikService.bulkAbsensi(tenantId, dto, user);
    }
    findAllNilai(tenantId, santriId, mapelId, jenis) {
        return this.akademikService.findAllNilai(tenantId, santriId, mapelId, jenis);
    }
    createNilai(tenantId, dto, user) {
        return this.akademikService.createNilai(tenantId, dto, user);
    }
    findAllTahfidz(tenantId, santriId) {
        return this.akademikService.findAllTahfidz(tenantId, santriId);
    }
    createTahfidz(tenantId, dto, user) {
        return this.akademikService.createTahfidz(tenantId, dto, user);
    }
};
exports.AkademikController = AkademikController;
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ, client_1.Role.MUSYRIF),
    (0, common_1.Get)('absensi'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, akademik_dto_1.QueryAbsensiDto]),
    __metadata("design:returntype", void 0)
], AkademikController.prototype, "findAllAbsensi", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.USTADZ, client_1.Role.MUSYRIF),
    (0, common_1.Post)('absensi'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, akademik_dto_1.CreateAbsensiDto, Object]),
    __metadata("design:returntype", void 0)
], AkademikController.prototype, "createAbsensi", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.USTADZ),
    (0, common_1.Post)('absensi/bulk'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, akademik_dto_1.BulkAbsensiDto, Object]),
    __metadata("design:returntype", void 0)
], AkademikController.prototype, "bulkAbsensi", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ, client_1.Role.WALI_SANTRI),
    (0, common_1.Get)('nilai'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)('santriId')),
    __param(2, (0, common_1.Query)('mapelId')),
    __param(3, (0, common_1.Query)('jenis')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String, String]),
    __metadata("design:returntype", void 0)
], AkademikController.prototype, "findAllNilai", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.USTADZ),
    (0, common_1.Post)('nilai'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, akademik_dto_1.CreateNilaiDto, Object]),
    __metadata("design:returntype", void 0)
], AkademikController.prototype, "createNilai", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ, client_1.Role.WALI_SANTRI),
    (0, common_1.Get)('tahfidz'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)('santriId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], AkademikController.prototype, "findAllTahfidz", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.USTADZ),
    (0, common_1.Post)('tahfidz'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, akademik_dto_1.CreateTahfidzDto, Object]),
    __metadata("design:returntype", void 0)
], AkademikController.prototype, "createTahfidz", null);
exports.AkademikController = AkademikController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.Controller)(),
    __metadata("design:paramtypes", [akademik_service_1.AkademikService])
], AkademikController);
//# sourceMappingURL=akademik.controller.js.map