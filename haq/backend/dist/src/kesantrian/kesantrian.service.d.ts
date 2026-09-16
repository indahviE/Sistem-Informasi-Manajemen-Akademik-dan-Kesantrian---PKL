import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKesehatanDto, CreateKunjunganDto, CreatePelanggaranDto, CreatePerizinanDto, CreateTataTertibDto, QueryKesantrianDto, UpdatePelanggaranDto, UpdatePerizinanDto } from './dto/kesantrian.dto';
export declare class KesantrianService {
    private prisma;
    constructor(prisma: PrismaService);
    private assertSantri;
    private getAllowedSantriIdsForWali;
    private buildSantriScope;
    private notifyWali;
    findAllPelanggaran(tenantId: string, query: QueryKesantrianDto, user: RequestUser): Promise<({
        santri: {
            id: string;
            nis: string;
            nama: string;
            kelas: {
                namaKelas: string;
            };
        };
    } & {
        id: string;
        tenantId: string;
        santriId: string;
        jenisPelanggaran: string;
        poin: number;
        tanggal: Date;
        pelaporId: string | null;
        tindakLanjut: string | null;
        status: string;
        createdAt: Date;
    })[]>;
    createPelanggaran(tenantId: string, dto: CreatePelanggaranDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        jenisPelanggaran: string;
        poin: number;
        tanggal: Date;
        pelaporId: string | null;
        tindakLanjut: string | null;
        status: string;
        createdAt: Date;
    }>;
    updatePelanggaran(tenantId: string, id: string, dto: UpdatePelanggaranDto): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        jenisPelanggaran: string;
        poin: number;
        tanggal: Date;
        pelaporId: string | null;
        tindakLanjut: string | null;
        status: string;
        createdAt: Date;
    }>;
    findAllPerizinan(tenantId: string, query: QueryKesantrianDto, user: RequestUser): Promise<{
        disetujuiOlehNama: string;
        santri: {
            id: string;
            nis: string;
            nama: string;
            kelas: {
                namaKelas: string;
            };
        };
        id: string;
        tenantId: string;
        santriId: string;
        createdAt: Date;
        jenis: import(".prisma/client").$Enums.JenisPerizinan;
        tanggalKeluar: Date;
        tanggalKembali: Date | null;
        alasan: string;
        statusApproval: import(".prisma/client").$Enums.StatusApproval;
        disetujuiOleh: string | null;
        catatan: string | null;
    }[]>;
    createPerizinan(tenantId: string, dto: CreatePerizinanDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        createdAt: Date;
        jenis: import(".prisma/client").$Enums.JenisPerizinan;
        tanggalKeluar: Date;
        tanggalKembali: Date | null;
        alasan: string;
        statusApproval: import(".prisma/client").$Enums.StatusApproval;
        disetujuiOleh: string | null;
        catatan: string | null;
    }>;
    updatePerizinan(tenantId: string, id: string, dto: UpdatePerizinanDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        createdAt: Date;
        jenis: import(".prisma/client").$Enums.JenisPerizinan;
        tanggalKeluar: Date;
        tanggalKembali: Date | null;
        alasan: string;
        statusApproval: import(".prisma/client").$Enums.StatusApproval;
        disetujuiOleh: string | null;
        catatan: string | null;
    }>;
    findAllKesehatan(tenantId: string, query: QueryKesantrianDto): Promise<({
        santri: {
            id: string;
            nis: string;
            nama: string;
            kelas: {
                namaKelas: string;
            };
        };
    } & {
        id: string;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        status: import(".prisma/client").$Enums.StatusKesehatan;
        createdAt: Date;
        keluhan: string;
        diagnosa: string | null;
        tindakan: string | null;
        obat: string | null;
        tempat: string;
        inputOleh: string;
    })[]>;
    createKesehatan(tenantId: string, dto: CreateKesehatanDto, user: RequestUser): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        status: import(".prisma/client").$Enums.StatusKesehatan;
        createdAt: Date;
        keluhan: string;
        diagnosa: string | null;
        tindakan: string | null;
        obat: string | null;
        tempat: string;
        inputOleh: string;
    }>;
    findAllKunjungan(tenantId: string, query: QueryKesantrianDto): Promise<({
        santri: {
            id: string;
            nis: string;
            nama: string;
        };
        wali: {
            id: string;
            nama: string;
            hubungan: string;
        };
    } & {
        id: string;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        createdAt: Date;
        waliId: string | null;
        catatan: string | null;
    })[]>;
    createKunjungan(tenantId: string, dto: CreateKunjunganDto): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        createdAt: Date;
        waliId: string | null;
        catatan: string | null;
    }>;
    findAllTataTertib(tenantId: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        judul: string;
        isi: string;
        aktif: boolean;
    }[]>;
    createTataTertib(tenantId: string, dto: CreateTataTertibDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        judul: string;
        isi: string;
        aktif: boolean;
    }>;
    getRekamMedis(tenantId: string, santriId: string): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        golonganDarah: string | null;
        alergi: string | null;
        riwayatPenyakit: string | null;
        tinggiBadan: number | null;
        beratBadan: number | null;
        catatanKhusus: string | null;
        updatedAt: Date;
    } | {
        santriId: string;
        golonganDarah: any;
        alergi: any;
        riwayatPenyakit: any;
        tinggiBadan: any;
        beratBadan: any;
        catatanKhusus: any;
        kosong: boolean;
    }>;
    upsertRekamMedis(tenantId: string, santriId: string, dto: any): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        golonganDarah: string | null;
        alergi: string | null;
        riwayatPenyakit: string | null;
        tinggiBadan: number | null;
        beratBadan: number | null;
        catatanKhusus: string | null;
        updatedAt: Date;
    }>;
}
