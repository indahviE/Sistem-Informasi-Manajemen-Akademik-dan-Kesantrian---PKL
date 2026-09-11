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
exports.KurikulumController = void 0;
const common_1 = require("@nestjs/common");
const kurikulum_service_1 = require("./kurikulum.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const roles_guard_1 = require("../auth/guards/roles.guard");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const kurikulum_dto_1 = require("./dto/kurikulum.dto");
const VIEW = [client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ];
const WRITE = [client_1.Role.ADMIN, client_1.Role.PIMPINAN];
let KurikulumController = class KurikulumController {
    constructor(kurikulumService) {
        this.kurikulumService = kurikulumService;
    }
    findAllKurikulum(tenantId) {
        return this.kurikulumService.findAllKurikulum(tenantId);
    }
    createKurikulum(tenantId, dto) {
        return this.kurikulumService.createKurikulum(tenantId, dto);
    }
    updateKurikulum(tenantId, id, dto) {
        return this.kurikulumService.updateKurikulum(tenantId, id, dto);
    }
    removeKurikulum(tenantId, id) {
        return this.kurikulumService.removeKurikulum(tenantId, id);
    }
    findAllSilabus(tenantId) {
        return this.kurikulumService.findAllSilabus(tenantId);
    }
    createSilabus(tenantId, dto) {
        return this.kurikulumService.createSilabus(tenantId, dto);
    }
    updateSilabus(tenantId, id, dto) {
        return this.kurikulumService.updateSilabus(tenantId, id, dto);
    }
    removeSilabus(tenantId, id) {
        return this.kurikulumService.removeSilabus(tenantId, id);
    }
    findAllRpp(tenantId) {
        return this.kurikulumService.findAllRpp(tenantId);
    }
    createRpp(tenantId, dto) {
        return this.kurikulumService.createRpp(tenantId, dto);
    }
    updateRpp(tenantId, id, dto) {
        return this.kurikulumService.updateRpp(tenantId, id, dto);
    }
    removeRpp(tenantId, id) {
        return this.kurikulumService.removeRpp(tenantId, id);
    }
};
exports.KurikulumController = KurikulumController;
__decorate([
    (0, roles_decorator_1.Roles)(...VIEW),
    (0, common_1.Get)('kurikulum'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "findAllKurikulum", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Post)('kurikulum'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kurikulum_dto_1.CreateKurikulumDto]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "createKurikulum", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Patch)('kurikulum/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, kurikulum_dto_1.UpdateKurikulumDto]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "updateKurikulum", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Delete)('kurikulum/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "removeKurikulum", null);
__decorate([
    (0, roles_decorator_1.Roles)(...VIEW),
    (0, common_1.Get)('silabus'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "findAllSilabus", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Post)('silabus'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kurikulum_dto_1.CreateSilabusDto]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "createSilabus", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Patch)('silabus/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, kurikulum_dto_1.UpdateSilabusDto]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "updateSilabus", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Delete)('silabus/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "removeSilabus", null);
__decorate([
    (0, roles_decorator_1.Roles)(...VIEW),
    (0, common_1.Get)('rpp'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "findAllRpp", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Post)('rpp'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, kurikulum_dto_1.CreateRppDto]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "createRpp", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Patch)('rpp/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, kurikulum_dto_1.UpdateRppDto]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "updateRpp", null);
__decorate([
    (0, roles_decorator_1.Roles)(...WRITE),
    (0, common_1.Delete)('rpp/:id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String]),
    __metadata("design:returntype", void 0)
], KurikulumController.prototype, "removeRpp", null);
exports.KurikulumController = KurikulumController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.Controller)(),
    __metadata("design:paramtypes", [kurikulum_service_1.KurikulumService])
], KurikulumController);
//# sourceMappingURL=kurikulum.controller.js.map