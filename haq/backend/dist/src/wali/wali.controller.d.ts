import { WaliService } from './wali.service';
import { RequestUser } from '../common/decorators/current-user.decorator';
import { CreateWaliDto, LinkWaliUserDto } from './dto/wali.dto';
export declare class WaliController {
    private waliService;
    constructor(waliService: WaliService);
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
    update(tenantId: string, id: string, dto: CreateWaliDto): Promise<{
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
    myProfile(user: RequestUser): Promise<{
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
}
