export declare class CreateSantriDto {
    nis: string;
    nama: string;
    jenisKelamin: string;
    tanggalLahir?: string;
    kelasId?: string;
    asrama?: string;
    waliId?: string;
    tahunMasuk: number;
}
export declare class UpdateSantriDto {
    nama?: string;
    jenisKelamin?: string;
    tanggalLahir?: string;
    kelasId?: string;
    asrama?: string;
    waliId?: string;
}
export declare class QuerySantriDto {
    kelasId?: string;
    search?: string;
    page?: number;
    perPage?: number;
}
