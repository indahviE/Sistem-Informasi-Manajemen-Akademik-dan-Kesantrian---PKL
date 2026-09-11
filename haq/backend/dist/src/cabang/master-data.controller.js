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
exports.MasterDataController = void 0;
const common_1 = require("@nestjs/common");
const master_data_service_1 = require("./master-data.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const roles_guard_1 = require("../auth/guards/roles.guard");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const master_dto_1 = require("./dto/master.dto");
const client_1 = require("@prisma/client");
let MasterDataController = class MasterDataController {
    constructor(masterService) {
        this.masterService = masterService;
    }
    findAllUstadz(tenantId, jenis) {
        return this.masterService.findAllUstadz(tenantId, jenis);
    }
    createUstadz(tenantId, dto) {
        return this.masterService.createUstadz(tenantId, dto);
    }
    updateUstadz(tenantId, id, dto) {
        return this.masterService.updateUstadz(tenantId, id, dto);
    }
    removeUstadz(tenantId, id) {
        return this.masterService.removeUstadz(tenantId, id);
    }
    findAllKelas(tenantId) {
        return this.masterService.findAllKelas(tenantId);
    }
    createKelas(tenantId, dto) {
        return this.masterService.createKelas(tenantId, dto);
    }
    updateKelas(tenantId, id, dto) {
        return this.masterService.updateKelas(tenantId, id, dto);
    }
    removeKelas(tenantId, id) {
        return this.masterService.removeKelas(tenantId, id);
    }
    findAllMapel(tenantId) {
        return this.masterService.findAllMapel(tenantId);
    }
    createMapel(tenantId, dto) {
        return this.masterService.createMapel(tenantId, dto);
    }
    updateMapel(tenantId, id, dto) {
        return this.masterService.updateMapel(tenantId, id, dto);
    }
    removeMapel(tenantId, id) {
        return this.masterService.removeMapel(tenantId, id);
    }
    findAllTahunAjaran(tenantId) {
        return this.masterService.findAllTahunAjaran(tenantId);
    }
    createTahunAjaran(tenantId, dto) {
        return this.masterService.createTahunAjaran(tenantId, dto);
    }
    setAktif(tenantId, id) {
        return this.masterService.setTahunAjaranAktif(tenantId, id);
    }
};
exports.MasterDataController = MasterDataController;
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN),
    (0, common_1.Get)('ustadz'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Query)('jenis')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "findAllUstadz", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Post)('ustadz'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, master_dto_1.CreateUstadzDto]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "createUstadz", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Patch)('ustadz/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, master_dto_1.UpdateUstadzDto]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "updateUstadz", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Delete)('ustadz/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "removeUstadz", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ, client_1.Role.MUSYRIF),
    (0, common_1.Get)('kelas'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "findAllKelas", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Post)('kelas'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, master_dto_1.CreateKelasDto]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "createKelas", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Patch)('kelas/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, master_dto_1.UpdateKelasDto]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "updateKelas", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Delete)('kelas/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "removeKelas", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ),
    (0, common_1.Get)('mapel'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "findAllMapel", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Post)('mapel'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, master_dto_1.CreateMapelDto]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "createMapel", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Patch)('mapel/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, master_dto_1.UpdateMapelDto]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "updateMapel", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Delete)('mapel/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "removeMapel", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN),
    (0, common_1.Get)('tahun-ajaran'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "findAllTahunAjaran", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Post)('tahun-ajaran'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, master_dto_1.CreateTahunAjaranDto]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "createTahunAjaran", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Post)('tahun-ajaran/:id/aktif'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], MasterDataController.prototype, "setAktif", null);
exports.MasterDataController = MasterDataController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.Controller)(),
    __metadata("design:paramtypes", [master_data_service_1.MasterDataService])
], MasterDataController);
//# sourceMappingURL=master-data.controller.js.map