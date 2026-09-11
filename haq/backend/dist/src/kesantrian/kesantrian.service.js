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
exports.KesantrianService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const client_1 = require("@prisma/client");
let KesantrianService = class KesantrianService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async assertSantri(tenantId, santriId) {
        const found = await this.prisma.santri.findFirst({ where: { id: santriId, tenantId }, include: { wali: true } });
        if (!found)
            throw new common_1.NotFoundException('Santri tidak ditemukan di pondok ini.');
        return found;
    }
    async notifyWali(tenantId, wali, jenis, pesan) {
        if (!wali)
            return;
        const waliUser = await this.prisma.waliSantri.findFirst({
            where: { id: wali.id },
            include: { user: true },
        });
        const userIds = waliUser?.user ? [waliUser.user.id] : [];
        for (const userId of userIds) {
            await this.prisma.notifikasi.create({ data: { tenantId, userId, jenis, pesan } });
        }
    }
    async findAllPelanggaran(tenantId, query) {
        return this.prisma.pelanggaran.findMany({
            where: {
                tenantId,
                ...(query.santriId ? { santriId: query.santriId } : {}),
                ...(query.kelasId ? { santri: { kelasId: query.kelasId } } : {}),
            },
            include: {
                santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } },
            },
            orderBy: { tanggal: 'desc' },
        });
    }
    async createPelanggaran(tenantId, dto, user) {
        const santri = await this.assertSantri(tenantId, dto.santriId);
        const created = await this.prisma.pelanggaran.create({
            data: {
                tenantId,
                santriId: dto.santriId,
                jenisPelanggaran: dto.jenisPelanggaran,
                poin: dto.poin,
                tanggal: new Date(dto.tanggal),
                pelaporId: user.userId,
                tindakLanjut: dto.tindakLanjut,
            },
        });
        await this.notifyWali(tenantId, santri.wali, client_1.JenisNotifikasi.PELANGGARAN, `${santri.nama} tercatat pelanggaran: ${dto.jenisPelanggaran} (${dto.poin} poin).`);
        return created;
    }
    async updatePelanggaran(tenantId, id, dto) {
        const found = await this.prisma.pelanggaran.findFirst({ where: { id, tenantId } });
        if (!found)
            throw new common_1.NotFoundException('Pelanggaran tidak ditemukan.');
        return this.prisma.pelanggaran.update({ where: { id }, data: dto });
    }
    async findAllPerizinan(tenantId, query) {
        return this.prisma.perizinan.findMany({
            where: {
                tenantId,
                ...(query.santriId ? { santriId: query.santriId } : {}),
            },
            include: {
                santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } },
            },
            orderBy: { tanggalKeluar: 'desc' },
        });
    }
    async createPerizinan(tenantId, dto, user) {
        const santri = await this.assertSantri(tenantId, dto.santriId);
        const created = await this.prisma.perizinan.create({
            data: {
                tenantId,
                santriId: dto.santriId,
                jenis: dto.jenis,
                tanggalKeluar: new Date(dto.tanggalKeluar),
                tanggalKembali: dto.tanggalKembali ? new Date(dto.tanggalKembali) : null,
                alasan: dto.alasan,
                catatan: dto.catatan,
            },
        });
        await this.notifyWali(tenantId, santri.wali, client_1.JenisNotifikasi.PERIZINAN, `${santri.nama} mengajukan izin ${dto.jenis === 'PULANG' ? 'pulang' : 'keluar'} dengan alasan: ${dto.alasan}.`);
        return created;
    }
    async updatePerizinan(tenantId, id, dto, user) {
        const found = await this.prisma.perizinan.findFirst({
            where: { id, tenantId },
            include: { santri: { include: { wali: true } } },
        });
        if (!found)
            throw new common_1.NotFoundException('Perizinan tidak ditemukan.');
        let tanggalKembali = dto.tanggalKembali ? new Date(dto.tanggalKembali) : found.tanggalKembali;
        let statusApproval = dto.statusApproval;
        if (statusApproval === 'KEMBALI' && tanggalKembali && found.tanggalKeluar) {
            const telat = tanggalKembali > found.tanggalKeluar && found.jenis === 'PULANG';
            if (telat) {
                statusApproval = 'TELAT';
            }
        }
        const updated = await this.prisma.perizinan.update({
            where: { id },
            data: {
                statusApproval,
                tanggalKembali,
                disetujuiOleh: dto.disetujuiOleh || user.userId,
                catatan: dto.catatan,
            },
        });
        await this.notifyWali(tenantId, found.santri.wali, client_1.JenisNotifikasi.PERIZINAN, `Status izin ${found.santri.nama} diperbarui menjadi ${statusApproval}.`);
        return updated;
    }
    async findAllKesehatan(tenantId, query) {
        return this.prisma.kesehatanLog.findMany({
            where: {
                tenantId,
                ...(query.santriId ? { santriId: query.santriId } : {}),
                ...(query.kelasId ? { santri: { kelasId: query.kelasId } } : {}),
            },
            include: { santri: { select: { id: true, nama: true, nis: true, kelas: { select: { namaKelas: true } } } } },
            orderBy: { tanggal: 'desc' },
        });
    }
    async createKesehatan(tenantId, dto, user) {
        const santri = await this.assertSantri(tenantId, dto.santriId);
        const created = await this.prisma.kesehatanLog.create({
            data: {
                tenantId,
                santriId: dto.santriId,
                keluhan: dto.keluhan,
                diagnosa: dto.diagnosa,
                tindakan: dto.tindakan,
                obat: dto.obat,
                tempat: dto.tempat ?? 'UKS',
                tanggal: new Date(dto.tanggal),
                status: dto.status ?? 'RAWAT_JALAN',
                inputOleh: user.userId,
            },
        });
        await this.notifyWali(tenantId, santri.wali, client_1.JenisNotifikasi.KESEHATAN, `${santri.nama} sedang sakit: ${dto.keluhan}.`);
        return created;
    }
    async findAllKunjungan(tenantId, query) {
        return this.prisma.kunjunganWali.findMany({
            where: {
                tenantId,
                ...(query.santriId ? { santriId: query.santriId } : {}),
            },
            include: {
                santri: { select: { id: true, nama: true, nis: true } },
                wali: { select: { id: true, nama: true, hubungan: true } },
            },
            orderBy: { tanggal: 'desc' },
        });
    }
    async createKunjungan(tenantId, dto) {
        await this.assertSantri(tenantId, dto.santriId);
        return this.prisma.kunjunganWali.create({
            data: {
                tenantId,
                santriId: dto.santriId,
                waliId: dto.waliId,
                tanggal: new Date(dto.tanggal),
                catatan: dto.catatan,
            },
        });
    }
    async findAllTataTertib(tenantId) {
        return this.prisma.tataTertib.findMany({
            where: { tenantId, aktif: true },
            orderBy: { createdAt: 'desc' },
        });
    }
    async createTataTertib(tenantId, dto) {
        return this.prisma.tataTertib.create({
            data: { tenantId, judul: dto.judul, isi: dto.isi },
        });
    }
    async getRekamMedis(tenantId, santriId) {
        await this.assertSantri(tenantId, santriId);
        const rekam = await this.prisma.rekamMedis.findFirst({
            where: { santriId, tenantId },
        });
        if (!rekam) {
            return {
                santriId,
                golonganDarah: null,
                alergi: null,
                riwayatPenyakit: null,
                tinggiBadan: null,
                beratBadan: null,
                catatanKhusus: null,
                kosong: true,
            };
        }
        return rekam;
    }
    async upsertRekamMedis(tenantId, santriId, dto) {
        await this.assertSantri(tenantId, santriId);
        const data = {
            golonganDarah: dto.golonganDarah ?? null,
            alergi: dto.alergi ?? null,
            riwayatPenyakit: dto.riwayatPenyakit ?? null,
            tinggiBadan: dto.tinggiBadan != null ? Number(dto.tinggiBadan) : null,
            beratBadan: dto.beratBadan != null ? Number(dto.beratBadan) : null,
            catatanKhusus: dto.catatanKhusus ?? null,
        };
        return this.prisma.rekamMedis.upsert({
            where: { santriId },
            create: { tenantId, santriId, ...data },
            update: data,
        });
    }
};
exports.KesantrianService = KesantrianService;
exports.KesantrianService = KesantrianService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], KesantrianService);
//# sourceMappingURL=kesantrian.service.js.map