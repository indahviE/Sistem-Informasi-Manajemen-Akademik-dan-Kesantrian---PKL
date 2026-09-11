import { SantriService } from './santri.service';
import { CreateSantriDto, QuerySantriDto, UpdateSantriDto } from './dto/santri.dto';
export declare class SantriController {
    private santriService;
    constructor(santriService: SantriService);
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
            nis: string;
            nama: string;
            jenisKelamin: string;
            tanggalLahir: Date | null;
            kelasId: string | null;
            asrama: string | null;
            waliId: string | null;
            status: import(".prisma/client").$Enums.SantriStatus;
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
            noHp: string | null;
            email: string | null;
            hubungan: string;
            userId: string | null;
        };
        capaianTahfidzs: {
            id: string;
            tenantId: string;
            tanggalSetor: Date;
            santriId: string;
            juz: number;
            halaman: number;
            catatanUstadz: string | null;
            inputOleh: string;
            createdAt: Date;
        }[];
        pelanggarans: {
            id: string;
            tenantId: string;
            status: string;
            santriId: string;
            createdAt: Date;
            tanggal: Date;
            jenisPelanggaran: string;
            poin: number;
            pelaporId: string | null;
            tindakLanjut: string | null;
        }[];
    } & {
        id: string;
        tenantId: string;
        nis: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        kelasId: string | null;
        asrama: string | null;
        waliId: string | null;
        status: import(".prisma/client").$Enums.SantriStatus;
        tahunMasuk: number;
    }>;
    create(tenantId: string, dto: CreateSantriDto): import(".prisma/client").Prisma.Prisma__SantriClient<{
        id: string;
        tenantId: string;
        nis: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        kelasId: string | null;
        asrama: string | null;
        waliId: string | null;
        status: import(".prisma/client").$Enums.SantriStatus;
        tahunMasuk: number;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    update(tenantId: string, id: string, dto: UpdateSantriDto): Promise<{
        id: string;
        tenantId: string;
        nis: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        kelasId: string | null;
        asrama: string | null;
        waliId: string | null;
        status: import(".prisma/client").$Enums.SantriStatus;
        tahunMasuk: number;
    }>;
    remove(tenantId: string, id: string): Promise<{
        message: string;
    }>;
}
