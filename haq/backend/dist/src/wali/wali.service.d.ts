import { PrismaService } from '../prisma/prisma.service';
import { CreateWaliDto, LinkWaliUserDto } from './dto/wali.dto';
export declare class WaliService {
    private prisma;
    constructor(prisma: PrismaService);
    findAll(tenantId: string): Promise<({
        _count: {
            santris: number;
        };
        user: {
            id: string;
            email: string;
        };
    } & {
        id: string;
        nama: string;
        noHp: string | null;
        email: string | null;
        tenantId: string;
        userId: string | null;
        hubungan: string;
    })[]>;
    create(tenantId: string, dto: CreateWaliDto): Promise<{
        id: string;
        nama: string;
        noHp: string | null;
        email: string | null;
        tenantId: string;
        userId: string | null;
        hubungan: string;
    }>;
    update(tenantId: string, id: string, dto: Partial<CreateWaliDto>): Promise<{
        id: string;
        nama: string;
        noHp: string | null;
        email: string | null;
        tenantId: string;
        userId: string | null;
        hubungan: string;
    }>;
    linkUser(tenantId: string, dto: LinkWaliUserDto): Promise<{
        id: string;
        nama: string;
        noHp: string | null;
        email: string | null;
        tenantId: string;
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
            nama: string;
            jenisKelamin: string;
            tanggalLahir: Date | null;
            status: import(".prisma/client").$Enums.SantriStatus;
            tenantId: string;
            nis: string;
            asrama: string | null;
            tahunMasuk: number;
            kelasId: string | null;
            waliId: string | null;
        })[];
    } & {
        id: string;
        nama: string;
        noHp: string | null;
        email: string | null;
        tenantId: string;
        userId: string | null;
        hubungan: string;
    }>;
    getSantriIds(userId: string): Promise<string[]>;
}
