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
            tenantId: string;
            nama: string;
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
            tenantId: string;
            nama: string;
            email: string | null;
            noHp: string | null;
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
            tenantId: string;
            status: string;
            createdAt: Date;
            tanggal: Date;
            santriId: string;
            jenisPelanggaran: string;
            poin: number;
            pelaporId: string | null;
            tindakLanjut: string | null;
        }[];
    } & {
        id: string;
        tenantId: string;
        nama: string;
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
        tenantId: string;
        nama: string;
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
        tenantId: string;
        nama: string;
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
