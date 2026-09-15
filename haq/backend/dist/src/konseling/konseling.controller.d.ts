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
    update(tenantId: string, id: string, dto: UpdateKonselingDto): Promise<{
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
    remove(tenantId: string, id: string): Promise<{
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
