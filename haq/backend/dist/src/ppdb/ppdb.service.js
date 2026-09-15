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
exports.PpdbService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const client_1 = require("@prisma/client");
let PpdbService = class PpdbService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async daftar(dto) {
        const tenant = await this.prisma.tenant.findUnique({
            where: { kodeTenant: dto.kodeTenant },
        });
        if (!tenant) {
            throw new common_1.NotFoundException('Pondok dengan kode tersebut tidak ditemukan. Periksa kembali kode PPDB.');
        }
        if (tenant.status !== 'AKTIF') {
            throw new common_1.BadRequestException('Pondok ini belum membuka PPDB online.');
        }
        const pendaftaran = await this.prisma.pendaftaran.create({
            data: {
                tenantId: tenant.id,
                nama: dto.nama,
                jenisKelamin: dto.jenisKelamin,
                tanggalLahir: dto.tanggalLahir ? new Date(dto.tanggalLahir) : null,
                asalSekolah: dto.asalSekolah,
                noHp: dto.noHp,
                email: dto.email,
                alamat: dto.alamat,
                jalur: dto.jalur,
            },
        });
        await this.prisma.notifikasi.create({
            data: {
                tenantId: tenant.id,
                jenis: 'SISTEM',
                pesan: `Pendaftar baru PPDB: ${dto.nama}. Segera tinjau di menu PPDB.`,
            },
        });
        return {
            id: pendaftaran.id,
            noPendaftaran: this.noPendaftaran(tenant.kodeTenant, pendaftaran.id),
            nama: pendaftaran.nama,
            status: pendaftaran.status,
            message: 'Pendaftaran berhasil dikirim. Panitia pondok akan meninjau dan menghubungi Anda.',
        };
    }
    async lookup(kodeTenant) {
        const tenant = await this.prisma.tenant.findUnique({
            where: { kodeTenant },
            select: {
                id: true,
                namaPondok: true,
                kodeTenant: true,
                logoUrl: true,
                status: true,
                kuotaSantriPpdb: true,
                statusGelombangPpdb: true,
            },
        });
        if (!tenant) {
            throw new common_1.NotFoundException('Pondok dengan kode tersebut tidak ditemukan. Periksa kembali kode PPDB.');
        }
        if (tenant.status !== 'AKTIF') {
            throw new common_1.BadRequestException('Pondok ini belum membuka PPDB online.');
        }
        const jumlahDiterima = await this.prisma.pendaftaran.count({
            where: { tenantId: tenant.id, status: client_1.StatusPendaftaran.DITERIMA },
        });
        const sisaKuota = tenant.kuotaSantriPpdb != null
            ? Math.max(tenant.kuotaSantriPpdb - jumlahDiterima, 0)
            : null;
        return {
            namaPondok: tenant.namaPondok,
            kodeTenant: tenant.kodeTenant,
            logoUrl: tenant.logoUrl,
            gelombang: {
                status: tenant.statusGelombangPpdb,
                kuota: tenant.kuotaSantriPpdb,
                sisaKuota,
            },
        };
    }
    async findAll(tenantId, q) {
        const where = { tenantId };
        if (q.status)
            where.status = q.status;
        if (q.q) {
            where.OR = [
                { nama: { contains: q.q } },
                { email: { contains: q.q } },
                { noHp: { contains: q.q } },
            ];
        }
        const list = await this.prisma.pendaftaran.findMany({
            where,
            orderBy: { tanggalDaftar: 'desc' },
            include: { ujian: true },
        });
        return list.map((p) => ({ ...p, noPendaftaran: this.noPendaftaranLabel(p.id) }));
    }
    async findOne(tenantId, id) {
        const p = await this.prisma.pendaftaran.findFirst({
            where: { id, tenantId },
            include: { ujian: true },
        });
        if (!p)
            throw new common_1.NotFoundException('Pendaftaran tidak ditemukan.');
        return p;
    }
    async updateStatus(tenantId, id, dto) {
        const p = await this.prisma.pendaftaran.findFirst({
            where: { id, tenantId },
            include: { tenant: true },
        });
        if (!p)
            throw new common_1.NotFoundException('Pendaftaran tidak ditemukan.');
        const nextStatus = dto.status ?? p.status;
        const updated = await this.prisma.pendaftaran.update({
            where: { id },
            data: { status: nextStatus, catatan: dto.catatan ?? p.catatan },
        });
        if (nextStatus === client_1.StatusPendaftaran.DITERIMA) {
            await this.createSantriDariPendaftaran(p);
        }
        if (nextStatus === client_1.StatusPendaftaran.DITERIMA || nextStatus === client_1.StatusPendaftaran.DITOLAK) {
            await this.prisma.notifikasi.create({
                data: {
                    tenantId,
                    jenis: 'SISTEM',
                    pesan: nextStatus === client_1.StatusPendaftaran.DITERIMA
                        ? `Selamat, ${p.nama} dinyatakan DITERIMA.`
                        : `Kami mohon maaf, ${p.nama} belum diterima.`,
                },
            });
        }
        return { ...updated, message: 'Status pendaftaran diperbarui.' };
    }
    async createSantriDariPendaftaran(p) {
        const tahun = new Date().getFullYear();
        const jumlah = await this.prisma.santri.count({
            where: { tenantId: p.tenantId, tahunMasuk: tahun },
        });
        const nis = `${tahun}${String(jumlah + 1).padStart(4, '0')}`;
        const nisExists = await this.prisma.santri.findUnique({
            where: { tenantId_nis: { tenantId: p.tenantId, nis } },
        });
        if (nisExists) {
            throw new common_1.ConflictException('Gagal membuat NIS. Coba lagi.');
        }
        return this.prisma.santri.create({
            data: {
                tenantId: p.tenantId,
                nis,
                nama: p.nama,
                jenisKelamin: p.jenisKelamin,
                tanggalLahir: p.tanggalLahir ?? null,
                tahunMasuk: tahun,
            },
        });
    }
    noPendaftaranLabel(id) {
        return `PPDB-${id.slice(-6).toUpperCase()}`;
    }
    noPendaftaran(kodeTenant, id) {
        return `PPDB-${kodeTenant.toUpperCase()}-${id.slice(-6).toUpperCase()}`;
    }
    async createPlacementTest(tenantId, pendaftaranId, dto) {
        const p = await this.prisma.pendaftaran.findFirst({
            where: { id: pendaftaranId, tenantId },
        });
        if (!p)
            throw new common_1.NotFoundException('Pendaftaran tidak ditemukan.');
        const existing = await this.prisma.placementTest.findUnique({
            where: { pendaftaranId },
        });
        if (existing) {
            throw new common_1.ConflictException('Placement test untuk pendaftar ini sudah ada.');
        }
        return this.prisma.placementTest.create({
            data: {
                tenantId,
                pendaftaranId,
                mapelId: dto.mapelId,
                nilai: dto.nilai,
                hasil: dto.hasil,
                catatan: dto.catatan,
                tanggal: dto.tanggal ? new Date(dto.tanggal) : new Date(),
            },
        });
    }
    async getPlacementTest(tenantId, pendaftaranId) {
        const test = await this.prisma.placementTest.findFirst({
            where: { pendaftaranId, tenantId },
        });
        if (!test)
            throw new common_1.NotFoundException('Placement test belum diisi.');
        return test;
    }
    async updatePlacementTest(tenantId, pendaftaranId, dto) {
        const test = await this.prisma.placementTest.findFirst({
            where: { pendaftaranId, tenantId },
        });
        if (!test)
            throw new common_1.NotFoundException('Placement test belum diisi.');
        return this.prisma.placementTest.update({
            where: { id: test.id },
            data: {
                mapelId: dto.mapelId ?? test.mapelId,
                nilai: dto.nilai ?? test.nilai,
                hasil: dto.hasil ?? test.hasil,
                catatan: dto.catatan ?? test.catatan,
                tanggal: dto.tanggal ? new Date(dto.tanggal) : test.tanggal,
            },
        });
    }
};
exports.PpdbService = PpdbService;
exports.PpdbService = PpdbService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], PpdbService);
//# sourceMappingURL=ppdb.service.js.map