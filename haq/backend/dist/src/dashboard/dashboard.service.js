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
exports.DashboardService = void 0;
const common_1 = require("@nestjs/common");
const prisma_service_1 = require("../prisma/prisma.service");
const client_1 = require("@prisma/client");
let DashboardService = class DashboardService {
    constructor(prisma) {
        this.prisma = prisma;
    }
    async getDashboard(user) {
        if (user.role === client_1.Role.SUPER_ADMIN) {
            return this.superAdminDashboard();
        }
        if (user.role === client_1.Role.WALI_SANTRI) {
            return this.waliDashboard(user.userId, user.tenantId);
        }
        return this.tenantDashboard(user.tenantId);
    }
    async superAdminDashboard() {
        const [totalTenant, tenantAktif, tenantPending, totalUser, totalSantri] = await this.prisma.$transaction([
            this.prisma.tenant.count(),
            this.prisma.tenant.count({ where: { status: 'AKTIF' } }),
            this.prisma.tenant.count({ where: { status: 'PENDING' } }),
            this.prisma.user.count({ where: { role: { not: client_1.Role.SUPER_ADMIN } } }),
            this.prisma.santri.count(),
        ]);
        const recentTenants = await this.prisma.tenant.findMany({
            orderBy: { tanggalDaftar: 'desc' },
            take: 10,
            include: { _count: { select: { users: true, santris: true } } },
        });
        return {
            role: 'SUPER_ADMIN',
            statistik: { totalTenant, tenantAktif, tenantPending, totalUser, totalSantri },
            tenantTerbaru: recentTenants,
        };
    }
    async tenantDashboard(tenantId) {
        const todayStart = new Date();
        todayStart.setHours(0, 0, 0, 0);
        const todayEnd = new Date();
        todayEnd.setHours(23, 59, 59, 999);
        const weekStart = new Date();
        weekStart.setDate(weekStart.getDate() - 7);
        const [totalSantri, santriAktif, totalKelas, totalUstadz, hadirHariIni, pelanggaranMingguIni, izinPending, santriSakit,] = await this.prisma.$transaction([
            this.prisma.santri.count({ where: { tenantId } }),
            this.prisma.santri.count({ where: { tenantId, status: 'AKTIF' } }),
            this.prisma.kelas.count({ where: { tenantId } }),
            this.prisma.ustadz.count({ where: { tenantId } }),
            this.prisma.absensi.count({
                where: { tenantId, status: 'HADIR', tanggal: { gte: todayStart, lte: todayEnd } },
            }),
            this.prisma.pelanggaran.count({
                where: { tenantId, tanggal: { gte: weekStart } },
            }),
            this.prisma.perizinan.count({ where: { tenantId, statusApproval: 'DIAJUKAN' } }),
            this.prisma.kesehatanLog.count({
                where: {
                    tenantId,
                    tanggal: { gte: weekStart },
                    status: { in: ['RAWAT_JALAN', 'DIRUJUK'] },
                },
            }),
        ]);
        const distribusiKelas = await this.prisma.kelas.findMany({
            where: { tenantId },
            include: { _count: { select: { santris: true } } },
        });
        const pelanggaranPerHari = await this.prisma.pelanggaran.groupBy({
            by: ['tanggal'],
            where: { tenantId, tanggal: { gte: weekStart } },
            _count: true,
            orderBy: { tanggal: 'asc' },
        });
        return {
            role: 'TENANT',
            statistik: {
                totalSantri,
                santriAktif,
                totalKelas,
                totalUstadz,
                hadirHariIni,
                pelanggaranMingguIni,
                izinPending,
                santriSakit,
            },
            distribusiKelas,
            pelanggaranPerHari,
        };
    }
    async waliDashboard(userId, tenantId) {
        const wali = await this.prisma.waliSantri.findFirst({
            where: { userId, ...(tenantId ? { tenantId } : {}) },
            include: {
                santris: {
                    include: { kelas: { select: { namaKelas: true } } },
                },
            },
        });
        if (!wali || wali.santris.length === 0) {
            return { role: 'WALI_SANTRI', statistik: {}, anak: [], pesan: 'Belum ada data anak.' };
        }
        const anakIds = wali.santris.map((s) => s.id);
        const [pelanggaranTotal, izinPending, kehadiranBulanIni, rataRataNilai,] = await this.prisma.$transaction([
            this.prisma.pelanggaran.count({ where: { santriId: { in: anakIds } } }),
            this.prisma.perizinan.count({
                where: { santriId: { in: anakIds }, statusApproval: 'DIAJUKAN' },
            }),
            this.prisma.absensi.count({
                where: { santriId: { in: anakIds }, status: 'HADIR' },
            }),
            this.prisma.nilai.aggregate({ _avg: { nilai: true }, where: { santriId: { in: anakIds } } }),
        ]);
        return {
            role: 'WALI_SANTRI',
            wali: { id: wali.id, nama: wali.nama, hubungan: wali.hubungan },
            anak: wali.santris,
            statistik: {
                jumlahAnak: anakIds.length,
                pelanggaranTotal,
                izinPending,
                kehadiranBulanIni,
                rataRataNilai: rataRataNilai._avg.nilai ?? null,
            },
        };
    }
};
exports.DashboardService = DashboardService;
exports.DashboardService = DashboardService = __decorate([
    (0, common_1.Injectable)(),
    __metadata("design:paramtypes", [prisma_service_1.PrismaService])
], DashboardService);
//# sourceMappingURL=dashboard.service.js.map