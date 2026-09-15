import { PpdbService } from './ppdb.service';
import { CreatePlacementTestDto, DaftarPpdbDto, QueryPpdbDto, UpdatePendaftaranDto } from './dto/ppdb.dto';
export declare class PpdbController {
    private ppdbService;
    constructor(ppdbService: PpdbService);
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
    getPlacementTest(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        tanggal: Date;
        catatan: string | null;
        mapelId: string | null;
        nilai: number | null;
        hasil: string | null;
        pendaftaranId: string;
    }>;
    createPlacementTest(tenantId: string, id: string, dto: CreatePlacementTestDto): Promise<{
        id: string;
        tenantId: string;
        tanggal: Date;
        catatan: string | null;
        mapelId: string | null;
        nilai: number | null;
        hasil: string | null;
        pendaftaranId: string;
    }>;
    updatePlacementTest(tenantId: string, id: string, dto: CreatePlacementTestDto): Promise<{
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
