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
            jenisKelamin: string;
            tanggalLahir: Date | null;
            status: import(".prisma/client").$Enums.SantriStatus;
            tenantId: string;
            nis: string;
            asrama: string | null;
            tahunMasuk: number;
            kelasId: string | null;
            waliId: string | null;
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
            noHp: string | null;
            email: string | null;
            tenantId: string;
            userId: string | null;
            hubungan: string;
        };
        capaianTahfidzs: {
            id: string;
            tenantId: string;
            createdAt: Date;
            tanggalSetor: Date;
            santriId: string;
            juz: number;
            halaman: number;
            catatanUstadz: string | null;
            inputOleh: string;
        }[];
        pelanggarans: {
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
        }[];
    } & {
        id: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        status: import(".prisma/client").$Enums.SantriStatus;
        tenantId: string;
        nis: string;
        asrama: string | null;
        tahunMasuk: number;
        kelasId: string | null;
        waliId: string | null;
    }>;
    create(tenantId: string, dto: CreateSantriDto): import(".prisma/client").Prisma.Prisma__SantriClient<{
        id: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        status: import(".prisma/client").$Enums.SantriStatus;
        tenantId: string;
        nis: string;
        asrama: string | null;
        tahunMasuk: number;
        kelasId: string | null;
        waliId: string | null;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    update(tenantId: string, id: string, dto: UpdateSantriDto): Promise<{
        id: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        status: import(".prisma/client").$Enums.SantriStatus;
        tenantId: string;
        nis: string;
        asrama: string | null;
        tahunMasuk: number;
        kelasId: string | null;
        waliId: string | null;
    }>;
    remove(tenantId: string, id: string): Promise<{
        message: string;
    }>;
}
