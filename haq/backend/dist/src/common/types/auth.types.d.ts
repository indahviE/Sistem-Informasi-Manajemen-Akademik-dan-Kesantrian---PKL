import { Role } from '@prisma/client';
export interface JwtPayload {
    sub: string;
    email: string;
    role: Role;
    tenantId?: string;
    tenantKode?: string;
    tenantStatus?: string;
}
export interface AuthenticatedUser extends JwtPayload {
    userId: string;
}
