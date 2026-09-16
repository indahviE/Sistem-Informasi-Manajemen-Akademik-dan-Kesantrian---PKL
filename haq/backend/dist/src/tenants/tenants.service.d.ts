import { PrismaService } from '../prisma/prisma.service';
import { TenantStatus } from '@prisma/client';
import { SignupTenantDto, UpdateBrandingDto } from './dto/tenant.dto';
export declare class TenantsService {
    private prisma;
    constructor(prisma: PrismaService);
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
        tanggalDaftar: Date;
        kodeTenant: string;
        namaPondok: string;
        logoUrl: string | null;
        warnaTema: string | null;
        kuotaSantriPpdb: number | null;
        statusGelombangPpdb: import(".prisma/client").$Enums.StatusGelombangPpdb;
        adminAwalId: string | null;
    }[]>;
    approve(tenantId: string): Promise<{
        message: string;
        id: string;
    }>;
    suspend(tenantId: string): Promise<{
        message: string;
    }>;
    getByTenantId(tenantId: string): Promise<{
        _count: {
            users: number;
            santris: number;
            ustadzs: number;
            kelas: number;
        };
    } & {
        id: string;
        status: import(".prisma/client").$Enums.TenantStatus;
        tanggalDaftar: Date;
        kodeTenant: string;
        namaPondok: string;
        logoUrl: string | null;
        warnaTema: string | null;
        kuotaSantriPpdb: number | null;
        statusGelombangPpdb: import(".prisma/client").$Enums.StatusGelombangPpdb;
        adminAwalId: string | null;
    }>;
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
        tanggalDaftar: Date;
        kodeTenant: string;
        namaPondok: string;
        logoUrl: string;
        warnaTema: string;
    }>;
    updateBranding(tenantId: string, dto: UpdateBrandingDto): Promise<{
        id: string;
        namaPondok: string;
        logoUrl: string;
        warnaTema: string;
    }>;
}
