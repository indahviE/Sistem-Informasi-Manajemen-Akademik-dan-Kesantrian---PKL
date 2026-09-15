import { PrismaService } from '../prisma/prisma.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKonselingDto, UpdateKonselingDto } from './dto/konseling.dto';
export declare class KonselingService {
    private prisma;
    constructor(prisma: PrismaService);
    private assertSantri;
    findAllKonseling(tenantId: string, santriId?: string): Promise<({
        santri: {
            id: string;
            nama: string;
            kelas: {
                namaKelas: string;
            };
            nis: string;
        };
        konselor: {
            id: string;
            nama: string;
        };
    } & {
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        konselorId: string | null;
        topik: string;
        catatan: string;
        tindakLanjut: string | null;
        privat: boolean;
        updatedAt: Date;
    })[]>;
    createKonseling(tenantId: string, dto: CreateKonselingDto, user: RequestUser): Promise<{
        santri: {
            id: string;
            nama: string;
            nis: string;
        };
        konselor: {
            id: string;
            nama: string;
        };
    } & {
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        konselorId: string | null;
        topik: string;
        catatan: string;
        tindakLanjut: string | null;
        privat: boolean;
        updatedAt: Date;
    }>;
    updateKonseling(tenantId: string, id: string, dto: UpdateKonselingDto): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        konselorId: string | null;
        topik: string;
        catatan: string;
        tindakLanjut: string | null;
        privat: boolean;
        updatedAt: Date;
    }>;
    removeKonseling(tenantId: string, id: string): Promise<{
        id: string;
        createdAt: Date;
        tenantId: string;
        santriId: string;
        tanggal: Date;
        konselorId: string | null;
        topik: string;
        catatan: string;
        tindakLanjut: string | null;
        privat: boolean;
        updatedAt: Date;
    }>;
}
