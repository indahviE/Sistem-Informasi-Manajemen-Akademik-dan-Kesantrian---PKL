import { PrismaService } from '../prisma/prisma.service';
import { CreatePlacementTestDto, DaftarPpdbDto, QueryPpdbDto, UpdatePendaftaranDto } from './dto/ppdb.dto';
export declare class PpdbService {
    private prisma;
    constructor(prisma: PrismaService);
    daftar(dto: DaftarPpdbDto): Promise<{
        id: string;
        noPendaftaran: string;
        nama: string;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        message: string;
    }>;
    findAll(tenantId: string, q: QueryPpdbDto): Promise<{
        noPendaftaran: string;
        ujian: {
            id: string;
            tenantId: string;
            tanggal: Date;
            catatan: string | null;
            mapelId: string | null;
            nilai: number | null;
            hasil: string | null;
            pendaftaranId: string;
        };
        id: string;
        nama: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        tanggalDaftar: Date;
        catatan: string | null;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        noHp: string | null;
        asalSekolah: string | null;
        email: string | null;
        alamat: string | null;
        jalur: string | null;
    }[]>;
    findOne(tenantId: string, id: string): Promise<{
        ujian: {
            id: string;
            tenantId: string;
            tanggal: Date;
            catatan: string | null;
            mapelId: string | null;
            nilai: number | null;
            hasil: string | null;
            pendaftaranId: string;
        };
    } & {
        id: string;
        nama: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        tanggalDaftar: Date;
        catatan: string | null;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        noHp: string | null;
        asalSekolah: string | null;
        email: string | null;
        alamat: string | null;
        jalur: string | null;
    }>;
    updateStatus(tenantId: string, id: string, dto: UpdatePendaftaranDto): Promise<{
        message: string;
        id: string;
        nama: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        tanggalDaftar: Date;
        catatan: string | null;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        noHp: string | null;
        asalSekolah: string | null;
        email: string | null;
        alamat: string | null;
        jalur: string | null;
    }>;
    private createSantriDariPendaftaran;
    private noPendaftaranLabel;
    private noPendaftaran;
    createPlacementTest(tenantId: string, pendaftaranId: string, dto: CreatePlacementTestDto): Promise<{
        id: string;
        tenantId: string;
        tanggal: Date;
        catatan: string | null;
        mapelId: string | null;
        nilai: number | null;
        hasil: string | null;
        pendaftaranId: string;
    }>;
    getPlacementTest(tenantId: string, pendaftaranId: string): Promise<{
        id: string;
        tenantId: string;
        tanggal: Date;
        catatan: string | null;
        mapelId: string | null;
        nilai: number | null;
        hasil: string | null;
        pendaftaranId: string;
    }>;
    updatePlacementTest(tenantId: string, pendaftaranId: string, dto: CreatePlacementTestDto): Promise<{
        id: string;
        tenantId: string;
        tanggal: Date;
        catatan: string | null;
        mapelId: string | null;
        nilai: number | null;
        hasil: string | null;
        pendaftaranId: string;
    }>;
}
