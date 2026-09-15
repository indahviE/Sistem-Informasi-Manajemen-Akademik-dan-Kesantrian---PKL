import { BillingService } from './billing.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { AssignSubscriptionDto, CreateInvoiceDto, CreatePaketDto, UpdateInvoiceDto, UpdatePaketDto, UpdateSubscriptionDto } from './dto/billing.dto';
export declare class BillingController {
    private billingService;
    constructor(billingService: BillingService);
    findAllPaket(): Promise<{
        id: string;
        nama: string;
        harga: number;
        limitSantri: number;
        fitur: import("@prisma/client/runtime/library").JsonValue | null;
        aktif: boolean;
        createdAt: Date;
    }[]>;
    createPaket(dto: CreatePaketDto): Promise<{
        id: string;
        nama: string;
        harga: number;
        limitSantri: number;
        fitur: import("@prisma/client/runtime/library").JsonValue | null;
        aktif: boolean;
        createdAt: Date;
    }>;
    updatePaket(id: string, dto: UpdatePaketDto): Promise<{
        id: string;
        nama: string;
        harga: number;
        limitSantri: number;
        fitur: import("@prisma/client/runtime/library").JsonValue | null;
        aktif: boolean;
        createdAt: Date;
    }>;
    removePaket(id: string): Promise<{
        id: string;
        nama: string;
        harga: number;
        limitSantri: number;
        fitur: import("@prisma/client/runtime/library").JsonValue | null;
        aktif: boolean;
        createdAt: Date;
    }>;
    findAllSubscription(user: RequestUser, tenantId?: string): Promise<({
        paket: {
            id: string;
            nama: string;
            harga: number;
            limitSantri: number;
            fitur: import("@prisma/client/runtime/library").JsonValue | null;
            aktif: boolean;
            createdAt: Date;
        };
        tenant: {
            kodeTenant: string;
            namaPondok: string;
        };
    } & {
        id: string;
        tenantId: string;
        paketId: string;
        tanggalMulai: Date;
        tanggalAkhir: Date | null;
        status: import(".prisma/client").$Enums.StatusSubscription;
    })[]>;
    assignSubscription(dto: AssignSubscriptionDto): Promise<{
        id: string;
        tenantId: string;
        paketId: string;
        tanggalMulai: Date;
        tanggalAkhir: Date | null;
        status: import(".prisma/client").$Enums.StatusSubscription;
    }>;
    updateSubscription(id: string, dto: UpdateSubscriptionDto): Promise<{
        id: string;
        tenantId: string;
        paketId: string;
        tanggalMulai: Date;
        tanggalAkhir: Date | null;
        status: import(".prisma/client").$Enums.StatusSubscription;
    }>;
    findAllInvoice(user: RequestUser, tenantId?: string): Promise<({
        tenant: {
            kodeTenant: string;
            namaPondok: string;
        };
    } & {
        id: string;
        createdAt: Date;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusInvoice;
        noInvoice: string;
        jumlah: number;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
        metodeBayar: string | null;
    })[]>;
    createInvoice(dto: CreateInvoiceDto): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusInvoice;
        noInvoice: string;
        jumlah: number;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
        metodeBayar: string | null;
    }>;
    updateInvoice(id: string, dto: UpdateInvoiceDto): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusInvoice;
        noInvoice: string;
        jumlah: number;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
        metodeBayar: string | null;
    }>;
}
