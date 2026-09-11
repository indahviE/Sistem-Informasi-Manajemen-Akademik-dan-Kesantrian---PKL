export declare class CreateKurikulumDto {
    nama: string;
    tahunAjaranId?: string;
    deskripsi?: string;
    aktif?: boolean;
}
export declare class UpdateKurikulumDto {
    nama?: string;
    tahunAjaranId?: string;
    deskripsi?: string;
    aktif?: boolean;
}
export declare class CreateSilabusDto {
    judul: string;
    kurikulumId?: string;
    mapelId?: string;
    kompetensiDasar?: string;
    materiPokok?: string;
    alokasiWaktu?: string;
    fileUrl?: string;
}
export declare class UpdateSilabusDto {
    judul?: string;
    kurikulumId?: string;
    mapelId?: string;
    kompetensiDasar?: string;
    materiPokok?: string;
    alokasiWaktu?: string;
    fileUrl?: string;
}
export declare class CreateRppDto {
    judul: string;
    mapelId?: string;
    pertemuan?: number;
    tujuan?: string;
    kegiatan?: string;
    penilaian?: string;
    fileUrl?: string;
}
export declare class UpdateRppDto {
    judul?: string;
    mapelId?: string;
    pertemuan?: number;
    tujuan?: string;
    kegiatan?: string;
    penilaian?: string;
    fileUrl?: string;
}
