"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.TenantsService = void 0;
const common_1 = require("@nestjs/common");
const bcrypt = __importStar(require("bcryptjs"));
const prisma_service_1 = require("../prisma/prisma.service");
const client_1 = require("@prisma/client");
let TenantsService = class TenantsService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async signup(dto) {
        const existing = await this.prisma.tenant.findUnique({
            where: { kodeTenant: dto.kodeTenant },
        });
        if (existing) {
            throw new common_1.ConflictException('Kode tenant sudah dipakai. Pilih kode lain.');
        }
        const emailExists = await this.prisma.user.findFirst({
            where: { email: dto.adminEmail },
        });
        if (emailExists) {
            throw new common_1.ConflictException('Email admin sudah terdaftar di platform ini.');
        }
        const passwordHash = await bcrypt.hash(dto.adminPassword, 10);
        return this.prisma.$transaction(async (tx) => {
            const tenant = await tx.tenant.create({
                data: {
                    kodeTenant: dto.kodeTenant,
                    namaPondok: dto.namaPondok,
                    logoUrl: dto.logoUrl,
                    status: client_1.TenantStatus.PENDING,
                },
            });
            const admin = await tx.user.create({
                data: {
                    tenantId: tenant.id,
                    nama: dto.adminNama,
                    email: dto.adminEmail,
                    passwordHash,
                    role: client_1.Role.ADMIN,
                },
            });
            await tx.tenant.update({
                where: { id: tenant.id },
                data: { adminAwalId: admin.id },
            });
            await tx.tahunAjaran.create({
                data: { tenantId: tenant.id, nama: '2026/2027', aktif: true },
            });
            return {
                id: tenant.id,
                namaPondok: tenant.namaPondok,
                kodeTenant: tenant.kodeTenant,
                status: tenant.status,
                message: 'Pendaftaran berhasil. Menunggu persetujuan Super Admin sebelum bisa digunakan.',
            };
        });
    }
    async findAll(status) {
        const tenants = await this.prisma.tenant.findMany({
            where: status ? { status } : {},
            orderBy: { tanggalDaftar: 'desc' },
            include: {
                _count: { select: { users: true, santris: true, kelas: true } },
            },
        });
        return tenants.map((t) => ({
            ...t,
            jumlahUser: t._count.users,
            jumlahSantri: t._count.santris,
            jumlahKelas: t._count.kelas,
        }));
    }
    async approve(tenantId) {
        const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
        if (!tenant)
            throw new common_1.NotFoundException('Tenant tidak ditemukan.');
        await this.prisma.tenant.update({
            where: { id: tenantId },
            data: { status: client_1.TenantStatus.AKTIF },
        });
        await this.prisma.notifikasi.create({
            data: {
                tenantId,
                jenis: 'SISTEM',
                pesan: `Pondok "${tenant.namaPondok}" telah diaktifkan. Admin dapat login dan mulai setup data.`,
            },
        });
        return { message: 'Tenant berhasil diaktifkan.', id: tenantId };
    }
    async suspend(tenantId) {
        const tenant = await this.prisma.tenant.findUnique({ where: { id: tenantId } });
        if (!tenant)
            throw new common_1.NotFoundException('Tenant tidak ditemukan.');
        await this.prisma.tenant.update({
            where: { id: tenantId },
            data: { status: client_1.TenantStatus.SUSPENDED },
        });
        return { message: 'Tenant di-suspend.' };
    }
    async getByTenantId(tenantId) {
        const tenant = await this.prisma.tenant.findUnique({
            where: { id: tenantId },
            include: {
                _count: { select: { users: true, santris: true, kelas: true, ustadzs: true } },
            },
        });
        if (!tenant)
            throw new common_1.NotFoundException('Tenant tidak ditemukan.');
        return tenant;
    }
    async getBranding(kodeTenant) {
        if (!kodeTenant)
            throw new common_1.BadRequestException('Parameter kodeTenant wajib diisi.');
        const tenant = await this.prisma.tenant.findUnique({
            where: { kodeTenant },
            select: {
                kodeTenant: true,
                namaPondok: true,
                logoUrl: true,
                warnaTema: true,
                status: true,
            },
        });
        if (!tenant)
            throw new common_1.NotFoundException('Pondok dengan kode tersebut tidak ditemukan.');
        return tenant;
    }
    async getMyBranding(tenantId) {
        const tenant = await this.prisma.tenant.findUnique({
            where: { id: tenantId },
            select: {
                id: true,
                kodeTenant: true,
                namaPondok: true,
                logoUrl: true,
                warnaTema: true,
                status: true,
                tanggalDaftar: true,
            },
        });
        if (!tenant)
            throw new common_1.NotFoundException('Tenant tidak ditemukan.');
        return tenant;
    }
    async updateBranding(tenantId, dto) {
        return this.prisma.tenant.update({
            where: { id: tenantId },
            data: dto,
            select: {
                id: true,
                namaPondok: true,
                logoUrl: true,
                warnaTema: true,
            },
        });
    }
};
exports.TenantsService = TenantsService;
exports.TenantsService = TenantsService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], TenantsService);
//# sourceMappingURL=tenants.service.js.map