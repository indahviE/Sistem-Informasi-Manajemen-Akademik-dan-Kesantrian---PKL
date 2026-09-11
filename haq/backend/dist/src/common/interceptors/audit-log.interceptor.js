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
exports.AuditLogInterceptor = void 0;
const common_1 = require("@nestjs/common");
const rxjs_1 = require("rxjs");
const prisma_service_1 = require("../../prisma/prisma.service");
const MUTATION_METHODS = ['POST', 'PUT', 'PATCH', 'DELETE'];
let AuditLogInterceptor = class AuditLogInterceptor {
    constructor(prisma) {
        this.prisma = prisma;
    }
    intercept(context, next) {
        const req = context.switchToHttp().getRequest();
        const method = req.method;
        const isMutation = MUTATION_METHODS.includes(method);
        if (!isMutation) {
            return next.handle();
        }
        const user = req.user;
        const entity = this.extractEntity(req.route?.path || req.originalUrl || '');
        return next.handle().pipe((0, rxjs_1.tap)({
            next: (res) => {
                const entityId = res?.id ?? res?.data?.id;
                this.prisma.auditLog
                    .create({
                    data: {
                        tenantId: user?.tenantId ?? null,
                        userId: user?.userId ?? null,
                        userNama: user?.email ?? null,
                        action: method,
                        entity,
                        entityId: entityId ? String(entityId) : null,
                        data: {
                            url: req.originalUrl,
                            body: req.body ?? {},
                        },
                    },
                })
                    .catch(() => { });
            },
        }));
    }
    extractEntity(url) {
        const clean = url.replace(/\/([0-9a-zA-Z]+)(\/|$)/g, '/:id/');
        const seg = clean.split('?')[0];
        return seg;
    }
};
exports.AuditLogInterceptor = AuditLogInterceptor;
exports.AuditLogInterceptor = AuditLogInterceptor = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AuditLogInterceptor);
//# sourceMappingURL=audit-log.interceptor.js.map