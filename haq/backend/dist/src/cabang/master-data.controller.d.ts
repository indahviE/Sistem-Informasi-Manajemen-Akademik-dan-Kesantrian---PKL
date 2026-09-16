import { MasterDataService } from './master-data.service';
import { CreateKelasDto, CreateMapelDto, CreateTahunAjaranDto, CreateUstadzDto, UpdateKelasDto, UpdateMapelDto, UpdateUstadzDto } from './dto/master.dto';
export declare class MasterDataController {
    private masterService;
    constructor(masterService: MasterDataService);
    findAllUstadz(tenantId: string, jenis?: string): import(".prisma/client").Prisma.PrismaPromise<{
        id: string;
        nama: string;
        noHp: string | null;
        tenantId: string;
        jenis: import(".prisma/client").$Enums.JenisUstadz;
        userId: string | null;
    }[]>;
    createUstadz(tenantId: string, dto: CreateUstadzDto): import(".prisma/client").Prisma.Prisma__UstadzClient<{
        id: string;
        nama: string;
        noHp: string | null;
        tenantId: string;
        jenis: import(".prisma/client").$Enums.JenisUstadz;
        userId: string | null;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    updateUstadz(tenantId: string, id: string, dto: UpdateUstadzDto): Promise<{
        id: string;
        nama: string;
        noHp: string | null;
        tenantId: string;
        jenis: import(".prisma/client").$Enums.JenisUstadz;
        userId: string | null;
    }>;
    removeUstadz(tenantId: string, id: string): Promise<{
        message: string;
    }>;
    findAllKelas(tenantId: string): import(".prisma/client").Prisma.PrismaPromise<({
        tahunAjaran: {
            id: string;
            nama: string;
        };
        _count: {
            santris: number;
        };
        waliKelas: {
            id: string;
            nama: string;
        };
    } & {
        id: string;
        tenantId: string;
        namaKelas: string;
        tingkat: string;
        waliKelasId: string | null;
        tahunAjaranId: string | null;
    })[]>;
    createKelas(tenantId: string, dto: CreateKelasDto): import(".prisma/client").Prisma.Prisma__KelasClient<{
        id: string;
        tenantId: string;
        namaKelas: string;
        tingkat: string;
        waliKelasId: string | null;
        tahunAjaranId: string | null;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    updateKelas(tenantId: string, id: string, dto: UpdateKelasDto): Promise<{
        id: string;
        tenantId: string;
        namaKelas: string;
        tingkat: string;
        waliKelasId: string | null;
        tahunAjaranId: string | null;
    }>;
    removeKelas(tenantId: string, id: string): Promise<{
        message: string;
    }>;
    findAllMapel(tenantId: string): import(".prisma/client").Prisma.PrismaPromise<{
        id: string;
        tenantId: string;
        kode: string | null;
        jenis: string | null;
        namaMapel: string;
    }[]>;
    createMapel(tenantId: string, dto: CreateMapelDto): import(".prisma/client").Prisma.Prisma__MataPelajaranClient<{
        id: string;
        tenantId: string;
        kode: string | null;
        jenis: string | null;
        namaMapel: string;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    updateMapel(tenantId: string, id: string, dto: UpdateMapelDto): Promise<{
        id: string;
        tenantId: string;
        kode: string | null;
        jenis: string | null;
        namaMapel: string;
    }>;
    removeMapel(tenantId: string, id: string): Promise<{
        message: string;
    }>;
    findAllTahunAjaran(tenantId: string): import(".prisma/client").Prisma.PrismaPromise<{
        id: string;
        nama: string;
        tenantId: string;
        aktif: boolean;
    }[]>;
    createTahunAjaran(tenantId: string, dto: CreateTahunAjaranDto): import(".prisma/client").Prisma.Prisma__TahunAjaranClient<{
        id: string;
        nama: string;
        tenantId: string;
        aktif: boolean;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    setAktif(tenantId: string, id: string): Promise<{
        message: string;
    }>;
}
