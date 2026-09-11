import { KonselingService } from './konseling.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateKonselingDto, UpdateKonselingDto } from './dto/konseling.dto';
export declare class KonselingController {
    private konselingService;
    constructor(konselingService: KonselingService);
    findAll(tenantId: string, santriId?: string): Promise<({
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
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        updatedAt: Date;
        santriId: string;
        catatan: string;
        konselorId: string | null;
        topik: string;
        tindakLanjut: string | null;
        privat: boolean;
    })[]>;
    create(tenantId: string, dto: CreateKonselingDto, user: RequestUser): Promise<{
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
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        updatedAt: Date;
        santriId: string;
        catatan: string;
        konselorId: string | null;
        topik: string;
        tindakLanjut: string | null;
        privat: boolean;
    }>;
    update(tenantId: string, id: string, dto: UpdateKonselingDto): Promise<{
        id: string;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        updatedAt: Date;
        santriId: string;
        catatan: string;
        konselorId: string | null;
        topik: string;
        tindakLanjut: string | null;
        privat: boolean;
    }>;
    remove(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        updatedAt: Date;
        santriId: string;
        catatan: string;
        konselorId: string | null;
        topik: string;
        tindakLanjut: string | null;
        privat: boolean;
    }>;
}
