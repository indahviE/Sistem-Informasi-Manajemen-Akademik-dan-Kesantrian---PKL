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
        tenantId: string;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        createdAt: Date;
        kelasId: string | null;
        tanggal: Date;
        santriId: string;
        inputOleh: string;
        mapelId: string | null;
        catatan: string | null;
    })[]>;
    createAbsensi(tenantId: string, dto: CreateAbsensiDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        createdAt: Date;
        kelasId: string | null;
        tanggal: Date;
        santriId: string;
        inputOleh: string;
        mapelId: string | null;
        catatan: string | null;
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
        tenantId: string;
        createdAt: Date;
        jenis: import(".prisma/client").$Enums.JenisNilai;
        nilai: number;
        tanggal: Date;
        santriId: string;
        inputOleh: string;
        mapelId: string;
        keterangan: string | null;
    })[]>;
    createNilai(tenantId: string, dto: CreateNilaiDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        jenis: import(".prisma/client").$Enums.JenisNilai;
        nilai: number;
        tanggal: Date;
        santriId: string;
        inputOleh: string;
        mapelId: string;
        keterangan: string | null;
    }>;
    findAllTahfidz(tenantId: string, santriId?: string): Promise<({
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
