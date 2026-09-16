import { PrismaService } from '../prisma/prisma.service';
import { AssignSubscriptionDto, CreateInvoiceDto, CreatePaketDto, UpdateInvoiceDto, UpdatePaketDto, UpdateSubscriptionDto } from './dto/billing.dto';
export declare class BillingService {
    private prisma;
    constructor(prisma: PrismaService);
    findAllPaket(): Promise<{
        id: string;
        nama: string;
        createdAt: Date;
        aktif: boolean;
        harga: number;
        limitSantri: number;
        fitur: import("@prisma/client/runtime/library").JsonValue | null;
    }[]>;
    createPaket(dto: CreatePaketDto): Promise<{
        id: string;
        nama: string;
        createdAt: Date;
        aktif: boolean;
        harga: number;
        limitSantri: number;
        fitur: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
    updatePaket(id: string, dto: UpdatePaketDto): Promise<{
        id: string;
        nama: string;
        createdAt: Date;
        aktif: boolean;
        harga: number;
        limitSantri: number;
        fitur: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
    removePaket(id: string): Promise<{
        id: string;
        nama: string;
        createdAt: Date;
        aktif: boolean;
        harga: number;
        limitSantri: number;
        fitur: import("@prisma/client/runtime/library").JsonValue | null;
    }>;
    findAllSubscription(isSuperAdmin: boolean, tenantId?: string): Promise<({
        tenant: {
            kodeTenant: string;
            namaPondok: string;
        };
        paket: {
            id: string;
            nama: string;
            createdAt: Date;
            aktif: boolean;
            harga: number;
            limitSantri: number;
            fitur: import("@prisma/client/runtime/library").JsonValue | null;
        };
    } & {
        id: string;
        status: import(".prisma/client").$Enums.StatusSubscription;
        tenantId: string;
        paketId: string;
        tanggalAkhir: Date | null;
        tanggalMulai: Date;
    })[]>;
    assignSubscription(dto: AssignSubscriptionDto): Promise<{
        id: string;
        status: import(".prisma/client").$Enums.StatusSubscription;
        tenantId: string;
        paketId: string;
        tanggalAkhir: Date | null;
        tanggalMulai: Date;
    }>;
    updateSubscription(id: string, dto: UpdateSubscriptionDto): Promise<{
        id: string;
        status: import(".prisma/client").$Enums.StatusSubscription;
        tenantId: string;
        paketId: string;
        tanggalAkhir: Date | null;
        tanggalMulai: Date;
    }>;
    findAllInvoice(isSuperAdmin: boolean, tenantId?: string): Promise<({
        tenant: {
            kodeTenant: string;
            namaPondok: string;
        };
    } & {
        id: string;
        status: import(".prisma/client").$Enums.StatusInvoice;
        tenantId: string;
        createdAt: Date;
        jumlah: number;
        metodeBayar: string | null;
        noInvoice: string;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
    })[]>;
    createInvoice(dto: CreateInvoiceDto): Promise<{
        id: string;
        status: import(".prisma/client").$Enums.StatusInvoice;
        tenantId: string;
        createdAt: Date;
        jumlah: number;
        metodeBayar: string | null;
        noInvoice: string;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
    }>;
    updateInvoice(id: string, dto: UpdateInvoiceDto): Promise<{
        id: string;
        status: import(".prisma/client").$Enums.StatusInvoice;
        tenantId: string;
        createdAt: Date;
        jumlah: number;
        metodeBayar: string | null;
        noInvoice: string;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
    }>;
}
