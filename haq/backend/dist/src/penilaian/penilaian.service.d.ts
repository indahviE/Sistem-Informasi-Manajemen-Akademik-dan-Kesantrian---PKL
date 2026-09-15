import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKelulusanDto, CreateRemedialDto, CreateUjianDto, GenerateRaporDto, InputNilaiUjianDto, UpdateKelulusanDto, UpdateRemedialDto, UpdateUjianDto } from './dto/penilaian.dto';
import { Prisma } from '@prisma/client';
export declare class PenilaianService {
    private prisma;
    constructor(prisma: PrismaService);
    private assertSantri;
    findAllUjian(tenantId: string, kelasId?: string): Promise<({
        _count: {
            nilais: number;
        };
        kelas: {
            id: string;
            namaKelas: string;
        };
        mapel: {
            id: string;
            namaMapel: string;
        };
    } & {
        id: string;
        nama: string;
        createdAt: Date;
        tenantId: string;
        tanggal: Date | null;
        updatedAt: Date;
        kelasId: string | null;
        jenis: string;
        mapelId: string | null;
        durasiMenit: number | null;
    })[]>;
    getUjian(tenantId: string, id: string): Promise<{
        kelas: {
            id: string;
            namaKelas: string;
        };
        nilais: ({
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
            catatan: string | null;
            updatedAt: Date;
            ujianId: string;
            nilai: number;
        })[];
        mapel: {
            id: string;
            namaMapel: string;
        };
    } & {
        id: string;
        nama: string;
        createdAt: Date;
        tenantId: string;
        tanggal: Date | null;
        updatedAt: Date;
        kelasId: string | null;
        jenis: string;
        mapelId: string | null;
        durasiMenit: number | null;
    }>;
    createUjian(tenantId: string, dto: CreateUjianDto): Promise<{
        kelas: {
            id: string;
            namaKelas: string;
        };
        mapel: {
            id: string;
            namaMapel: string;
        };
    } & {
        id: string;
        nama: string;
        createdAt: Date;
        tenantId: string;
        tanggal: Date | null;
        updatedAt: Date;
        kelasId: string | null;
        jenis: string;
        mapelId: string | null;
        durasiMenit: number | null;
    }>;
    updateUjian(tenantId: string, id: string, dto: UpdateUjianDto): Promise<{
        id: string;
        nama: string;
        createdAt: Date;
        tenantId: string;
        tanggal: Date | null;
        updatedAt: Date;
        kelasId: string | null;
        jenis: string;
        mapelId: string | null;
        durasiMenit: number | null;
    }>;
    removeUjian(tenantId: string, id: string): Promise<{
        id: string;
        nama: string;
        createdAt: Date;
        tenantId: string;
        tanggal: Date | null;
        updatedAt: Date;
        kelasId: string | null;
        jenis: string;
        mapelId: string | null;
        durasiMenit: number | null;
    }>;
    listNilaiUjian(tenantId: string, ujianId: string): Promise<({
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
        updatedAt: Date;
        ujianId: string;
        nilai: number;
    })[]>;
    inputNilaiUjian(tenantId: string, ujianId: string, dto: InputNilaiUjianDto): Promise<{
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
        catatan: string | null;
        updatedAt: Date;
        ujianId: string;
        nilai: number;
    }>;
    inputNilaiUjianBulk(tenantId: string, ujianId: string, items: InputNilaiUjianDto[], user: RequestUser): Promise<any[]>;
    removeNilaiUjian(tenantId: string, ujianId: string, nilaiId: string): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        catatan: string | null;
        updatedAt: Date;
        ujianId: string;
        nilai: number;
    }>;
    findAllRemedial(tenantId: string, santriId?: string): Promise<({
        santri: {
            id: string;
            nama: string;
            kelas: {
                namaKelas: string;
            };
            nis: string;
        };
        ujian: {
            id: string;
            nama: string;
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
        updatedAt: Date;
        mapelId: string | null;
        ujianId: string | null;
        keterangan: string;
        hasil: string | null;
    })[]>;
    createRemedial(tenantId: string, dto: CreateRemedialDto): Promise<{
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
        ujian: {
            id: string;
            nama: string;
        };
    } & {
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        updatedAt: Date;
        mapelId: string | null;
        ujianId: string | null;
        keterangan: string;
        hasil: string | null;
    }>;
    updateRemedial(tenantId: string, id: string, dto: UpdateRemedialDto): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        updatedAt: Date;
        mapelId: string | null;
        ujianId: string | null;
        keterangan: string;
        hasil: string | null;
    }>;
    removeRemedial(tenantId: string, id: string): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        updatedAt: Date;
        mapelId: string | null;
        ujianId: string | null;
        keterangan: string;
        hasil: string | null;
    }>;
    findAllRapor(tenantId: string, santriId?: string, periode?: string): Promise<({
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
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
        updatedAt: Date;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    })[]>;
    getRapor(tenantId: string, id: string): Promise<{
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
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
        updatedAt: Date;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    generateRapor(tenantId: string, dto: GenerateRaporDto): Promise<{
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
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
        updatedAt: Date;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    terbitRapor(tenantId: string, id: string): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
        updatedAt: Date;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    removeRapor(tenantId: string, id: string): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
        updatedAt: Date;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    findAllKelulusan(tenantId: string): Promise<({
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
        catatan: string | null;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    })[]>;
    createKelulusan(tenantId: string, dto: CreateKelulusanDto): Promise<{
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
    } & {
        id: string;
        createdAt: Date;
        tenantId: string;
        status: string;
        santriId: string;
        catatan: string | null;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
    updateKelulusan(tenantId: string, id: string, dto: UpdateKelulusanDto): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: string;
        santriId: string;
        catatan: string | null;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
    removeKelulusan(tenantId: string, id: string): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: string;
        santriId: string;
        catatan: string | null;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
}
