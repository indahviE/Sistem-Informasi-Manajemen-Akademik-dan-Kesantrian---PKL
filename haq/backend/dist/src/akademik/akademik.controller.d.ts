import { AkademikService } from './akademik.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { BulkAbsensiDto, CreateAbsensiDto, CreateNilaiDto, CreateTahfidzDto, QueryAbsensiDto } from './dto/akademik.dto';
import { JenisNilai } from '@prisma/client';
export declare class AkademikController {
    private akademikService;
    constructor(akademikService: AkademikService);
    findAllAbsensi(tenantId: string, q: QueryAbsensiDto): Promise<({
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
        tenantId: string;
        mapelId: string | null;
        kelasId: string | null;
        tanggal: Date;
        createdAt: Date;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        santriId: string;
        catatan: string | null;
        inputOleh: string;
    })[]>;
    createAbsensi(tenantId: string, dto: CreateAbsensiDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        mapelId: string | null;
        kelasId: string | null;
        tanggal: Date;
        createdAt: Date;
        status: import(".prisma/client").$Enums.AbsensiStatus;
        santriId: string;
        catatan: string | null;
        inputOleh: string;
    }>;
    bulkAbsensi(tenantId: string, dto: BulkAbsensiDto, user: RequestUser): Promise<{
        count: number;
        message: string;
    }>;
    findAllNilai(tenantId: string, santriId?: string, mapelId?: string, jenis?: JenisNilai): Promise<({
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
        jenis: import(".prisma/client").$Enums.JenisNilai;
        mapelId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        nilai: number;
        keterangan: string | null;
        inputOleh: string;
    })[]>;
    createNilai(tenantId: string, dto: CreateNilaiDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        jenis: import(".prisma/client").$Enums.JenisNilai;
        mapelId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
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
        tenantId: string;
        createdAt: Date;
        santriId: string;
        inputOleh: string;
        tanggalSetor: Date;
        juz: number;
        halaman: number;
        catatanUstadz: string | null;
    })[]>;
    createTahfidz(tenantId: string, dto: CreateTahfidzDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        santriId: string;
        inputOleh: string;
        tanggalSetor: Date;
        juz: number;
        halaman: number;
        catatanUstadz: string | null;
    }>;
}
