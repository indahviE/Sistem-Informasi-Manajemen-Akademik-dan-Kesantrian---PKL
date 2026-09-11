import { MasterDataService } from './master-data.service';
import { CreateKelasDto, CreateMapelDto, CreateTahunAjaranDto, CreateUstadzDto, UpdateKelasDto, UpdateMapelDto, UpdateUstadzDto } from './dto/master.dto';
export declare class MasterDataController {
    private masterService;
    constructor(masterService: MasterDataService);
    findAllUstadz(tenantId: string, jenis?: string): import(".prisma/client").Prisma.PrismaPromise<{
        id: string;
        tenantId: string;
        nama: string;
        jenis: import(".prisma/client").$Enums.JenisUstadz;
        noHp: string | null;
        userId: string | null;
    }[]>;
    createUstadz(tenantId: string, dto: CreateUstadzDto): import(".prisma/client").Prisma.Prisma__UstadzClient<{
        id: string;
        tenantId: string;
        nama: string;
        jenis: import(".prisma/client").$Enums.JenisUstadz;
        noHp: string | null;
        userId: string | null;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    updateUstadz(tenantId: string, id: string, dto: UpdateUstadzDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        jenis: import(".prisma/client").$Enums.JenisUstadz;
        noHp: string | null;
        userId: string | null;
    }>;
    removeUstadz(tenantId: string, id: string): Promise<{
        message: string;
    }>;
    findAllKelas(tenantId: string): import(".prisma/client").Prisma.PrismaPromise<({
        _count: {
            santris: number;
        };
        waliKelas: {
            id: string;
            nama: string;
        };
        tahunAjaran: {
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
        jenis: string | null;
        namaMapel: string;
        kode: string | null;
    }[]>;
    createMapel(tenantId: string, dto: CreateMapelDto): import(".prisma/client").Prisma.Prisma__MataPelajaranClient<{
        id: string;
        tenantId: string;
        jenis: string | null;
        namaMapel: string;
        kode: string | null;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    updateMapel(tenantId: string, id: string, dto: UpdateMapelDto): Promise<{
        id: string;
        tenantId: string;
        jenis: string | null;
        namaMapel: string;
        kode: string | null;
    }>;
    removeMapel(tenantId: string, id: string): Promise<{
        message: string;
    }>;
    findAllTahunAjaran(tenantId: string): import(".prisma/client").Prisma.PrismaPromise<{
        id: string;
        tenantId: string;
        nama: string;
        aktif: boolean;
    }[]>;
    createTahunAjaran(tenantId: string, dto: CreateTahunAjaranDto): import(".prisma/client").Prisma.Prisma__TahunAjaranClient<{
        id: string;
        tenantId: string;
        nama: string;
        aktif: boolean;
    }, never, import("@prisma/client/runtime/library").DefaultArgs>;
    setAktif(tenantId: string, id: string): Promise<{
        message: string;
    }>;
}
