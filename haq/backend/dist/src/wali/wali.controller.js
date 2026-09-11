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
exports.WaliController = void 0;
const common_1 = require("@nestjs/common");
const wali_service_1 = require("./wali.service");
const jwt_auth_guard_1 = require("../auth/guards/jwt-auth.guard");
const roles_guard_1 = require("../auth/guards/roles.guard");
const roles_decorator_1 = require("../common/decorators/roles.decorator");
const current_user_decorator_1 = require("../common/decorators/current-user.decorator");
const wali_dto_1 = require("./dto/wali.dto");
const client_1 = require("@prisma/client");
let WaliController = class WaliController {
    constructor(waliService) {
        this.waliService = waliService;
    }
    findAll(tenantId) {
        return this.waliService.findAll(tenantId);
    }
    create(tenantId, dto) {
        return this.waliService.create(tenantId, dto);
    }
    update(tenantId, id, dto) {
        return this.waliService.update(tenantId, id, dto);
    }
    linkUser(tenantId, dto) {
        return this.waliService.linkUser(tenantId, dto);
    }
    myProfile(user) {
        return this.waliService.myProfile(user.userId);
    }
};
exports.WaliController = WaliController;
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN, client_1.Role.PIMPINAN, client_1.Role.USTADZ, client_1.Role.MUSYRIF),
    (0, common_1.Get)(),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String]),
    __metadata("design:returntype", void 0)
], WaliController.prototype, "findAll", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Post)(),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, wali_dto_1.CreateWaliDto]),
    __metadata("design:returntype", void 0)
], WaliController.prototype, "create", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Patch)(':id'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Param)('id')),
    __param(2, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, String, wali_dto_1.CreateWaliDto]),
    __metadata("design:returntype", void 0)
], WaliController.prototype, "update", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.ADMIN),
    (0, common_1.Post)('link-user'),
    __param(0, (0, current_user_decorator_1.TenantId)()),
    __param(1, (0, common_1.Body)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [String, wali_dto_1.LinkWaliUserDto]),
    __metadata("design:returntype", void 0)
], WaliController.prototype, "linkUser", null);
__decorate([
    (0, roles_decorator_1.Roles)(client_1.Role.WALI_SANTRI),
    (0, common_1.Get)('me'),
    __param(0, (0, current_user_decorator_1.CurrentUser)()),
    __metadata("design:type", Function),
    __metadata("design:paramtypes", [Object]),
    __metadata("design:returntype", void 0)
], WaliController.prototype, "myProfile", null);
exports.WaliController = WaliController = __decorate([
    (0, common_1.UseGuards)(jwt_auth_guard_1.JwtAuthGuard, roles_guard_1.RolesGuard),
    (0, common_1.Controller)('wali'),
    __metadata("design:paramtypes", [wali_service_1.WaliService])
], WaliController);
//# sourceMappingURL=wali.controller.js.map