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
exports.PpdbController = void 0;
const common_1 = require("@nestjs/common");
const ppdb_service_1 = require("./ppdb.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const roles_guard_1 = require("../auth/guards/roles.guard");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const ppdb_dto_1 = require("./dto/ppdb.dto");
let PpdbController = class PpdbController {
    constructor(ppdbService) {
        this.ppdbService = ppdbService;
    }
    daftar(dto) {
        return this.ppdbService.daftar(dto);
    }
    findAll(tenantId, q) {
        return this.ppdbService.findAll(tenantId, q);
    }
    findOne(tenantId, id) {
        return this.ppdbService.findOne(tenantId, id);
    }
    updateStatus(tenantId, id, dto) {
        return this.ppdbService.updateStatus(tenantId, id, dto);
    }
    getPlacementTest(tenantId, id) {
        return this.ppdbService.getPlacementTest(tenantId, id);
    }
    createPlacementTest(tenantId, id, dto) {
        return this.ppdbService.createPlacementTest(tenantId, id, dto);
    }
    updatePlacementTest(tenantId, id, dto) {
        return this.ppdbService.updatePlacementTest(tenantId, id, dto);
    }
};
exports.PpdbController = PpdbController;
__decorate([
    (0, roles_decorator_1.Public)(),
    (0, common_1.Post)('daftar'),
    __param(0, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [ppdb_dto_1.DaftarPpdbDto]),
    __metadata("design:returntype", void 0)
], PpdbController.prototype, "daftar", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN),
    (0, common_1.Get)(),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, ppdb_dto_1.QueryPpdbDto]),
    __metadata("design:returntype", void 0)
], PpdbController.prototype, "findAll", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN),
    (0, common_1.Get)(':id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PpdbController.prototype, "findOne", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN),
    (0, common_1.Patch)(':id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, ppdb_dto_1.UpdatePendaftaranDto]),
    __metadata("design:returntype", void 0)
], PpdbController.prototype, "updateStatus", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ),
    (0, common_1.Get)(':id/placement-test'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], PpdbController.prototype, "getPlacementTest", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ),
    (0, common_1.Post)(':id/placement-test'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, ppdb_dto_1.CreatePlacementTestDto]),
    __metadata("design:returntype", void 0)
], PpdbController.prototype, "createPlacementTest", null);
__decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ),
    (0, common_1.Patch)(':id/placement-test'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, ppdb_dto_1.CreatePlacementTestDto]),
    __metadata("design:returntype", void 0)
], PpdbController.prototype, "updatePlacementTest", null);
exports.PpdbController = PpdbController = __decorate([
    (0, common_1.Controller)('ppdb'),
    __metadata("design:paramtypes", [ppdb_service_1.PpdbService])
], PpdbController);
//# sourceMappingURL=ppdb.controller.js.map