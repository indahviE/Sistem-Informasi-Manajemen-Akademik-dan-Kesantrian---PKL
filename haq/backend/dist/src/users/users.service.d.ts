import { PrismaService } from '../prisma/prisma.service';
import { CreateUserDto, UpdateUserDto } from './dto/user.dto';
import { Role } from '@prisma/client';
export declare class UsersService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(tenantId: string, role?: Role): Promise<{
        id: string;
        nama: string;
        email: string;
        status: import(".prisma/client").$Enums.UserStatus;
        role: import(".prisma/client").$Enums.Role;
        createdAt: Date;
    }[]>;
    create(tenantId: string, dto: CreateUserDto): Promise<{
        id: string;
        nama: string;
        email: string;
        role: import(".prisma/client").$Enums.Role;
    }>;
    update(tenantId: string, id: string, dto: UpdateUserDto): Promise<{
        id: string;
        nama: string;
        email: string;
        role: import(".prisma/client").$Enums.Role;
    }>;
    remove(tenantId: string, id: string): Promise<{
        message: string;
    }>;
    toggleStatus(tenantId: string, id: string): Promise<{
        status: import(".prisma/client").$Enums.UserStatus;
    }>;
}
