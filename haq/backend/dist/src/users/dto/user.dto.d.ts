import { Role } from '@prisma/client';
export declare class CreateUserDto {
    nama: string;
    email: string;
    password: string;
    role: Role;
    waliSantriId?: string;
    ustadzId?: string;
}
export declare class UpdateUserDto {
    nama?: string;
    email?: string;
    role?: Role;
}
