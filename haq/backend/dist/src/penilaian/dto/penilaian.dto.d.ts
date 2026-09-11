export declare class CreateUjianDto {
    nama: string;
    jenis?: string;
    mapelId?: string;
    kelasId?: string;
    tanggal?: string;
    durasiMenit?: number;
}
export declare class UpdateUjianDto {
    nama?: string;
    jenis?: string;
    mapelId?: string;
    kelasId?: string;
    tanggal?: string;
    durasiMenit?: number;
}
export declare class InputNilaiUjianDto {
    santriId: string;
    nilai: number;
    catatan?: string;
}
export declare class CreateRemedialDto {
    santriId: string;
    ujianId?: string;
    mapelId?: string;
    keterangan: string;
    hasil?: string;
    tanggal?: string;
}
export declare class UpdateRemedialDto {
    keterangan?: string;
    hasil?: string;
    tanggal?: string;
}
export declare class GenerateRaporDto {
    santriId: string;
    periode: string;
    status?: string;
}
export declare class CreateKelulusanDto {
    santriId: string;
    status?: string;
    tanggalKelulusan?: string;
    predikat?: string;
    juzYangDiHafal?: number;
    catatan?: string;
}
export declare class UpdateKelulusanDto {
    status?: string;
    tanggalKelulusan?: string;
    predikat?: string;
    juzYangDiHafal?: number;
    catatan?: string;
}
