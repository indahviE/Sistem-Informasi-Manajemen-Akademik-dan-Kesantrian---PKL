import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKelulusanDto, CreateRemedialDto, CreateUjianDto, GenerateRaporDto, InputNilaiUjianDto, UpdateKelulusanDto, UpdateRemedialDto, UpdateUjianDto } from './dto/penilaian.dto';
import { Prisma } from '@prisma/client';
export declare class PenilaianService {
    private prisma;
    constructor(prisma: PrismaService);
    private assertSantri;
    findAllUjian(tenantId: string, kelasId?: string): Promise<({
        mapel: {
            id: string;
            namaMapel: string;
        };
        kelas: {
            id: string;
            namaKelas: string;
        };
        _count: {
            nilais: number;
        };
    } & {
        id: string;
        tenantId: string;
        nama: string;
        jenis: string;
        mapelId: string | null;
        kelasId: string | null;
        tanggal: Date | null;
        durasiMenit: number | null;
        createdAt: Date;
        updatedAt: Date;
    })[]>;
    getUjian(tenantId: string, id: string): Promise<{
        mapel: {
            id: string;
            namaMapel: string;
        };
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
            updatedAt: Date;
            ujianId: string;
            santriId: string;
            nilai: number;
            catatan: string | null;
        })[];
    } & {
        id: string;
        tenantId: string;
        nama: string;
        jenis: string;
        mapelId: string | null;
        kelasId: string | null;
        tanggal: Date | null;
        durasiMenit: number | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
    createUjian(tenantId: string, dto: CreateUjianDto): Promise<{
        mapel: {
            id: string;
            namaMapel: string;
        };
        kelas: {
            id: string;
            namaKelas: string;
        };
    } & {
        id: string;
        tenantId: string;
        nama: string;
        jenis: string;
        mapelId: string | null;
        kelasId: string | null;
        tanggal: Date | null;
        durasiMenit: number | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
    updateUjian(tenantId: string, id: string, dto: UpdateUjianDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        jenis: string;
        mapelId: string | null;
        kelasId: string | null;
        tanggal: Date | null;
        durasiMenit: number | null;
        createdAt: Date;
        updatedAt: Date;
    }>;
    removeUjian(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        jenis: string;
        mapelId: string | null;
        kelasId: string | null;
        tanggal: Date | null;
        durasiMenit: number | null;
        createdAt: Date;
        updatedAt: Date;
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
        updatedAt: Date;
        ujianId: string;
        santriId: string;
        nilai: number;
        catatan: string | null;
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
        updatedAt: Date;
        ujianId: string;
        santriId: string;
        nilai: number;
        catatan: string | null;
    }>;
    inputNilaiUjianBulk(tenantId: string, ujianId: string, items: InputNilaiUjianDto[], user: RequestUser): Promise<any[]>;
    removeNilaiUjian(tenantId: string, ujianId: string, nilaiId: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        updatedAt: Date;
        ujianId: string;
        santriId: string;
        nilai: number;
        catatan: string | null;
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
        tanggal: Date;
        createdAt: Date;
        updatedAt: Date;
        ujianId: string | null;
        santriId: string;
        keterangan: string;
        hasil: string | null;
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
        tanggal: Date;
        createdAt: Date;
        updatedAt: Date;
        ujianId: string | null;
        santriId: string;
        keterangan: string;
        hasil: string | null;
    }>;
    updateRemedial(tenantId: string, id: string, dto: UpdateRemedialDto): Promise<{
        id: string;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date;
        createdAt: Date;
        updatedAt: Date;
        ujianId: string | null;
        santriId: string;
        keterangan: string;
        hasil: string | null;
    }>;
    removeRemedial(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date;
        createdAt: Date;
        updatedAt: Date;
        ujianId: string | null;
        santriId: string;
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
        tenantId: string;
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
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
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
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
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    terbitRapor(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
        periode: string;
        ringkasan: Prisma.JsonValue | null;
        rataRata: number | null;
    }>;
    removeRapor(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        updatedAt: Date;
        status: import(".prisma/client").$Enums.StatusRapor;
        santriId: string;
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
        createdAt: Date;
        updatedAt: Date;
        status: string;
        santriId: string;
        catatan: string | null;
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
        createdAt: Date;
        updatedAt: Date;
        status: string;
        santriId: string;
        catatan: string | null;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
    updateKelulusan(tenantId: string, id: string, dto: UpdateKelulusanDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        updatedAt: Date;
        status: string;
        santriId: string;
        catatan: string | null;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
    removeKelulusan(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        updatedAt: Date;
        status: string;
        santriId: string;
        catatan: string | null;
        tanggalKelulusan: Date;
        predikat: import(".prisma/client").$Enums.PredikatKelulusan | null;
        juzYangDiHafal: number | null;
    }>;
}
