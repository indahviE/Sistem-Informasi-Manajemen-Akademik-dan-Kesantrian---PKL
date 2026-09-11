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
        tenantId: string;
        nama: string;
        userId: string | null;
        email: string | null;
        noHp: string | null;
        hubungan: string;
    })[]>;
    create(tenantId: string, dto: CreateWaliDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        userId: string | null;
        email: string | null;
        noHp: string | null;
        hubungan: string;
    }>;
    update(tenantId: string, id: string, dto: CreateWaliDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        userId: string | null;
        email: string | null;
        noHp: string | null;
        hubungan: string;
    }>;
    linkUser(tenantId: string, dto: LinkWaliUserDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        userId: string | null;
        email: string | null;
        noHp: string | null;
        hubungan: string;
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
            kelasId: string | null;
            nis: string;
            jenisKelamin: string;
            tanggalLahir: Date | null;
            asrama: string | null;
            waliId: string | null;
            status: import(".prisma/client").$Enums.SantriStatus;
            tahunMasuk: number;
        })[];
    } & {
        id: string;
        tenantId: string;
        nama: string;
        userId: string | null;
        email: string | null;
        noHp: string | null;
        hubungan: string;
    }>;
}
