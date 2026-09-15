import { PrismaService } from '../prisma/prisma.service';
import { CreateSantriDto, QuerySantriDto, UpdateSantriDto } from './dto/santri.dto';
export declare class SantriService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(tenantId: string, query: QuerySantriDto): Promise<{
        items: ({
            kelas: {
                id: string;
                namaKelas: string;
            };
            wali: {
                id: string;
                nama: string;
                noHp: string;
            };
        } & {
            id: string;
            nama: string;
            tenantId: string;
            status: import(".prisma/client").$Enums.SantriStatus;
            nis: string;
            jenisKelamin: string;
            tanggalLahir: Date | null;
            kelasId: string | null;
            asrama: string | null;
            waliId: string | null;
            tahunMasuk: number;
        })[];
        total: number;
        page: number;
        perPage: number;
    }>;
    findOne(tenantId: string, id: string): Promise<{
        kelas: {
            id: string;
            tenantId: string;
            namaKelas: string;
            tingkat: string;
            waliKelasId: string | null;
            tahunAjaranId: string | null;
        };
        wali: {
            id: string;
            nama: string;
            tenantId: string;
            noHp: string | null;
            userId: string | null;
            email: string | null;
            hubungan: string;
        };
        capaianTahfidzs: {
            id: string;
            createdAt: Date;
            tenantId: string;
            santriId: string;
            inputOleh: string;
            juz: number;
            halaman: number;
            tanggalSetor: Date;
            catatanUstadz: string | null;
        }[];
        pelanggarans: {
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
        }[];
    } & {
        id: string;
        nama: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.SantriStatus;
        nis: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        kelasId: string | null;
        asrama: string | null;
        waliId: string | null;
        tahunMasuk: number;
    }>;
    create(tenantId: string, dto: CreateSantriDto): import(".prisma/client").Prisma.Prisma__SantriClient<{
        id: string;
        nama: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.SantriStatus;
        nis: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        kelasId: string | null;
        asrama: string | null;
        waliId: string | null;
        tahunMasuk: number;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    update(tenantId: string, id: string, dto: UpdateSantriDto): Promise<{
        id: string;
        nama: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.SantriStatus;
        nis: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        kelasId: string | null;
        asrama: string | null;
        waliId: string | null;
        tahunMasuk: number;
    }>;
    remove(tenantId: string, id: string): Promise<{
        message: string;
    }>;
}
