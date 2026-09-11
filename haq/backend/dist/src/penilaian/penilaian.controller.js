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
exports.PenilaianController = void 0;
const common_1 = require("@nestjs/common");
const penilaian_service_1 = require("./penilaian.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const roles_guard_1 = require("../auth/guards/roles.guard");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const client_1 = require("@prisma/client");
const penilaian_dto_1 = require("./dto/penilaian.dto");
const PENGELOLA = [client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ, client_1.Role.MUSYRIF];
const WRITE = [client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ];
const TERBATAS = [client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.WALI_SANTRI];
let PenilaianController = class PenilaianController {
    constructor(penilaianService) {
        this.penilaianService = penilaianService;
    }
    findAllUjian(tenantId, kelasId) {
        return this.penilaianService.findAllUjian(tenantId, kelasId);
    }
    getUjian(tenantId, id) {
        return this.penilaianService.getUjian(tenantId, id);
    }
    createUjian(tenantId, dto) {
        return this.penilaianService.createUjian(tenantId, dto);
    }
    updateUjian(tenantId, id, dto) {
        return this.penilaianService.updateUjian(tenantId, id, dto);
    }
    removeUjian(tenantId, id) {
        return this.penilaianService.removeUjian(tenantId, id);
    }
    listNilaiUjian(tenantId, id) {
        return this.penilaianService.listNilaiUjian(tenantId, id);
    }
    inputNilaiUjian(tenantId, id, dto) {
        return this.penilaianService.inputNilaiUjian(tenantId, id, dto);
    }
    inputNilaiUjianBulk(tenantId, id, body, user) {
        return this.penilaianService.inputNilaiUjianBulk(tenantId, id, body.items ?? [], user);
    }
    removeNilaiUjian(tenantId, id, nilaiId) {
        return this.penilaianService.removeNilaiUjian(tenantId, id, nilaiId);
    }
    findAllRemedial(tenantId, santriId) {
        return this.penilaianService.findAllRemedial(tenantId, santriId);
    }
    createRemedial(tenantId, dto) {
        return this.penilaianService.createRemedial(tenantId, dto);
    }
    updateRemedial(tenantId, id, dto) {
        return this.penilaianService.updateRemedial(tenantId, id, dto);
    }
    removeRemedial(tenantId, id) {
        return this.penilaianService.removeRemedial(tenantId, id);
    }
    findAllRapor(tenantId, santriId, periode) {
        return this.penilaianService.findAllRapor(tenantId, santriId, periode);
    }
    getRapor(tenantId, id) {
        return this.penilaianService.getRapor(tenantId, id);
    }
    generateRapor(tenantId, dto) {
        return this.penilaianService.generateRapor(tenantId, dto);
    }
    terbitRapor(tenantId, id) {
        return this.penilaianService.terbitRapor(tenantId, id);
    }
    removeRapor(tenantId, id) {
        return this.penilaianService.removeRapor(tenantId, id);
    }
    findAllKelulusan(tenantId) {
        return this.penilaianService.findAllKelulusan(tenantId);
    }
    createKelulusan(tenantId, dto) {
        return this.penilaianService.createKelulusan(tenantId, dto);
    }
    updateKelulusan(tenantId, id, dto) {
        return this.penilaianService.updateKelulusan(tenantId, id, dto);
    }
    removeKelulusan(tenantId, id) {
        return this.penilaianService.removeKelulusan(tenantId, id);
    }
};
exports.PenilaianController = PenilaianController;
__decorate([
    (0, roles_decorator_1.Roles)(...PENGELOLA),
    (0, common_1.Get)('ujian'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)('kelasId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "findAllUjian", null);
__decorate([
    (0, roles_decorator_1.Roles)(...PENGELOLA),
    (0, common_1.Get)('ujian/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "getUjian", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Post)('ujian'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, penilaian_dto_1.CreateUjianDto]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "createUjian", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Patch)('ujian/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, penilaian_dto_1.UpdateUjianDto]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "updateUjian", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Delete)('ujian/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "removeUjian", null);
__decorate([
    (0, roles_decorator_1.Roles)(...PENGELOLA),
    (0, common_1.Get)('ujian/:id/nilai'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "listNilaiUjian", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Post)('ujian/:id/nilai'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, penilaian_dto_1.InputNilaiUjianDto]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "inputNilaiUjian", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Post)('ujian/:id/nilai/bulk'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __param(3, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, Object, Object]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "inputNilaiUjianBulk", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Delete)('ujian/:id/nilai/:nilaiId'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Param)('nilaiId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "removeNilaiUjian", null);
__decorate([
    (0, roles_decorator_1.Roles)(...PENGELOLA),
    (0, common_1.Get)('remedial'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)('santriId')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "findAllRemedial", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Post)('remedial'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, penilaian_dto_1.CreateRemedialDto]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "createRemedial", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Patch)('remedial/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, penilaian_dto_1.UpdateRemedialDto]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "updateRemedial", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Delete)('remedial/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "removeRemedial", null);
__decorate([
    (0, roles_decorator_1.Roles)(...TERBATAS),
    (0, common_1.Get)('rapor'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)('santriId')),
    __param(2, (0, common_1.Query)('periode')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "findAllRapor", null);
__decorate([
    (0, roles_decorator_1.Roles)(...TERBATAS),
    (0, common_1.Get)('rapor/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "getRapor", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Post)('rapor/generate'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, penilaian_dto_1.GenerateRaporDto]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "generateRapor", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Patch)('rapor/:id/terbit'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "terbitRapor", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Delete)('rapor/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "removeRapor", null);
__decorate([
    (0, roles_decorator_1.Roles)(...TERBATAS),
    (0, common_1.Get)('kelulusan'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "findAllKelulusan", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Post)('kelulusan'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, penilaian_dto_1.CreateKelulusanDto]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "createKelulusan", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Patch)('kelulusan/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, penilaian_dto_1.UpdateKelulusanDto]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "updateKelulusan", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Delete)('kelulusan/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PenilaianController.prototype, "removeKelulusan", null);
exports.PenilaianController = PenilaianController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.Controller)(),
    __metadata("design:paramtypes", [penilaian_service_1.PenilaianService])
], PenilaianController);
//# sourceMappingURL=penilaian.controller.js.map