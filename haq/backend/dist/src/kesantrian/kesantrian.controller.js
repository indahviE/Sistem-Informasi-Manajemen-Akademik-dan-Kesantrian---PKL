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
exports.KesantrianController = void 0;
const common_1 = require("@nestjs/common");
const kesantrian_service_1 = require("./kesantrian.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const roles_guard_1 = require("../auth/guards/roles.guard");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const kesantrian_dto_1 = require("./dto/kesantrian.dto");
const client_1 = require("@prisma/client");
let KesantrianController = class KesantrianController {
    constructor(kesantrianService) {
        this.kesantrianService = kesantrianService;
    }
    findAllPelanggaran(tenantId, q) {
        return this.kesantrianService.findAllPelanggaran(tenantId, q);
    }
    createPelanggaran(tenantId, dto, user) {
        return this.kesantrianService.createPelanggaran(tenantId, dto, user);
    }
    updatePelanggaran(tenantId, id, dto) {
        return this.kesantrianService.updatePelanggaran(tenantId, id, dto);
    }
    findAllPerizinan(tenantId, q) {
        return this.kesantrianService.findAllPerizinan(tenantId, q);
    }
    createPerizinan(tenantId, dto, user) {
        return this.kesantrianService.createPerizinan(tenantId, dto, user);
    }
    updatePerizinan(tenantId, id, dto, user) {
        return this.kesantrianService.updatePerizinan(tenantId, id, dto, user);
    }
    findAllKesehatan(tenantId, q) {
        return this.kesantrianService.findAllKesehatan(tenantId, q);
    }
    createKesehatan(tenantId, dto, user) {
        return this.kesantrianService.createKesehatan(tenantId, dto, user);
    }
    getRekamMedis(tenantId, santriId) {
        return this.kesantrianService.getRekamMedis(tenantId, santriId);
    }
    upsertRekamMedis(tenantId, santriId, dto) {
        return this.kesantrianService.upsertRekamMedis(tenantId, santriId, dto);
    }
    findAllKunjungan(tenantId, q) {
        return this.kesantrianService.findAllKunjungan(tenantId, q);
    }
    createKunjungan(tenantId, dto) {
        return this.kesantrianService.createKunjungan(tenantId, dto);
    }
    findAllTataTertib(tenantId) {
        return this.kesantrianService.findAllTataTertib(tenantId);
    }
    createTataTertib(tenantId, dto) {
        return this.kesantrianService.createTataTertib(tenantId, dto);
    }
};
exports.KesantrianController = KesantrianController;
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.MUSYRIF, client_1.Role.WALI_SANTRI),
    (0, common_1.Get)('pelanggaran'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kesantrian_dto_1.QueryKesantrianDto]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "findAllPelanggaran", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MUSYRIF),
    (0, common_1.Post)('pelanggaran'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kesantrian_dto_1.CreatePelanggaranDto, Object]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "createPelanggaran", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.MUSYRIF),
    (0, common_1.Patch)('pelanggaran/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, kesantrian_dto_1.UpdatePelanggaranDto]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "updatePelanggaran", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.MUSYRIF, client_1.Role.WALI_SANTRI),
    (0, common_1.Get)('perizinan'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kesantrian_dto_1.QueryKesantrianDto]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "findAllPerizinan", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MUSYRIF),
    (0, common_1.Post)('perizinan'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kesantrian_dto_1.CreatePerizinanDto, Object]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "createPerizinan", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.MUSYRIF),
    (0, common_1.Patch)('perizinan/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __param(3, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, kesantrian_dto_1.UpdatePerizinanDto, Object]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "updatePerizinan", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.MUSYRIF, client_1.Role.WALI_SANTRI),
    (0, common_1.Get)('kesehatan'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kesantrian_dto_1.QueryKesantrianDto]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "findAllKesehatan", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MUSYRIF),
    (0, common_1.Post)('kesehatan'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __param(2, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kesantrian_dto_1.CreateKesehatanDto, Object]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "createKesehatan", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.MUSYRIF, client_1.Role.WALI_SANTRI),
    (0, common_1.Get)('rekam-medis/:santriId'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('santriId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "getRekamMedis", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.MUSYRIF),
    (0, common_1.Put)('rekam-medis/:santriId'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('santriId')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "upsertRekamMedis", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.MUSYRIF),
    (0, common_1.Get)('kunjungan'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kesantrian_dto_1.QueryKesantrianDto]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "findAllKunjungan", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.MUSYRIF),
    (0, common_1.Post)('kunjungan'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kesantrian_dto_1.CreateKunjunganDto]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "createKunjungan", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.MUSYRIF, client_1.Role.USTADZ, client_1.Role.WALI_SANTRI, client_1.Role.SANTRI),
    (0, common_1.Get)('tata-tertib'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "findAllTataTertib", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Post)('tata-tertib'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kesantrian_dto_1.CreateTataTertibDto]),
    __metadata("design:returntype", void 0)
], KesantrianController.prototype, "createTataTertib", null);
exports.KesantrianController = KesantrianController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.Controller)(),
    __metadata("design:paramtypes", [kesantrian_service_1.KesantrianService])
], KesantrianController);
//# sourceMappingURL=kesantrian.controller.js.map