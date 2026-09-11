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
exports.BillingService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const client_1 = require("@prisma/client");
let BillingService = class BillingService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async findAllPaket() {
        return this.prisma.paket.findMany({ orderBy: { harga: 'asc' } });
    }
    async createPaket(dto) {
        return this.prisma.paket.create({
            data: { nama: dto.nama, harga: dto.harga, limitSantri: dto.limitSantri, fitur: dto.fitur },
        });
    }
    async updatePaket(id, dto) {
        const exist = await this.prisma.paket.findUnique({ where: { id } });
        if (!exist)
            throw new common_1.NotFoundException('Paket tidak ditemukan.');
        return this.prisma.paket.update({ where: { id }, data: dto });
    }
    async removePaket(id) {
        const exist = await this.prisma.paket.findUnique({ where: { id } });
        if (!exist)
            throw new common_1.NotFoundException('Paket tidak ditemukan.');
        return this.prisma.paket.delete({ where: { id } });
    }
    async findAllSubscription(isSuperAdmin, tenantId) {
        return this.prisma.subscription.findMany({
            where: isSuperAdmin ? {} : { tenantId },
            orderBy: { tanggalMulai: 'desc' },
            include: { tenant: { select: { namaPondok: true, kodeTenant: true } }, paket: true },
        });
    }
    async assignSubscription(dto) {
        const tenant = await this.prisma.tenant.findUnique({ where: { id: dto.tenantId } });
        if (!tenant)
            throw new common_1.NotFoundException('Tenant tidak ditemukan.');
        const paket = await this.prisma.paket.findUnique({ where: { id: dto.paketId } });
        if (!paket)
            throw new common_1.NotFoundException('Paket tidak ditemukan.');
        await this.prisma.subscription.updateMany({
            where: { tenantId: dto.tenantId, status: client_1.StatusSubscription.AKTIF },
            data: { status: client_1.StatusSubscription.EXPIRED },
        });
        return this.prisma.subscription.create({
            data: {
                tenantId: dto.tenantId,
                paketId: dto.paketId,
                tanggalAkhir: new Date(new Date().setFullYear(new Date().getFullYear() + 1)),
            },
        });
    }
    async updateSubscription(id, dto) {
        const exist = await this.prisma.subscription.findUnique({ where: { id } });
        if (!exist)
            throw new common_1.NotFoundException('Subscription tidak ditemukan.');
        return this.prisma.subscription.update({ where: { id }, data: dto });
    }
    async findAllInvoice(isSuperAdmin, tenantId) {
        return this.prisma.invoice.findMany({
            where: isSuperAdmin ? {} : { tenantId },
            orderBy: { createdAt: 'desc' },
            include: { tenant: { select: { namaPondok: true, kodeTenant: true } } },
        });
    }
    async createInvoice(dto) {
        const tenant = await this.prisma.tenant.findUnique({ where: { id: dto.tenantId } });
        if (!tenant)
            throw new common_1.NotFoundException('Tenant tidak ditemukan.');
        const count = await this.prisma.invoice.count({ where: { tenantId: dto.tenantId } });
        const noInvoice = `INV-${tenant.kodeTenant.toUpperCase()}-${String(count + 1).padStart(4, '0')}`;
        return this.prisma.invoice.create({
            data: {
                tenantId: dto.tenantId,
                noInvoice,
                jumlah: dto.jumlah,
                metodeBayar: dto.metodeBayar,
                tanggalJatuhTempo: new Date(new Date().setDate(new Date().getDate() + 30)),
            },
        });
    }
    async updateInvoice(id, dto) {
        const exist = await this.prisma.invoice.findUnique({ where: { id } });
        if (!exist)
            throw new common_1.NotFoundException('Invoice tidak ditemukan.');
        const data = {};
        if (dto.status)
            data.status = dto.status;
        if (dto.status === client_1.StatusInvoice.LUNAS)
            data.tanggalBayar = new Date();
        if (dto.metodeBayar)
            data.metodeBayar = dto.metodeBayar;
        return this.prisma.invoice.update({ where: { id }, data });
    }
};
exports.BillingService = BillingService;
exports.BillingService = BillingService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], BillingService);
//# sourceMappingURL=billing.service.js.map