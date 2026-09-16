import { PrismaService } from '../prisma/prisma.service';
import { BulkAbsensiDto, CreateAbsensiDto, CreateNilaiDto, CreateTahfidzDto, QueryAbsensiDto } from './dto/akademik.dto';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { JenisNilai } from '@prisma/client';
export declare class AkademikService {
    private prisma;
    constructor(prisma: PrismaService);
    private assertSantri;
    findAllAbsensi(tenantId: string, query: QueryAbsensiDto): Promise<({
        mapel: {
            id: string;
            namaMapel: string;
        };
        santri: {
            id: string;
            nama: string;
            kelas: {
                namaKelas: string;
            };
            nis: string;
        };
    } & {
        id: string;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        catatan: string | null;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date;
        kelasId: string | null;
        createdAt: Date;
        santriId: string;
        inputOleh: string;
    })[]>;
    createAbsensi(tenantId: string, dto: CreateAbsensiDto, user: RequestUser): Promise<{
        id: string;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        catatan: string | null;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date;
        kelasId: string | null;
        createdAt: Date;
        santriId: string;
        inputOleh: string;
    }>;
    bulkAbsensi(tenantId: string, dto: BulkAbsensiDto, user: RequestUser): Promise<{
        count: number;
        message: string;
    }>;
    findAllNilai(tenantId: string, santriId?: string, mapelId?: string, jenis?: JenisNilai, allowedSantriIds?: string[]): Promise<({
        mapel: {
            id: string;
            namaMapel: string;
        };
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
    } & {
        id: string;
        tenantId: string;
        mapelId: string;
        nilai: number;
        tanggal: Date;
        jenis: import(".prisma/client").$Enums.JenisNilai;
        createdAt: Date;
        santriId: string;
        inputOleh: string;
        keterangan: string | null;
    })[]>;
    createNilai(tenantId: string, dto: CreateNilaiDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        mapelId: string;
        nilai: number;
        tanggal: Date;
        jenis: import(".prisma/client").$Enums.JenisNilai;
        createdAt: Date;
        santriId: string;
        inputOleh: string;
        keterangan: string | null;
    }>;
    findAllTahfidz(tenantId: string, santriId?: string, allowedSantriIds?: string[]): Promise<({
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
    } & {
        id: string;
        tenantId: string;
        createdAt: Date;
        tanggalSetor: Date;
        santriId: string;
        juz: number;
        halaman: number;
        catatanUstadz: string | null;
        inputOleh: string;
    })[]>;
    createTahfidz(tenantId: string, dto: CreateTahfidzDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        tanggalSetor: Date;
        santriId: string;
        juz: number;
        halaman: number;
        catatanUstadz: string | null;
        inputOleh: string;
    }>;
    private assertSantriInTenant;
}
