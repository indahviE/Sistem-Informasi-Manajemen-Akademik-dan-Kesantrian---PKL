import { PrismaService } from '../prisma/prisma.service';
import { CreateWaliDto, LinkWaliUserDto } from './dto/wali.dto';
export declare class WaliService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(tenantId: string): Promise<({
        user: {
            id: string;
            email: string;
        };
        _count: {
            santris: number;
        };
    } & {
        id: string;
        tenantId: string;
        nama: string;
        email: string | null;
        noHp: string | null;
        userId: string | null;
        hubungan: string;
    })[]>;
    create(tenantId: string, dto: CreateWaliDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        email: string | null;
        noHp: string | null;
        userId: string | null;
        hubungan: string;
    }>;
    update(tenantId: string, id: string, dto: Partial<CreateWaliDto>): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        email: string | null;
        noHp: string | null;
        userId: string | null;
        hubungan: string;
    }>;
    linkUser(tenantId: string, dto: LinkWaliUserDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        email: string | null;
        noHp: string | null;
        userId: string | null;
        hubungan: string;
    }>;
    myProfile(userId: string): Promise<{
        santris: ({
            kelas: {
                namaKelas: string;
            };
        } & {
            id: string;
            tenantId: string;
            nama: string;
            status: import(".prisma/client").$Enums.SantriStatus;
            nis: string;
            jenisKelamin: string;
            tanggalLahir: Date | null;
            kelasId: string | null;
            asrama: string | null;
            waliId: string | null;
            tahunMasuk: number;
        })[];
    } & {
        id: string;
        tenantId: string;
        nama: string;
        email: string | null;
        noHp: string | null;
        userId: string | null;
        hubungan: string;
    }>;
    getSantriIds(userId: string): Promise<string[]>;
}
