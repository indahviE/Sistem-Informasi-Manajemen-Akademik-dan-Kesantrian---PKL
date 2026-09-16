import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
export declare class DashboardService {
    private prisma;
    constructor(prisma: PrismaService);
    getDashboard(user: RequestUser): Promise<{
        role: string;
        statistik: {
            totalTenant: number;
            tenantAktif: number;
            tenantPending: number;
            totalUser: number;
            totalSantri: number;
        };
        tenantTerbaru: ({
            _count: {
                users: number;
                santris: number;
            };
        } & {
            id: string;
            status: import(".prisma/client").$Enums.TenantStatus;
            tanggalDaftar: Date;
            kodeTenant: string;
            namaPondok: string;
            logoUrl: string | null;
            warnaTema: string | null;
            kuotaSantriPpdb: number | null;
            statusGelombangPpdb: import(".prisma/client").$Enums.StatusGelombangPpdb;
            adminAwalId: string | null;
        })[];
    } | {
        role: string;
        statistik: {
            jumlahAnak?: undefined;
            pelanggaranTotal?: undefined;
            izinPending?: undefined;
            kehadiranBulanIni?: undefined;
            rataRataNilai?: undefined;
        };
        anak: any[];
        pesan: string;
        wali?: undefined;
    } | {
        role: string;
        wali: {
            id: string;
            nama: string;
            hubungan: string;
        };
        anak: ({
            kelas: {
                namaKelas: string;
            };
        } & {
            id: string;
            nama: string;
            jenisKelamin: string;
            tanggalLahir: Date | null;
            status: import(".prisma/client").$Enums.SantriStatus;
            tenantId: string;
            nis: string;
            asrama: string | null;
            tahunMasuk: number;
            kelasId: string | null;
            waliId: string | null;
        })[];
        statistik: {
            jumlahAnak: number;
            pelanggaranTotal: number;
            izinPending: number;
            kehadiranBulanIni: number;
            rataRataNilai: number;
        };
        pesan?: undefined;
    } | {
        role: string;
        statistik: {
            totalSantri: number;
            santriAktif: number;
            totalKelas: number;
            totalUstadz: number;
            hadirHariIni: number;
            pelanggaranMingguIni: number;
            izinPending: number;
            santriSakit: number;
        };
        distribusiKelas: ({
            _count: {
                santris: number;
            };
        } & {
            id: string;
            tenantId: string;
            namaKelas: string;
            tingkat: string;
            waliKelasId: string | null;
            tahunAjaranId: string | null;
        })[];
        pelanggaranPerHari: (import(".prisma/client").Prisma.PickEnumerable<import(".prisma/client").Prisma.PelanggaranGroupByOutputType, "tanggal"[]> & {
            _count: number;
        })[];
    }>;
    private superAdminDashboard;
    private tenantDashboard;
    private waliDashboard;
}
