import { PrismaService } from '../prisma/prisma.service';
export declare class NotifikasiService {
    private prisma;
    constructor(prisma: PrismaService);
    myNotifikasis(userId: string, tenantId: string | undefined): Promise<{
        id: string;
        tenantId: string;
        jenis: import(".prisma/client").$Enums.JenisNotifikasi;
        tanggal: Date;
        userId: string | null;
        pesan: string;
        statusBaca: boolean;
    }[]>;
    unreadCount(userId: string, tenantId: string | undefined): Promise<number>;
    markRead(userId: string, id: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    markAllRead(userId: string, tenantId: string | undefined): Promise<import(".prisma/client").Prisma.BatchPayload>;
}
