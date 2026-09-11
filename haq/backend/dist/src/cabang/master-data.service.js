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
exports.MasterDataService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let MasterDataService = class MasterDataService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    findAllUstadz(tenantId, jenis) {
        return this.prisma.ustadz.findMany({
            where: { tenantId, ...(jenis ? { jenis: jenis } : {}) },
            orderBy: { nama: 'asc' },
        });
    }
    createUstadz(tenantId, dto) {
        return this.prisma.ustadz.create({ data: { tenantId, ...dto } });
    }
    async updateUstadz(tenantId, id, dto) {
        const found = await this.prisma.ustadz.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Ustadz tidak ditemukan.');
        return this.prisma.ustadz.update({ where: { id }, data: dto });
    }
    async removeUstadz(tenantId, id) {
        const found = await this.prisma.ustadz.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Ustadz tidak ditemukan.');
        await this.prisma.ustadz.delete({ where: { id } });
        return { message: 'Ustadz dihapus.' };
    }
    findAllKelas(tenantId) {
        return this.prisma.kelas.findMany({
            where: { tenantId },
            include: {
                waliKelas: { select: { id: true, nama: true } },
                tahunAjaran: { select: { id: true, nama: true } },
                _count: { select: { santris: true } },
            },
            orderBy: { tingkat: 'asc' },
        });
    }
    createKelas(tenantId, dto) {
        return this.prisma.kelas.create({
            data: { tenantId, ...dto },
        });
    }
    async updateKelas(tenantId, id, dto) {
        const found = await this.prisma.kelas.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Kelas tidak ditemukan.');
        return this.prisma.kelas.update({ where: { id }, data: dto });
    }
    async removeKelas(tenantId, id) {
        const found = await this.prisma.kelas.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Kelas tidak ditemukan.');
        await this.prisma.kelas.delete({ where: { id } });
        return { message: 'Kelas dihapus.' };
    }
    findAllMapel(tenantId) {
        return this.prisma.mataPelajaran.findMany({
            where: { tenantId },
            orderBy: { namaMapel: 'asc' },
        });
    }
    createMapel(tenantId, dto) {
        return this.prisma.mataPelajaran.create({ data: { tenantId, ...dto } });
    }
    async updateMapel(tenantId, id, dto) {
        const found = await this.prisma.mataPelajaran.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Mapel tidak ditemukan.');
        return this.prisma.mataPelajaran.update({ where: { id }, data: dto });
    }
    async removeMapel(tenantId, id) {
        const found = await this.prisma.mataPelajaran.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Mapel tidak ditemukan.');
        await this.prisma.mataPelajaran.delete({ where: { id } });
        return { message: 'Mapel dihapus.' };
    }
    findAllTahunAjaran(tenantId) {
        return this.prisma.tahunAjaran.findMany({
            where: { tenantId },
            orderBy: { nama: 'desc' },
        });
    }
    createTahunAjaran(tenantId, dto) {
        return this.prisma.tahunAjaran.create({ data: { tenantId, ...dto } });
    }
    async setTahunAjaranAktif(tenantId, id) {
        await this.prisma.$transaction([
            this.prisma.tahunAjaran.updateMany({
                where: { tenantId },
                data: { aktif: false },
            }),
            this.prisma.tahunAjaran.update({
                where: { id },
                data: { aktif: true },
            }),
        ]);
        return { message: 'Tahun ajaran aktif diperbarui.' };
    }
};
exports.MasterDataService = MasterDataService;
exports.MasterDataService = MasterDataService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], MasterDataService);
//# sourceMappingURL=master-data.service.js.map