import { WaliService } from './wali.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateWaliDto, LinkWaliUserDto } from './dto/wali.dto';
export declare class WaliController {
    private waliService;
    constructor(waliService: WaliService);
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
        noHp: string | null;
        email: string | null;
        hubungan: string;
        userId: string | null;
    })[]>;
    create(tenantId: string, dto: CreateWaliDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        noHp: string | null;
        email: string | null;
        hubungan: string;
        userId: string | null;
    }>;
    update(tenantId: string, id: string, dto: CreateWaliDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        noHp: string | null;
        email: string | null;
        hubungan: string;
        userId: string | null;
    }>;
    linkUser(tenantId: string, dto: LinkWaliUserDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        noHp: string | null;
        email: string | null;
        hubungan: string;
        userId: string | null;
    }>;
    myProfile(user: RequestUser): Promise<{
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
        noHp: string | null;
        email: string | null;
        hubungan: string;
        userId: string | null;
    }>;
}
