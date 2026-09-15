import { PrismaService } from '../prisma/prisma.service';
import { BulkAbsensiDto, CreateAbsensiDto, CreateNilaiDto, CreateTahfidzDto, QueryAbsensiDto } from './dto/akademik.dto';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { JenisNilai } from '@prisma/client';
export declare class AkademikService {
    private prisma;
    constructor(prisma: PrismaService);
    private assertSantri;
    findAllAbsensi(tenantId: string, query: QueryAbsensiDto): Promise<({
        santri: {
            id: string;
            nama: string;
            kelas: {
                namaKelas: string;
            };
            nis: string;
        };
        mapel: {
            id: string;
            namaMapel: string;
        };
    } & {
        id: string;
        createdAt: Date;
        tenantId: string;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        santriId: string;
        tanggal: Date;
        catatan: string | null;
        kelasId: string | null;
        mapelId: string | null;
        inputOleh: string;
    })[]>;
    createAbsensi(tenantId: string, dto: CreateAbsensiDto, user: RequestUser): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        santriId: string;
        tanggal: Date;
        catatan: string | null;
        kelasId: string | null;
        mapelId: string | null;
        inputOleh: string;
    }>;
    bulkAbsensi(tenantId: string, dto: BulkAbsensiDto, user: RequestUser): Promise<{
        count: number;
        message: string;
    }>;
    findAllNilai(tenantId: string, santriId?: string, mapelId?: string, jenis?: JenisNilai): Promise<({
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
        mapel: {
            id: string;
            namaMapel: string;
        };
    } & {
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        jenis: import(".prisma/client").$Enums.JenisNilai;
        mapelId: string;
        nilai: number;
        keterangan: string | null;
        inputOleh: string;
    })[]>;
    createNilai(tenantId: string, dto: CreateNilaiDto, user: RequestUser): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        jenis: import(".prisma/client").$Enums.JenisNilai;
        mapelId: string;
        nilai: number;
        keterangan: string | null;
        inputOleh: string;
    }>;
    findAllTahfidz(tenantId: string, santriId?: string): Promise<({
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
    } & {
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        inputOleh: string;
        juz: number;
        halaman: number;
        tanggalSetor: Date;
        catatanUstadz: string | null;
    })[]>;
    createTahfidz(tenantId: string, dto: CreateTahfidzDto, user: RequestUser): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        inputOleh: string;
        juz: number;
        halaman: number;
        tanggalSetor: Date;
        catatanUstadz: string | null;
    }>;
    private assertSantriInTenant;
}
