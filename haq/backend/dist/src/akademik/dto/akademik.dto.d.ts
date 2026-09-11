import { AbsensiStatus, JenisNilai } from '@prisma/client';
export declare class CreateAbsensiDto {
    santriId: string;
    kelasId?: string;
    mapelId?: string;
    tanggal: string;
    status: AbsensiStatus;
    catatan?: string;
}
export declare class BulkAbsensiDto {
    kelasId: string;
    mapelId?: string;
    tanggal: string;
    items: {
        santriId: string;
        status: AbsensiStatus;
        catatan?: string;
    }[];
}
export declare class CreateNilaiDto {
    santriId: string;
    mapelId: string;
    jenis: JenisNilai;
    nilai: number;
    keterangan?: string;
    tanggal: string;
}
export declare class CreateTahfidzDto {
    santriId: string;
    juz: number;
    halaman: number;
    catatanUstadz?: string;
    tanggalSetor: string;
}
export declare class QueryAbsensiDto {
    santriId?: string;
    kelasId?: string;
    startDate?: string;
    endDate?: string;
}
