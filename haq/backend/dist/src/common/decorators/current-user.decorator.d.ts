import { Role } from '@prisma/client';
export interface RequestUser {
    userId: string;
    email: string;
    role: Role;
    tenantId?: string;
    tenantKode?: string;
    tenantStatus?: string;
}
export declare const CurrentUser: (...dataOrPipes: (import("@nestjs/common").PipeTransform<any, any> | import("@nestjs/common").Type<import("@nestjs/common").PipeTransform<any, any>> | keyof RequestUser)[]) => ParameterDecorator;
export declare const TenantId: (...dataOrPipes: unknown[]) => ParameterDecorator;
