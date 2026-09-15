import { TenantsService } from './tenants.service';
import { TenantStatus } from '@prisma/client';
import { ApproveTenantDto, SignupTenantDto, UpdateBrandingDto } from './dto/tenant.dto';
export declare class TenantsController {
    private tenantsService;
    constructor(tenantsService: TenantsService);
    signup(dto: SignupTenantDto): Promise<{
        id: string;
        namaPondok: string;
        kodeTenant: string;
        status: import(".prisma/client").$Enums.TenantStatus;
        message: string;
    }>;
    findAll(status?: TenantStatus): Promise<{
        jumlahUser: number;
        jumlahSantri: number;
        jumlahKelas: number;
        _count: {
            users: number;
            santris: number;
            kelas: number;
        };
        id: string;
        status: import(".prisma/client").$Enums.TenantStatus;
        kodeTenant: string;
        namaPondok: string;
        logoUrl: string | null;
        warnaTema: string | null;
        adminAwalId: string | null;
        tanggalDaftar: Date;
    }[]>;
    approve(dto: ApproveTenantDto): Promise<{
        message: string;
        id: string;
    }>;
    suspend(dto: ApproveTenantDto): Promise<{
        message: string;
    }>;
    getMyTenant(tenantId: string | undefined): Promise<{
        _count: {
            users: number;
            santris: number;
            ustadzs: number;
            kelas: number;
        };
    } & {
        id: string;
        status: import(".prisma/client").$Enums.TenantStatus;
        kodeTenant: string;
        namaPondok: string;
        logoUrl: string | null;
        warnaTema: string | null;
        adminAwalId: string | null;
        tanggalDaftar: Date;
    }> | {
        note: string;
    };
    getBranding(kodeTenant: string): Promise<{
        status: import(".prisma/client").$Enums.TenantStatus;
        kodeTenant: string;
        namaPondok: string;
        logoUrl: string;
        warnaTema: string;
    }>;
    getMyBranding(tenantId: string): Promise<{
        id: string;
        status: import(".prisma/client").$Enums.TenantStatus;
        kodeTenant: string;
        namaPondok: string;
        logoUrl: string;
        warnaTema: string;
        tanggalDaftar: Date;
    }>;
    updateBranding(tenantId: string, dto: UpdateBrandingDto): Promise<{
        id: string;
        namaPondok: string;
        logoUrl: string;
        warnaTema: string;
    }>;
}
