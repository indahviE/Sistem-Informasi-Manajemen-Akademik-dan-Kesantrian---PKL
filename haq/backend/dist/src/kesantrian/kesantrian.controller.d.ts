import { KesantrianService } from './kesantrian.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKesehatanDto, CreateKunjunganDto, CreatePelanggaranDto, CreatePerizinanDto, CreateTataTertibDto, QueryKesantrianDto, UpdatePelanggaranDto, UpdatePerizinanDto } from './dto/kesantrian.dto';
export declare class KesantrianController {
    private kesantrianService;
    constructor(kesantrianService: KesantrianService);
    findAllPelanggaran(tenantId: string, q: QueryKesantrianDto, user: RequestUser): Promise<({
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
        status: string;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        jenisPelanggaran: string;
        poin: number;
        pelaporId: string | null;
        tindakLanjut: string | null;
    })[]>;
    createPelanggaran(tenantId: string, dto: CreatePelanggaranDto, user: RequestUser): Promise<{
        id: string;
        status: string;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        jenisPelanggaran: string;
        poin: number;
        pelaporId: string | null;
        tindakLanjut: string | null;
    }>;
    updatePelanggaran(tenantId: string, id: string, dto: UpdatePelanggaranDto): Promise<{
        id: string;
        status: string;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        jenisPelanggaran: string;
        poin: number;
        pelaporId: string | null;
        tindakLanjut: string | null;
    }>;
    findAllPerizinan(tenantId: string, q: QueryKesantrianDto, user: RequestUser): Promise<({
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
        catatan: string | null;
        tenantId: string;
        jenis: import(".prisma/client").$Enums.JenisPerizinan;
        createdAt: Date;
        santriId: string;
        tanggalKeluar: Date;
        tanggalKembali: Date | null;
        alasan: string;
        statusApproval: import(".prisma/client").$Enums.StatusApproval;
        disetujuiOleh: string | null;
    })[]>;
    createPerizinan(tenantId: string, dto: CreatePerizinanDto, user: RequestUser): Promise<{
        id: string;
        catatan: string | null;
        tenantId: string;
        jenis: import(".prisma/client").$Enums.JenisPerizinan;
        createdAt: Date;
        santriId: string;
        tanggalKeluar: Date;
        tanggalKembali: Date | null;
        alasan: string;
        statusApproval: import(".prisma/client").$Enums.StatusApproval;
        disetujuiOleh: string | null;
    }>;
    updatePerizinan(tenantId: string, id: string, dto: UpdatePerizinanDto, user: RequestUser): Promise<{
        id: string;
        catatan: string | null;
        tenantId: string;
        jenis: import(".prisma/client").$Enums.JenisPerizinan;
        createdAt: Date;
        santriId: string;
        tanggalKeluar: Date;
        tanggalKembali: Date | null;
        alasan: string;
        statusApproval: import(".prisma/client").$Enums.StatusApproval;
        disetujuiOleh: string | null;
    }>;
    findAllKesehatan(tenantId: string, q: QueryKesantrianDto): Promise<({
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
        status: import(".prisma/client").$Enums.StatusKesehatan;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        inputOleh: string;
        keluhan: string;
        diagnosa: string | null;
        tindakan: string | null;
        obat: string | null;
        tempat: string;
    })[]>;
    createKesehatan(tenantId: string, dto: CreateKesehatanDto, user: RequestUser): Promise<{
        id: string;
        status: import(".prisma/client").$Enums.StatusKesehatan;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        inputOleh: string;
        keluhan: string;
        diagnosa: string | null;
        tindakan: string | null;
        obat: string | null;
        tempat: string;
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
    findAllKunjungan(tenantId: string, q: QueryKesantrianDto): Promise<({
        wali: {
            id: string;
            nama: string;
            hubungan: string;
        };
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
    } & {
        id: string;
        catatan: string | null;
        tenantId: string;
        tanggal: Date;
        waliId: string | null;
        createdAt: Date;
        santriId: string;
    })[]>;
    createKunjungan(tenantId: string, dto: CreateKunjunganDto): Promise<{
        id: string;
        catatan: string | null;
        tenantId: string;
        tanggal: Date;
        waliId: string | null;
        createdAt: Date;
        santriId: string;
    }>;
    findAllTataTertib(tenantId: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        aktif: boolean;
        judul: string;
        isi: string;
    }[]>;
    createTataTertib(tenantId: string, dto: CreateTataTertibDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        aktif: boolean;
        judul: string;
        isi: string;
    }>;
}
