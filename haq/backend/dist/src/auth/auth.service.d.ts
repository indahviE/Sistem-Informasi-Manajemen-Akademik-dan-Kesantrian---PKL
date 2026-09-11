import { JwtService } from '@nestjs/jwt';
import { PrismaService } from '../prisma/prisma.service';
export declare class AuthService {
    private prisma;
    private jwt;
    constructor(prisma: PrismaService, jwt: JwtService);
    login(kodeTenant: string | undefined, email: string, password: string): Promise<{
        user: {
            id: string;
            nama: string;
            email: string;
            role: import(".prisma/client").$Enums.Role;
            tenant: {
                id: string;
                namaPondok: string;
                kodeTenant: string;
                status: import(".prisma/client").$Enums.TenantStatus;
            };
        };
        accessToken: string;
        refreshToken: string;
    }>;
    refresh(refreshToken: string): Promise<{
        accessToken: string;
        refreshToken: string;
    }>;
    changePassword(userId: string, currentPassword: string, newPassword: string): Promise<{
        message: string;
    }>;
    private generateTokens;
}
