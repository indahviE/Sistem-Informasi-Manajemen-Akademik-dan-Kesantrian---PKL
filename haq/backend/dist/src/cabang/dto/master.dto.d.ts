import { JenisUstadz } from '@prisma/client';
export declare class CreateUstadzDto {
    nama: string;
    jenis: JenisUstadz;
    noHp?: string;
    userId?: string;
}
export declare class UpdateUstadzDto {
    nama?: string;
    jenis?: JenisUstadz;
    noHp?: string;
}
export declare class CreateKelasDto {
    namaKelas: string;
    tingkat: string;
    waliKelasId?: string;
    tahunAjaranId?: string;
}
export declare class UpdateKelasDto {
    namaKelas?: string;
    tingkat?: string;
    waliKelasId?: string;
    tahunAjaranId?: string;
}
export declare class CreateMapelDto {
    namaMapel: string;
    kode?: string;
    jenis?: string;
}
export declare class UpdateMapelDto {
    namaMapel?: string;
    kode?: string;
    jenis?: string;
}
export declare class CreateTahunAjaranDto {
    nama: string;
}
