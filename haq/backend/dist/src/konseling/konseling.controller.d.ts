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
        createdAt: Date;
        tanggal: Date;
        santriId: string;
        tindakLanjut: string | null;
        catatan: string;
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
        tenantId: string;
        createdAt: Date;
        tanggal: Date;
        santriId: string;
        tindakLanjut: string | null;
        catatan: string;
        updatedAt: Date;
        konselorId: string | null;
        topik: string;
        privat: boolean;
    }>;
    update(tenantId: string, id: string, dto: UpdateKonselingDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        tanggal: Date;
        santriId: string;
        tindakLanjut: string | null;
        catatan: string;
        updatedAt: Date;
        konselorId: string | null;
        topik: string;
        privat: boolean;
    }>;
    remove(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        tanggal: Date;
        santriId: string;
        tindakLanjut: string | null;
        catatan: string;
        updatedAt: Date;
        konselorId: string | null;
        topik: string;
        privat: boolean;
    }>;
}
