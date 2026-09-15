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
        tanggalAkhir: Date | null;
        tanggalMulai: Date;
    })[]>;
    assignSubscription(dto: AssignSubscriptionDto): Promise<{
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusSubscription;
        paketId: string;
        tanggalAkhir: Date | null;
        tanggalMulai: Date;
    }>;
    updateSubscription(id: string, dto: UpdateSubscriptionDto): Promise<{
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusSubscription;
        paketId: string;
        tanggalAkhir: Date | null;
        tanggalMulai: Date;
    }>;
    findAllInvoice(user: RequestUser, tenantId?: string): Promise<({
        tenant: {
            kodeTenant: string;
            namaPondok: string;
        };
    } & {
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusInvoice;
        createdAt: Date;
        jumlah: number;
        metodeBayar: string | null;
        noInvoice: string;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
    })[]>;
    createInvoice(dto: CreateInvoiceDto): Promise<{
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusInvoice;
        createdAt: Date;
        jumlah: number;
        metodeBayar: string | null;
        noInvoice: string;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
    }>;
    updateInvoice(id: string, dto: UpdateInvoiceDto): Promise<{
        id: string;
        tenantId: string;
        status: import(".prisma/client").$Enums.StatusInvoice;
        createdAt: Date;
        jumlah: number;
        metodeBayar: string | null;
        noInvoice: string;
        tanggalJatuhTempo: Date | null;
        tanggalBayar: Date | null;
    }>;
}
