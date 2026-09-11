import { ConfigService } from '@nestjs/config';
import { Strategy } from 'passport-jwt';
import { PrismaService } from '../../prisma/prisma.service';
import { JwtPayload } from '../../common/types/auth.types';
declare const JwtStrategy_base: new (...args: any[]) => Strategy;
export declare class JwtStrategy extends JwtStrategy_base {
    private prisma;
    constructor(config: ConfigService, prisma: PrismaService);
    validate(payload: JwtPayload): Promise<{
        userId: string;
        email: string;
        nama: string;
        role: import(".prisma/client").$Enums.Role;
        tenantId: string;
        tenantKode: string;
        tenantStatus: import(".prisma/client").$Enums.TenantStatus;
    }>;
}
export {};
