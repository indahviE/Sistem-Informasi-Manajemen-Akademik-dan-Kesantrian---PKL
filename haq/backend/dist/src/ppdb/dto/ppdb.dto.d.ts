import { StatusPendaftaran } from '@prisma/client';
export declare class DaftarPpdbDto {
    kodeTenant: string;
    nama: string;
    jenisKelamin: string;
    tanggalLahir?: string;
    asalSekolah?: string;
    noHp?: string;
    email?: string;
    alamat?: string;
    jalur?: string;
}
export declare class UpdatePendaftaranDto {
    status?: StatusPendaftaran;
    catatan?: string;
}
export declare class QueryPpdbDto {
    status?: string;
    q?: string;
}
export declare class CreatePlacementTestDto {
    mapelId?: string;
    nilai?: number;
    hasil?: string;
    catatan?: string;
    tanggal?: string;
}
