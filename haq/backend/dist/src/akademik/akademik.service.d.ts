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
            nis: string;
            nama: string;
            kelas: {
                namaKelas: string;
            };
        };
        mapel: {
            id: string;
            namaMapel: string;
        };
    } & {
        id: string;
        tenantId: string;
        santriId: string;
        kelasId: string | null;
        mapelId: string | null;
        tanggal: Date;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        catatan: string | null;
        inputOleh: string;
        createdAt: Date;
    })[]>;
    createAbsensi(tenantId: string, dto: CreateAbsensiDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        kelasId: string | null;
        mapelId: string | null;
        tanggal: Date;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        catatan: string | null;
        inputOleh: string;
        createdAt: Date;
    }>;
    bulkAbsensi(tenantId: string, dto: BulkAbsensiDto, user: RequestUser): Promise<{
        count: number;
        message: string;
    }>;
    findAllNilai(tenantId: string, santriId?: string, mapelId?: string, jenis?: JenisNilai, allowedSantriIds?: string[]): Promise<({
        santri: {
            id: string;
            nis: string;
            nama: string;
        };
        mapel: {
            id: string;
            namaMapel: string;
        };
    } & {
        id: string;
        tenantId: string;
        santriId: string;
        mapelId: string;
        tanggal: Date;
        inputOleh: string;
        createdAt: Date;
        jenis: import(".prisma/client").$Enums.JenisNilai;
        nilai: number;
        keterangan: string | null;
    })[]>;
    createNilai(tenantId: string, dto: CreateNilaiDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        mapelId: string;
        tanggal: Date;
        inputOleh: string;
        createdAt: Date;
        jenis: import(".prisma/client").$Enums.JenisNilai;
        nilai: number;
        keterangan: string | null;
    }>;
    findAllTahfidz(tenantId: string, santriId?: string, allowedSantriIds?: string[]): Promise<({
        santri: {
            id: string;
            nis: string;
            nama: string;
        };
    } & {
        id: string;
        tenantId: string;
        santriId: string;
        inputOleh: string;
        createdAt: Date;
        juz: number;
        halaman: number;
        tanggalSetor: Date;
        catatanUstadz: string | null;
    })[]>;
    createTahfidz(tenantId: string, dto: CreateTahfidzDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        inputOleh: string;
        createdAt: Date;
        juz: number;
        halaman: number;
        tanggalSetor: Date;
        catatanUstadz: string | null;
    }>;
    private assertSantriInTenant;
}
