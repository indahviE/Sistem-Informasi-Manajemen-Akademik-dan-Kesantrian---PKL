export declare class CreateKonselingDto {
    santriId: string;
    tanggal?: string;
    konselorId?: string;
    topik: string;
    catatan: string;
    tindakLanjut?: string;
    privat?: boolean;
}
export declare class UpdateKonselingDto {
    tanggal?: string;
    konselorId?: string;
    topik?: string;
    catatan?: string;
    tindakLanjut?: string;
    privat?: boolean;
}
