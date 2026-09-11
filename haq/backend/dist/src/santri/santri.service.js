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
exports.SantriService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let SantriService = class SantriService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAll(tenantId, query) {
        const { kelasId, search, page = 1, perPage = 20 } = query;
        const where = {
            tenantId,
            ...(kelasId ? { kelasId } : {}),
            ...(search
                ? { OR: [{ nama: { contains: search } }, { nis: { contains: search } }] }
                : {}),
        };
        const [items, total] = await this.prisma.$transaction([
            this.prisma.santri.findMany({
                where,
                include: {
                    kelas: { select: { id: true, namaKelas: true } },
                    wali: { select: { id: true, nama: true, noHp: true } },
                },
                orderBy: { nama: 'asc' },
                skip: (page - 1) * perPage,
                take: perPage,
            }),
            this.prisma.santri.count({ where }),
        ]);
        return { items, total, page, perPage };
    }
    async findOne(tenantId, id) {
        const santri = await this.prisma.santri.findFirst({
            where: { id, tenantId },
            include: {
                kelas: true,
                wali: true,
                capaianTahfidzs: { orderBy: { tanggalSetor: 'desc' }, take: 10 },
                pelanggarans: { orderBy: { tanggal: 'desc' }, take: 10 },
            },
        });
        if (!santri)
            throw new common_1.NotFoundException('Santri tidak ditemukan.');
        return santri;
    }
    create(tenantId, dto) {
        return this.prisma.santri.create({
            data: {
                tenantId,
                nis: dto.nis,
                nama: dto.nama,
                jenisKelamin: dto.jenisKelamin,
                tanggalLahir: dto.tanggalLahir ? new Date(dto.tanggalLahir) : undefined,
                kelasId: dto.kelasId,
                asrama: dto.asrama,
                waliId: dto.waliId,
                tahunMasuk: dto.tahunMasuk,
            },
        });
    }
    async update(tenantId, id, dto) {
        const existing = await this.prisma.santri.findFirst({ where: { id, tenantId } });
        if (!existing)
            throw new common_1.NotFoundException('Santri tidak ditemukan.');
        return this.prisma.santri.update({
            where: { id },
            data: {
                nama: dto.nama,
                jenisKelamin: dto.jenisKelamin,
                tanggalLahir: dto.tanggalLahir ? new Date(dto.tanggalLahir) : undefined,
                kelasId: dto.kelasId,
                asrama: dto.asrama,
                waliId: dto.waliId,
            },
        });
    }
    async remove(tenantId, id) {
        const existing = await this.prisma.santri.findFirst({ where: { id, tenantId } });
        if (!existing)
            throw new common_1.NotFoundException('Santri tidak ditemukan.');
        await this.prisma.santri.delete({ where: { id } });
        return { message: 'Santri dihapus.' };
    }
};
exports.SantriService = SantriService;
exports.SantriService = SantriService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], SantriService);
//# sourceMappingURL=santri.service.js.map