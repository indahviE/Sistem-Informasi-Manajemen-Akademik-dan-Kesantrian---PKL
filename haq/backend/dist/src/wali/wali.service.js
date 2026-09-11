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
exports.WaliService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let WaliService = class WaliService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(tenantId) {
        return this.prisma.waliSantri.findMany({
            where: { tenantId },
            include: {
                _count: { select: { santris: true } },
                user: { select: { id: true, email: true } },
            },
            orderBy: { nama: 'asc' },
        });
    }
    async create(tenantId, dto) {
        return this.prisma.waliSantri.create({
            data: { tenantId, ...dto },
        });
    }
    async update(tenantId, id, dto) {
        const found = await this.prisma.waliSantri.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Wali tidak ditemukan.');
        return this.prisma.waliSantri.update({ where: { id }, data: dto });
    }
    async linkUser(tenantId, dto) {
        const wali = await this.prisma.waliSantri.findFirst({
            where: { id: dto.waliId, tenantId },
        });
        if (!wali)
            throw new common_1.NotFoundException('Wali tidak ditemukan.');
        const user = await this.prisma.user.findFirst({
            where: { id: dto.userId, tenantId },
        });
        if (!user)
            throw new common_1.NotFoundException('User tidak ditemukan.');
        return this.prisma.waliSantri.update({
            where: { id: dto.waliId },
            data: { userId: dto.userId },
        });
    }
    async myProfile(userId) {
        const wali = await this.prisma.waliSantri.findFirst({
            where: { userId },
            include: {
                santris: { include: { kelas: { select: { namaKelas: true } } } },
            },
        });
        if (!wali)
            throw new common_1.NotFoundException('Akun wali belum terhubung ke data santri.');
        return wali;
    }
};
exports.WaliService = WaliService;
exports.WaliService = WaliService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], WaliService);
//# sourceMappingURL=wali.service.js.map