import { KurikulumService } from './kurikulum.service';
import { CreateKurikulumDto, CreateRppDto, CreateSilabusDto, UpdateKurikulumDto, UpdateRppDto, UpdateSilabusDto } from './dto/kurikulum.dto';
export declare class KurikulumController {
    private kurikulumService;
    constructor(kurikulumService: KurikulumService);
    findAllKurikulum(tenantId: string): Promise<({
        _count: {
            silabus: number;
        };
        tahunAjaran: {
            id: string;
            tenantId: string;
            nama: string;
            aktif: boolean;
        };
    } & {
        id: string;
        tenantId: string;
        nama: string;
        createdAt: Date;
        aktif: boolean;
        tahunAjaranId: string | null;
        deskripsi: string | null;
    })[]>;
    createKurikulum(tenantId: string, dto: CreateKurikulumDto): Promise<{
        tahunAjaran: {
            id: string;
            tenantId: string;
            nama: string;
            aktif: boolean;
        };
    } & {
        id: string;
        tenantId: string;
        nama: string;
        createdAt: Date;
        aktif: boolean;
        tahunAjaranId: string | null;
        deskripsi: string | null;
    }>;
    updateKurikulum(tenantId: string, id: string, dto: UpdateKurikulumDto): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        createdAt: Date;
        aktif: boolean;
        tahunAjaranId: string | null;
        deskripsi: string | null;
    }>;
    removeKurikulum(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        nama: string;
        createdAt: Date;
        aktif: boolean;
        tahunAjaranId: string | null;
        deskripsi: string | null;
    }>;
    findAllSilabus(tenantId: string): Promise<({
        kurikulum: {
            id: string;
            tenantId: string;
            nama: string;
            createdAt: Date;
            aktif: boolean;
            tahunAjaranId: string | null;
            deskripsi: string | null;
        };
        mapel: {
            id: string;
            tenantId: string;
            jenis: string | null;
            namaMapel: string;
            kode: string | null;
        };
    } & {
        id: string;
        tenantId: string;
        createdAt: Date;
        mapelId: string | null;
        judul: string;
        kurikulumId: string | null;
        kompetensiDasar: string | null;
        materiPokok: string | null;
        alokasiWaktu: string | null;
        fileUrl: string | null;
    })[]>;
    createSilabus(tenantId: string, dto: CreateSilabusDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        mapelId: string | null;
        judul: string;
        kurikulumId: string | null;
        kompetensiDasar: string | null;
        materiPokok: string | null;
        alokasiWaktu: string | null;
        fileUrl: string | null;
    }>;
    updateSilabus(tenantId: string, id: string, dto: UpdateSilabusDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        mapelId: string | null;
        judul: string;
        kurikulumId: string | null;
        kompetensiDasar: string | null;
        materiPokok: string | null;
        alokasiWaktu: string | null;
        fileUrl: string | null;
    }>;
    removeSilabus(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        mapelId: string | null;
        judul: string;
        kurikulumId: string | null;
        kompetensiDasar: string | null;
        materiPokok: string | null;
        alokasiWaktu: string | null;
        fileUrl: string | null;
    }>;
    findAllRpp(tenantId: string): Promise<({
        mapel: {
            id: string;
            tenantId: string;
            jenis: string | null;
            namaMapel: string;
            kode: string | null;
        };
    } & {
        id: string;
        tenantId: string;
        createdAt: Date;
        mapelId: string | null;
        judul: string;
        fileUrl: string | null;
        pertemuan: number;
        tujuan: string | null;
        kegiatan: string | null;
        penilaian: string | null;
    })[]>;
    createRpp(tenantId: string, dto: CreateRppDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        mapelId: string | null;
        judul: string;
        fileUrl: string | null;
        pertemuan: number;
        tujuan: string | null;
        kegiatan: string | null;
        penilaian: string | null;
    }>;
    updateRpp(tenantId: string, id: string, dto: UpdateRppDto): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        mapelId: string | null;
        judul: string;
        fileUrl: string | null;
        pertemuan: number;
        tujuan: string | null;
        kegiatan: string | null;
        penilaian: string | null;
    }>;
    removeRpp(tenantId: string, id: string): Promise<{
        id: string;
        tenantId: string;
        createdAt: Date;
        mapelId: string | null;
        judul: string;
        fileUrl: string | null;
        pertemuan: number;
        tujuan: string | null;
        kegiatan: string | null;
        penilaian: string | null;
    }>;
}
