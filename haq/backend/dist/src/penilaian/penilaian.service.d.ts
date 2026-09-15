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
        tenantId: string;
        nama: string;
        createdAt: Date;
        jenis: string;
        kelasId: string | null;
        tanggal: Date | null;
        mapelId: string | null;
        updatedAt: Date;
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
            tenantId: string;
            createdAt: Date;
            nilai: number;
            santriId: string;
            catatan: string | null;
            updatedAt: Date;
            ujianId: string;
        })[];
        mapel: {
            id: string;
            namaMapel: string;
        };
    } & {
        id: string;
        tenantId: string;
        nama: string;
        createdAt: Date;
        jenis: string;
        kelasId: string | null;
        tanggal: Date | null;
        mapelId: string | null;
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
        tenantId: string;
        nama: string;
        createdAt: Date;
        jenis: string;
        kelasId: string | null;
        tanggal: Date | null;
        mapelId: string | null;
        updatedAt: Date;
        durasiMenit: number | null;
    }>;
    updateUjian(tenantId: string, id: string, dto: UpdateUjianDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        createdAt: Date;
        jenis: string;
        kelasId: string | null;
        tanggal: Date | null;
        mapelId: string | null;
        updatedAt: Date;
        durasiMenit: number | null;
    }>;
    removeUjian(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        createdAt: Date;
        jenis: string;
        kelasId: string | null;
        tanggal: Date | null;
        mapelId: string | null;
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
        tenantId: string;
        createdAt: Date;
        nilai: number;
        santriId: string;
        catatan: string | null;
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
        tenantId: string;
        createdAt: Date;
        nilai: number;
        santriId: string;
        catatan: string | null;
        updatedAt: Date;
        ujianId: string;
    }>;
    inputNilaiUjianBulk(tenantId: string, ujianId: string, items: InputNilaiUjianDto[], user: RequestUser): Promise<any[]>;
    removeNilaiUjian(tenantId: string, ujianId: string, nilaiId: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        nilai: number;
        santriId: string;
        catatan: string | null;
        updatedAt: Date;
        ujianId: string;
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
        tenantId: string;
        createdAt: Date;
        tanggal: Date;
        santriId: string;
        mapelId: string | null;
        keterangan: string;
        updatedAt: Date;
        hasil: string | null;
        ujianId: string | null;
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
        tenantId: string;
        createdAt: Date;
        tanggal: Date;
        santriId: string;
        mapelId: string | null;
        keterangan: string;
        updatedAt: Date;
        hasil: string | null;
        ujianId: string | null;
    }>;
    updateRemedial(tenantId: string, id: string, dto: UpdateRemedialDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        tanggal: Date;
        santriId: string;
        mapelId: string | null;
        keterangan: string;
        updatedAt: Date;
        hasil: string | null;
        ujianId: string | null;
    }>;
    removeRemedial(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        tanggal: Date;
        santriId: string;
        mapelId: string | null;
        keterangan: string;
        updatedAt: Date;
        hasil: string | null;
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
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusRapor;
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
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusRapor;
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
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusRapor;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    terbitRapor(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusRapor;
        createdAt: Date;
        santriId: string;
        updatedAt: Date;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    removeRapor(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusRapor;
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
        tenantId: string;
        status: string;
        createdAt: Date;
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
        tenantId: string;
        status: string;
        createdAt: Date;
        santriId: string;
        catatan: string | null;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
    updateKelulusan(tenantId: string, id: string, dto: UpdateKelulusanDto): Promise<{
        id: string;
        tenantId: string;
        status: string;
        createdAt: Date;
        santriId: string;
        catatan: string | null;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
    removeKelulusan(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        status: string;
        createdAt: Date;
        santriId: string;
        catatan: string | null;
        updatedAt: Date;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
}
