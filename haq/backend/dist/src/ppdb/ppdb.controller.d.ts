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
    lookup(kode: string): Promise<{
        namaPondok: string;
        kodeTenant: string;
        logoUrl: string;
        gelombang: {
            status: import(".prisma/client").$Enums.StatusGelombangPpdb;
            kuota: number;
            sisaKuota: number;
        };
    }>;
    findAll(tenantId: string, q: QueryPpdbDto): Promise<{
        noPendaftaran: string;
        ujian: {
            id: string;
            catatan: string | null;
            tenantId: string;
            pendaftaranId: string;
            mapelId: string | null;
            nilai: number | null;
            hasil: string | null;
            tanggal: Date;
        };
        id: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        asalSekolah: string | null;
        noHp: string | null;
        email: string | null;
        alamat: string | null;
        jalur: string | null;
        fotoUrl: string | null;
        kartuKeluargaUrl: string | null;
        aktaLahirUrl: string | null;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        catatan: string | null;
        tanggalDaftar: Date;
        tenantId: string;
    }[]>;
    findOne(tenantId: string, id: string): Promise<{
        ujian: {
            id: string;
            catatan: string | null;
            tenantId: string;
            pendaftaranId: string;
            mapelId: string | null;
            nilai: number | null;
            hasil: string | null;
            tanggal: Date;
        };
    } & {
        id: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        asalSekolah: string | null;
        noHp: string | null;
        email: string | null;
        alamat: string | null;
        jalur: string | null;
        fotoUrl: string | null;
        kartuKeluargaUrl: string | null;
        aktaLahirUrl: string | null;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        catatan: string | null;
        tanggalDaftar: Date;
        tenantId: string;
    }>;
    updateStatus(tenantId: string, id: string, dto: UpdatePendaftaranDto): Promise<{
        message: string;
        id: string;
        nama: string;
        jenisKelamin: string;
        tanggalLahir: Date | null;
        asalSekolah: string | null;
        noHp: string | null;
        email: string | null;
        alamat: string | null;
        jalur: string | null;
        fotoUrl: string | null;
        kartuKeluargaUrl: string | null;
        aktaLahirUrl: string | null;
        status: import(".prisma/client").$Enums.StatusPendaftaran;
        catatan: string | null;
        tanggalDaftar: Date;
        tenantId: string;
    }>;
    getPlacementTest(tenantId: string, id: string): Promise<{
        id: string;
        catatan: string | null;
        tenantId: string;
        pendaftaranId: string;
        mapelId: string | null;
        nilai: number | null;
        hasil: string | null;
        tanggal: Date;
    }>;
    createPlacementTest(tenantId: string, id: string, dto: CreatePlacementTestDto): Promise<{
        id: string;
        catatan: string | null;
        tenantId: string;
        pendaftaranId: string;
        mapelId: string | null;
        nilai: number | null;
        hasil: string | null;
        tanggal: Date;
    }>;
    updatePlacementTest(tenantId: string, id: string, dto: CreatePlacementTestDto): Promise<{
        id: string;
        catatan: string | null;
        tenantId: string;
        pendaftaranId: string;
        mapelId: string | null;
        nilai: number | null;
        hasil: string | null;
        tanggal: Date;
    }>;
}
