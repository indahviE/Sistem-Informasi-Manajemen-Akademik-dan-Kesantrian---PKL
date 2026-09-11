import { BillingService } from './billing.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { AssignSubscriptionDto, CreateInvoiceDto, CreatePaketDto, UpdateInvoiceDto, UpdatePaketDto, UpdateSubscriptionDto } from './dto/billing.dto';
export declare class BillingController {
    private billingService;
    constructor(billingService: BillingService);
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
    findAllSubscription(user: RequestUser, tenantId?: string): Promise<({
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
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusSubscription;
        paketId: string;
        tanggalMulai: Date;
        tanggalAkhir: Date | null;
    })[]>;
    assignSubscription(dto: AssignSubscriptionDto): Promise<{
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusSubscription;
        paketId: string;
        tanggalMulai: Date;
        tanggalAkhir: Date | null;
    }>;
    updateSubscription(id: string, dto: UpdateSubscriptionDto): Promise<{
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusSubscription;
        paketId: string;
        tanggalMulai: Date;
        tanggalAkhir: Date | null;
    }>;
    findAllInvoice(user: RequestUser, tenantId?: string): Promise<({
        tenant: {
            kodeTenant: string;
            namaPondok: string;
        };
    } & {
        id: string;
        tenantId: string;
        createdAt: Date;
        status: import(".prisma/client").$Enums.StatusInvoice;
        noInvoice: string;
        jumlah: number;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
        metodeBayar: string | null;
    })[]>;
    createInvoice(dto: CreateInvoiceDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        status: import(".prisma/client").$Enums.StatusInvoice;
        noInvoice: string;
        jumlah: number;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
        metodeBayar: string | null;
    }>;
    updateInvoice(id: string, dto: UpdateInvoiceDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        status: import(".prisma/client").$Enums.StatusInvoice;
        noInvoice: string;
        jumlah: number;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
        metodeBayar: string | null;
    }>;
}
