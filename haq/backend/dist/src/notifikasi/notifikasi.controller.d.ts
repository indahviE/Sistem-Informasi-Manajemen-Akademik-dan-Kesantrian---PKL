import { NotifikasiService } from './notifikasi.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
export declare class NotifikasiController {
    private notifikasiService;
    constructor(notifikasiService: NotifikasiService);
    myNotifikasis(user: RequestUser, tenantId: string | undefined): Promise<{
        id: string;
        tenantId: string;
        tanggal: Date;
        jenis: import(".prisma/client").$Enums.JenisNotifikasi;
        pesan: string;
        statusBaca: boolean;
        userId: string | null;
    }[]>;
    unreadCount(user: RequestUser, tenantId: string | undefined): Promise<number>;
    markRead(user: RequestUser, id: string): Promise<import(".prisma/client").Prisma.BatchPayload>;
    markAllRead(user: RequestUser, tenantId: string | undefined): Promise<import(".prisma/client").Prisma.BatchPayload>;
}
