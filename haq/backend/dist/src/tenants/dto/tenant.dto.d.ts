export declare class SignupTenantDto {
    namaPondok: string;
    kodeTenant: string;
    logoUrl?: string;
    adminNama: string;
    adminEmail: string;
    adminPassword: string;
}
export declare class UpdateBrandingDto {
    namaPondok?: string;
    logoUrl?: string;
    warnaTema?: string;
}
export declare class ApproveTenantDto {
    tenantId: string;
}
export declare class RejectTenantDto {
    tenantId: string;
    alasan?: string;
}
