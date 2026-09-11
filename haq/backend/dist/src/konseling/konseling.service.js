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
exports.KonselingService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let KonselingService = class KonselingService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async assertSantri(tenantId, santriId) {
        const found = await this.prisma.santri.findFirst({ where: { id: santriId, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Santri tidak ditemukan di pondok ini.');
        return found;
    }
    async findAllKonseling(tenantId, santriId) {
        return this.prisma.konseling.findMany({
            where: { tenantId, ...(santriId ? { santriId } : {}) },
            include: {
                santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } },
                konselor: { select: { id: true, nama: true } },
            },
            orderBy: { tanggal: 'desc' },
        });
    }
    async createKonseling(tenantId, dto, user) {
        await this.assertSantri(tenantId, dto.santriId);
        if (dto.konselorId) {
            const konselor = await this.prisma.ustadz.findFirst({ where: { id: dto.konselorId, tenantId } });
            if (!konselor)
                throw new common_1.NotFoundException('Konselor tidak ditemukan.');
        }
        return this.prisma.konseling.create({
            data: {
                tenantId,
                santriId: dto.santriId,
                tanggal: dto.tanggal ? new Date(dto.tanggal) : new Date(),
                konselorId: dto.konselorId ?? null,
                topik: dto.topik,
                catatan: dto.catatan,
                tindakLanjut: dto.tindakLanjut ?? null,
                privat: dto.privat ?? true,
            },
            include: {
                santri: { select: { id: true, nama: true, nis: true } },
                konselor: { select: { id: true, nama: true } },
            },
        });
    }
    async updateKonseling(tenantId, id, dto) {
        const found = await this.prisma.konseling.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Catatan konseling tidak ditemukan.');
        return this.prisma.konseling.update({
            where: { id },
            data: {
                tanggal: dto.tanggal ? new Date(dto.tanggal) : undefined,
                konselorId: dto.konselorId ?? undefined,
                topik: dto.topik,
                catatan: dto.catatan,
                tindakLanjut: dto.tindakLanjut,
                privat: dto.privat,
            },
        });
    }
    async removeKonseling(tenantId, id) {
        const found = await this.prisma.konseling.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Catatan konseling tidak ditemukan.');
        return this.prisma.konseling.delete({ where: { id } });
    }
};
exports.KonselingService = KonselingService;
exports.KonselingService = KonselingService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], KonselingService);
//# sourceMappingURL=konseling.service.js.map