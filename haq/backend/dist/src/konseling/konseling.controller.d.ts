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
        catatan: string;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        tindakLanjut: string | null;
        updatedAt: Date;
        konselorId: string | null;
        topik: string;
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
        catatan: string;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        tindakLanjut: string | null;
        updatedAt: Date;
        konselorId: string | null;
        topik: string;
        privat: boolean;
    }>;
    update(tenantId: string, id: string, dto: UpdateKonselingDto): Promise<{
        id: string;
        catatan: string;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        tindakLanjut: string | null;
        updatedAt: Date;
        konselorId: string | null;
        topik: string;
        privat: boolean;
    }>;
    remove(tenantId: string, id: string): Promise<{
        id: string;
        catatan: string;
        tenantId: string;
        tanggal: Date;
        createdAt: Date;
        santriId: string;
        tindakLanjut: string | null;
        updatedAt: Date;
        konselorId: string | null;
        topik: string;
        privat: boolean;
    }>;
}
