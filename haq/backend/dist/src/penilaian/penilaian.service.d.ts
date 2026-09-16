import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKelulusanDto, CreateRemedialDto, CreateUjianDto, GenerateRaporDto, InputNilaiUjianDto, UpdateKelulusanDto, UpdateRemedialDto, UpdateUjianDto } from './dto/penilaian.dto';
import { Prisma } from '@prisma/client';
export declare class PenilaianService {
    private prisma;
    constructor(prisma: PrismaService);
    private assertSantri;
    findAllUjian(tenantId: string, kelasId?: string): Promise<({
        kelas: {
            id: string;
            namaKelas: string;
        };
        _count: {
            nilais: number;
        };
        mapel: {
            id: string;
            namaMapel: string;
        };
    } & {
        id: string;
        nama: string;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date | null;
        jenis: string;
        kelasId: string | null;
        createdAt: Date;
        updatedAt: Date;
        durasiMenit: number | null;
    })[]>;
    getUjian(tenantId: string, id: string): Promise<{
        kelas: {
            id: string;
            namaKelas: string;
        };
        mapel: {
            id: string;
            namaMapel: string;
        };
        nilais: ({
            santri: {
                id: string;
                nama: string;
                nis: string;
            };
        } & {
            id: string;
            catatan: string | null;
            tenantId: string;
            nilai: number;
            createdAt: Date;
            santriId: string;
            updatedAt: Date;
            ujianId: string;
        })[];
    } & {
        id: string;
        nama: string;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date | null;
        jenis: string;
        kelasId: string | null;
        createdAt: Date;
        updatedAt: Date;
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
        tenantId: string;
        mapelId: string | null;
        tanggal: Date | null;
        jenis: string;
        kelasId: string | null;
        createdAt: Date;
        updatedAt: Date;
        durasiMenit: number | null;
    }>;
    updateUjian(tenantId: string, id: string, dto: UpdateUjianDto): Promise<{
        id: string;
        nama: string;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date | null;
        jenis: string;
        kelasId: string | null;
        createdAt: Date;
        updatedAt: Date;
        durasiMenit: number | null;
    }>;
    removeUjian(tenantId: string, id: string): Promise<{
        id: string;
        nama: string;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date | null;
        jenis: string;
        kelasId: string | null;
        createdAt: Date;
        updatedAt: Date;
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
        catatan: string | null;
        tenantId: string;
        nilai: number;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        ujianId: string;
    })[]>;
    inputNilaiUjian(tenantId: string, ujianId: string, dto: InputNilaiUjianDto): Promise<{
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
    } & {
        id: string;
        catatan: string | null;
        tenantId: string;
        nilai: number;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        ujianId: string;
    }>;
    inputNilaiUjianBulk(tenantId: string, ujianId: string, items: InputNilaiUjianDto[], user: RequestUser): Promise<any[]>;
    removeNilaiUjian(tenantId: string, ujianId: string, nilaiId: string): Promise<{
        id: string;
        catatan: string | null;
        tenantId: string;
        nilai: number;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        ujianId: string;
    }>;
    findAllRemedial(tenantId: string, santriId?: string): Promise<({
        ujian: {
            id: string;
            nama: string;
        };
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
        hasil: string | null;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        keterangan: string;
        updatedAt: Date;
        ujianId: string | null;
    })[]>;
    createRemedial(tenantId: string, dto: CreateRemedialDto): Promise<{
        ujian: {
            id: string;
            nama: string;
        };
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
    } & {
        id: string;
        tenantId: string;
        mapelId: string | null;
        hasil: string | null;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        keterangan: string;
        updatedAt: Date;
        ujianId: string | null;
    }>;
    updateRemedial(tenantId: string, id: string, dto: UpdateRemedialDto): Promise<{
        id: string;
        tenantId: string;
        mapelId: string | null;
        hasil: string | null;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        keterangan: string;
        updatedAt: Date;
        ujianId: string | null;
    }>;
    removeRemedial(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        mapelId: string | null;
        hasil: string | null;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        keterangan: string;
        updatedAt: Date;
        ujianId: string | null;
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
        status: import(".prisma/client").$Enums.StatusRapor;
        tenantId: string;
        createdAt: Date;
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
        status: import(".prisma/client").$Enums.StatusRapor;
        tenantId: string;
        createdAt: Date;
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
        status: import(".prisma/client").$Enums.StatusRapor;
        tenantId: string;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    terbitRapor(tenantId: string, id: string): Promise<{
        id: string;
        status: import(".prisma/client").$Enums.StatusRapor;
        tenantId: string;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    removeRapor(tenantId: string, id: string): Promise<{
        id: string;
        status: import(".prisma/client").$Enums.StatusRapor;
        tenantId: string;
        createdAt: Date;
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
        status: string;
        catatan: string | null;
        tenantId: string;
        createdAt: Date;
        santriId: string;
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
        status: string;
        catatan: string | null;
        tenantId: string;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
    updateKelulusan(tenantId: string, id: string, dto: UpdateKelulusanDto): Promise<{
        id: string;
        status: string;
        catatan: string | null;
        tenantId: string;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
    removeKelulusan(tenantId: string, id: string): Promise<{
        id: string;
        status: string;
        catatan: string | null;
        tenantId: string;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
}
