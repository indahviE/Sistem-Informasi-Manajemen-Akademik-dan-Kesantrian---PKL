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
            mapelId: string | null;
            tanggal: Date;
            nilai: number | null;
            catatan: string | null;
            hasil: string | null;
            pendaftaranId: string;
        };
        id: string;
        tenantId: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        catatan: string | null;
        email: string | null;
        noHp: string | null;
        tanggalDaftar: Date;
        asalSekolah: string | null;
        alamat: string | null;
        jalur: string | null;
    }[]>;
    findOne(tenantId: string, id: string): Promise<{
        ujian: {
            id: string;
            tenantId: string;
            mapelId: string | null;
            tanggal: Date;
            nilai: number | null;
            catatan: string | null;
            hasil: string | null;
            pendaftaranId: string;
        };
    } & {
        id: string;
        tenantId: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        catatan: string | null;
        email: string | null;
        noHp: string | null;
        tanggalDaftar: Date;
        asalSekolah: string | null;
        alamat: string | null;
        jalur: string | null;
    }>;
    updateStatus(tenantId: string, id: string, dto: UpdatePendaftaranDto): Promise<{
        message: string;
        id: string;
        tenantId: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        catatan: string | null;
        email: string | null;
        noHp: string | null;
        tanggalDaftar: Date;
        asalSekolah: string | null;
        alamat: string | null;
        jalur: string | null;
    }>;
    private createSantriDariPendaftaran;
    private noPendaftaranLabel;
    private noPendaftaran;
    createPlacementTest(tenantId: string, pendaftaranId: string, dto: CreatePlacementTestDto): Promise<{
        id: string;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date;
        nilai: number | null;
        catatan: string | null;
        hasil: string | null;
        pendaftaranId: string;
    }>;
    getPlacementTest(tenantId: string, pendaftaranId: string): Promise<{
        id: string;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date;
        nilai: number | null;
        catatan: string | null;
        hasil: string | null;
        pendaftaranId: string;
    }>;
    updatePlacementTest(tenantId: string, pendaftaranId: string, dto: CreatePlacementTestDto): Promise<{
        id: string;
        tenantId: string;
        mapelId: string | null;
        tanggal: Date;
        nilai: number | null;
        catatan: string | null;
        hasil: string | null;
        pendaftaranId: string;
    }>;
}
