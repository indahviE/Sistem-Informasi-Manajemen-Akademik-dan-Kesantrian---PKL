import { StatusInvoice, StatusSubscription } from '@prisma/client';
export declare class CreatePaketDto {
    nama: string;
    harga: number;
    limitSantri: number;
    fitur?: any;
}
export declare class UpdatePaketDto {
    nama?: string;
    harga?: number;
    limitSantri?: number;
    fitur?: any;
    aktif?: boolean;
}
export declare class AssignSubscriptionDto {
    tenantId: string;
    paketId: string;
}
export declare class UpdateSubscriptionDto {
    status?: StatusSubscription;
    tanggalAkhir?: Date;
}
export declare class CreateInvoiceDto {
    tenantId: string;
    jumlah: number;
    metodeBayar?: string;
}
export declare class UpdateInvoiceDto {
    status?: StatusInvoice;
    metodeBayar?: string;
}
