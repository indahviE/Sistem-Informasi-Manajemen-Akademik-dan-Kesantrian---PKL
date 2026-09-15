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
exports.AkademikService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
let AkademikService = class AkademikService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    assertSantri(tenantId, santriId) {
        return this.prisma.santri.findFirst({ where: { id: santriId, tenantId } });
    }
    async findAllAbsensi(tenantId, query) {
        const where = {
            tenantId,
            ...(query.santriId ? { santriId: query.santriId } : {}),
            ...(query.kelasId ? { santri: { kelasId: query.kelasId } } : {}),
            ...(query.startDate || query.endDate
                ? {
                    tanggal: {
                        ...(query.startDate ? { gte: new Date(query.startDate) } : {}),
                        ...(query.endDate ? { lte: new Date(query.endDate) } : {}),
                    },
                }
                : {}),
        };
        return this.prisma.absensi.findMany({
            where,
            include: {
                santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } },
                mapel: { select: { id: true, namaMapel: true } },
            },
            orderBy: { tanggal: 'desc' },
        });
    }
    async createAbsensi(tenantId, dto, user) {
        await this.assertSantriInTenant(tenantId, dto.santriId);
        return this.prisma.absensi.create({
            data: {
                tenantId,
                santriId: dto.santriId,
                kelasId: dto.kelasId,
                mapelId: dto.mapelId,
                tanggal: new Date(dto.tanggal),
                status: dto.status,
                catatan: dto.catatan,
                inputOleh: user.userId,
            },
        });
    }
    async bulkAbsensi(tenantId, dto, user) {
        const tanggal = new Date(dto.tanggal);
        const results = [];
        for (const item of dto.items) {
            await this.assertSantriInTenant(tenantId, item.santriId);
            const existing = await this.prisma.absensi.findFirst({
                where: {
                    tenantId,
                    santriId: item.santriId,
                    mapelId: dto.mapelId ?? null,
                    tanggal,
                },
            });
            if (existing) {
                results.push(await this.prisma.absensi.update({
                    where: { id: existing.id },
                    data: { status: item.status, catatan: item.catatan, inputOleh: user.userId },
                }));
            }
            else {
                results.push(await this.prisma.absensi.create({
                    data: {
                        tenantId,
                        santriId: item.santriId,
                        kelasId: dto.kelasId,
                        mapelId: dto.mapelId,
                        tanggal,
                        status: item.status,
                        catatan: item.catatan,
                        inputOleh: user.userId,
                    },
                }));
            }
        }
        return { count: results.length, message: 'Absensi massal disimpan.' };
    }
    async findAllNilai(tenantId, santriId, mapelId, jenis, allowedSantriIds) {
        const santriFilter = allowedSantriIds
            ? santriId
                ? { santriId }
                : { santriId: { in: allowedSantriIds } }
            : santriId
                ? { santriId }
                : {};
        return this.prisma.nilai.findMany({
            where: {
                tenantId,
                ...santriFilter,
                ...(mapelId ? { mapelId } : {}),
                ...(jenis ? { jenis } : {}),
            },
            include: {
                santri: { select: { id: true, nama: true, nis: true } },
                mapel: { select: { id: true, namaMapel: true } },
            },
            orderBy: { tanggal: 'desc' },
        });
    }
    async createNilai(tenantId, dto, user) {
        await this.assertSantriInTenant(tenantId, dto.santriId);
        return this.prisma.nilai.create({
            data: {
                tenantId,
                santriId: dto.santriId,
                mapelId: dto.mapelId,
                jenis: dto.jenis,
                nilai: dto.nilai,
                keterangan: dto.keterangan,
                tanggal: new Date(dto.tanggal),
                inputOleh: user.userId,
            },
        });
    }
    async findAllTahfidz(tenantId, santriId, allowedSantriIds) {
        const santriFilter = allowedSantriIds
            ? santriId
                ? { santriId }
                : { santriId: { in: allowedSantriIds } }
            : santriId
                ? { santriId }
                : {};
        return this.prisma.capaianTahfidz.findMany({
            where: { tenantId, ...santriFilter },
            include: { santri: { select: { id: true, nama: true, nis: true } } },
            orderBy: { tanggalSetor: 'desc' },
        });
    }
    async createTahfidz(tenantId, dto, user) {
        await this.assertSantriInTenant(tenantId, dto.santriId);
        return this.prisma.capaianTahfidz.create({
            data: {
                tenantId,
                santriId: dto.santriId,
                juz: dto.juz,
                halaman: dto.halaman,
                catatanUstadz: dto.catatanUstadz,
                tanggalSetor: new Date(dto.tanggalSetor),
                inputOleh: user.userId,
            },
        });
    }
    async assertSantriInTenant(tenantId, santriId) {
        const found = await this.assertSantri(tenantId, santriId);
        if (!found)
            throw new common_1.NotFoundException('Santri tidak ditemukan di pondok ini.');
        return found;
    }
};
exports.AkademikService = AkademikService;
exports.AkademikService = AkademikService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], AkademikService);
//# sourceMappingURL=akademik.service.js.map