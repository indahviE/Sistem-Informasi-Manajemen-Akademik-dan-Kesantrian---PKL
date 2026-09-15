import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKesehatanDto, CreateKunjunganDto, CreatePelanggaranDto, CreatePerizinanDto, CreateTataTertibDto, QueryKesantrianDto, UpdatePelanggaranDto, UpdatePerizinanDto } from './dto/kesantrian.dto';
export declare class KesantrianService {
    private prisma;
    constructor(prisma: PrismaService);
    private assertSantri;
    private notifyWali;
    findAllPelanggaran(tenantId: string, query: QueryKesantrianDto): Promise<({
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
        createdAt: Date;
        tenantId: string;
        status: string;
        santriId: string;
        tanggal: Date;
        tindakLanjut: string | null;
        jenisPelanggaran: string;
        poin: number;
        pelaporId: string | null;
    })[]>;
    createPelanggaran(tenantId: string, dto: CreatePelanggaranDto, user: RequestUser): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: string;
        santriId: string;
        tanggal: Date;
        tindakLanjut: string | null;
        jenisPelanggaran: string;
        poin: number;
        pelaporId: string | null;
    }>;
    updatePelanggaran(tenantId: string, id: string, dto: UpdatePelanggaranDto): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: string;
        santriId: string;
        tanggal: Date;
        tindakLanjut: string | null;
        jenisPelanggaran: string;
        poin: number;
        pelaporId: string | null;
    }>;
    findAllPerizinan(tenantId: string, query: QueryKesantrianDto): Promise<({
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
        createdAt: Date;
        tenantId: string;
        santriId: string;
        catatan: string | null;
        jenis: import(".prisma/client").$Enums.JenisPerizinan;
        tanggalKeluar: Date;
        tanggalKembali: Date | null;
        alasan: string;
        statusApproval: import(".prisma/client").$Enums.StatusApproval;
        disetujuiOleh: string | null;
    })[]>;
    createPerizinan(tenantId: string, dto: CreatePerizinanDto, user: RequestUser): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        catatan: string | null;
        jenis: import(".prisma/client").$Enums.JenisPerizinan;
        tanggalKeluar: Date;
        tanggalKembali: Date | null;
        alasan: string;
        statusApproval: import(".prisma/client").$Enums.StatusApproval;
        disetujuiOleh: string | null;
    }>;
    updatePerizinan(tenantId: string, id: string, dto: UpdatePerizinanDto, user: RequestUser): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        catatan: string | null;
        jenis: import(".prisma/client").$Enums.JenisPerizinan;
        tanggalKeluar: Date;
        tanggalKembali: Date | null;
        alasan: string;
        statusApproval: import(".prisma/client").$Enums.StatusApproval;
        disetujuiOleh: string | null;
    }>;
    findAllKesehatan(tenantId: string, query: QueryKesantrianDto): Promise<({
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
        createdAt: Date;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusKesehatan;
        santriId: string;
        tanggal: Date;
        inputOleh: string;
        keluhan: string;
        diagnosa: string | null;
        tindakan: string | null;
        obat: string | null;
        tempat: string;
    })[]>;
    createKesehatan(tenantId: string, dto: CreateKesehatanDto, user: RequestUser): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusKesehatan;
        santriId: string;
        tanggal: Date;
        inputOleh: string;
        keluhan: string;
        diagnosa: string | null;
        tindakan: string | null;
        obat: string | null;
        tempat: string;
    }>;
    findAllKunjungan(tenantId: string, query: QueryKesantrianDto): Promise<({
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
        wali: {
            id: string;
            nama: string;
            hubungan: string;
        };
    } & {
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        catatan: string | null;
        waliId: string | null;
    })[]>;
    createKunjungan(tenantId: string, dto: CreateKunjunganDto): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        catatan: string | null;
        waliId: string | null;
    }>;
    findAllTataTertib(tenantId: string): Promise<{
        id: string;
        aktif: boolean;
        createdAt: Date;
        tenantId: string;
        judul: string;
        isi: string;
    }[]>;
    createTataTertib(tenantId: string, dto: CreateTataTertibDto): Promise<{
        id: string;
        aktif: boolean;
        createdAt: Date;
        tenantId: string;
        judul: string;
        isi: string;
    }>;
    getRekamMedis(tenantId: string, santriId: string): Promise<{
        id: string;
        tenantId: string;
        santriId: string;
        updatedAt: Date;
        golonganDarah: string | null;
        alergi: string | null;
        riwayatPenyakit: string | null;
        tinggiBadan: number | null;
        beratBadan: number | null;
        catatanKhusus: string | null;
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
        updatedAt: Date;
        golonganDarah: string | null;
        alergi: string | null;
        riwayatPenyakit: string | null;
        tinggiBadan: number | null;
        beratBadan: number | null;
        catatanKhusus: string | null;
    }>;
}
