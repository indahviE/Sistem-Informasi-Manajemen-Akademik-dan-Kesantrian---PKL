import { Role } from '@prisma/client';
export interface RequestUser {
    userId: string;
    email: string;
    role: Role;
    tenantId?: string;
    tenantKode?: string;
    tenantStatus?: string;
}
export declare const CurrentUser: (...dataOrPipes: (keyof RequestUser | import("@nestjs/common").PipeTransform<any, any> | import("@nestjs/common").Type<import("@nestjs/common").PipeTransform<any, any>>)[]) => ParameterDecorator;
export declare const TenantId: (...dataOrPipes: unknown[]) => ParameterDecorator;
