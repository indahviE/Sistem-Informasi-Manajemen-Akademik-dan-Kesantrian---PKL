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
exports.KurikulumService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let KurikulumService = class KurikulumService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAllKurikulum(tenantId) {
        return this.prisma.kurikulum.findMany({
            where: { tenantId },
            orderBy: { createdAt: 'desc' },
            include: {
                tahunAjaran: true,
                _count: { select: { silabus: true } },
            },
        });
    }
    async createKurikulum(tenantId, dto) {
        return this.prisma.kurikulum.create({
            data: { tenantId, ...dto },
            include: { tahunAjaran: true },
        });
    }
    async updateKurikulum(tenantId, id, dto) {
        const exist = await this.prisma.kurikulum.findFirst({ where: { id, tenantId } });
        if (!exist)
            throw new common_1.NotFoundException('Kurikulum tidak ditemukan.');
        return this.prisma.kurikulum.update({ where: { id }, data: dto });
    }
    async removeKurikulum(tenantId, id) {
        const exist = await this.prisma.kurikulum.findFirst({ where: { id, tenantId } });
        if (!exist)
            throw new common_1.NotFoundException('Kurikulum tidak ditemukan.');
        return this.prisma.kurikulum.delete({ where: { id } });
    }
    async findAllSilabus(tenantId) {
        return this.prisma.silabus.findMany({
            where: { tenantId },
            orderBy: { createdAt: 'desc' },
            include: { kurikulum: true, mapel: true },
        });
    }
    async createSilabus(tenantId, dto) {
        return this.prisma.silabus.create({ data: { tenantId, ...dto } });
    }
    async updateSilabus(tenantId, id, dto) {
        const exist = await this.prisma.silabus.findFirst({ where: { id, tenantId } });
        if (!exist)
            throw new common_1.NotFoundException('Silabus tidak ditemukan.');
        return this.prisma.silabus.update({ where: { id }, data: dto });
    }
    async removeSilabus(tenantId, id) {
        const exist = await this.prisma.silabus.findFirst({ where: { id, tenantId } });
        if (!exist)
            throw new common_1.NotFoundException('Silabus tidak ditemukan.');
        return this.prisma.silabus.delete({ where: { id } });
    }
    async findAllRpp(tenantId) {
        return this.prisma.rpp.findMany({
            where: { tenantId },
            orderBy: [{ pertemuan: 'asc' }, { createdAt: 'desc' }],
            include: { mapel: true },
        });
    }
    async createRpp(tenantId, dto) {
        return this.prisma.rpp.create({
            data: { tenantId, pertemuan: dto.pertemuan ?? 1, ...dto },
        });
    }
    async updateRpp(tenantId, id, dto) {
        const exist = await this.prisma.rpp.findFirst({ where: { id, tenantId } });
        if (!exist)
            throw new common_1.NotFoundException('RPP tidak ditemukan.');
        return this.prisma.rpp.update({ where: { id }, data: dto });
    }
    async removeRpp(tenantId, id) {
        const exist = await this.prisma.rpp.findFirst({ where: { id, tenantId } });
        if (!exist)
            throw new common_1.NotFoundException('RPP tidak ditemukan.');
        return this.prisma.rpp.delete({ where: { id } });
    }
};
exports.KurikulumService = KurikulumService;
exports.KurikulumService = KurikulumService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], KurikulumService);
//# sourceMappingURL=kurikulum.service.js.map