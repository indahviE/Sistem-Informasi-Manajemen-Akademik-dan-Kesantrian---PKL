import { JenisPerizinan, StatusApproval, StatusKesehatan } from '@prisma/client';
export declare class CreatePelanggaranDto {
    santriId: string;
    jenisPelanggaran: string;
    poin: number;
    tanggal: string;
    pelaporId?: string;
    tindakLanjut?: string;
}
export declare class UpdatePelanggaranDto {
    jenisPelanggaran?: string;
    poin?: number;
    tindakLanjut?: string;
    status?: string;
}
export declare class CreatePerizinanDto {
    santriId: string;
    jenis: JenisPerizinan;
    tanggalKeluar: string;
    tanggalKembali?: string;
    alasan: string;
    catatan?: string;
}
export declare class UpdatePerizinanDto {
    statusApproval: StatusApproval;
    disetujuiOleh?: string;
    tanggalKembali?: string;
    catatan?: string;
}
export declare class CreateKesehatanDto {
    santriId: string;
    keluhan: string;
    diagnosa?: string;
    tindakan?: string;
    obat?: string;
    tempat?: string;
    tanggal: string;
    status?: StatusKesehatan;
}
export declare class CreateKunjunganDto {
    santriId: string;
    waliId?: string;
    tanggal: string;
    catatan?: string;
}
export declare class CreateTataTertibDto {
    judul: string;
    isi: string;
}
export declare class QueryKesantrianDto {
    santriId?: string;
    kelasId?: string;
}
