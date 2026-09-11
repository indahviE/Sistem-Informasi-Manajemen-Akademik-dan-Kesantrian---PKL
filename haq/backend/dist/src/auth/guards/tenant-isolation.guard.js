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
Object.defineProperty(exports, "__esModule", { value: true });
exports.TenantIsolationGuard = void 0;
const common_1 = require("@nestjs/common");
const core_1 = require("@nestjs/core");
const roles_decorator_1 = require("../../common/decorators/roles.decorator");
const client_1 = require("@prisma/client");
let TenantIsolationGuard = class TenantIsolationGuard {
    constructor(reflector) {
        this.reflector = reflector;
    }
    canActivate(context) {
        const isPublic = this.reflector.getAllAndOverride(roles_decorator_1.IS_PUBLIC_KEY, [
            context.getHandler(),
            context.getClass(),
        ]);
        if (isPublic) {
            return true;
        }
        const req = context.switchToHttp().getRequest();
        const user = req.user;
        if (!user) {
            return true;
        }
        if (user.role === client_1.Role.SUPER_ADMIN) {
            return true;
        }
        if (!user.tenantId) {
            throw new common_1.ForbiddenException('Akun ini tidak terikat ke pondok mana pun. Hubungi administrator.');
        }
        if (user.tenantStatus && user.tenantStatus !== client_1.TenantStatus.AKTIF) {
            throw new common_1.ForbiddenException('Pondok Anda belum aktif. Hubungi Super Admin untuk aktivasi.');
        }
        return true;
    }
};
exports.TenantIsolationGuard = TenantIsolationGuard;
exports.TenantIsolationGuard = TenantIsolationGuard = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [core_1.Reflector])
], TenantIsolationGuard);
//# sourceMappingURL=tenant-isolation.guard.js.map