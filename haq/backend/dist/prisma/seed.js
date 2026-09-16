"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
Object.defineProperty(exports, "__esModule", { value: true });
const client_1 = require("@prisma/client");
const bcrypt = __importStar(require("bcryptjs"));
const prisma = new client_1.PrismaClient();
async function main() {
    console.log('Mulai seeding...');
    const superAdminPassword = await bcrypt.hash('superadmin123', 10);
    const existingSa = await prisma.user.findFirst({
        where: { email: 'superadmin@sistempesantren.com', tenantId: null },
    });
    if (!existingSa) {
        await prisma.user.create({
            data: {
                nama: 'Super Admin Platform',
                email: 'superadmin@sistempesantren.com',
                passwordHash: superAdminPassword,
                role: client_1.Role.SUPER_ADMIN,
            },
        });
    }
    console.log('Super admin siap.');
    const kodeTenant = 'mahad-alquran';
    let tenant = await prisma.tenant.findUnique({ where: { kodeTenant } });
    const adminPassword = await bcrypt.hash('admin123', 10);
    if (!tenant) {
        tenant = await prisma.tenant.create({
            data: {
                kodeTenant,
                namaPondok: "Ma'had Al-Qur'an Wal Lughah",
                status: client_1.TenantStatus.AKTIF,
            },
        });
    }
    const tahunAjaran = await prisma.tahunAjaran.upsert({
        where: { tenantId_nama: { tenantId: tenant.id, nama: '2026/2027' } },
        update: { aktif: true },
        create: { tenantId: tenant.id, nama: '2026/2027', aktif: true },
    });
    const admin = await prisma.user.create({
        data: {
            tenantId: tenant.id,
            nama: 'Admin Pondok',
            email: 'admin@mahad.id',
            passwordHash: adminPassword,
            role: client_1.Role.ADMIN,
        },
    });
    const ustadzUser = await prisma.user.create({
        data: {
            tenantId: tenant.id,
            nama: 'Ustadz Ahmad',
            email: 'ustadz@mahad.id',
            passwordHash: adminPassword,
            role: client_1.Role.USTADZ,
        },
    });
    const musyrifUser = await prisma.user.create({
        data: {
            tenantId: tenant.id,
            nama: 'Musyrif Ali',
            email: 'musyrif@mahad.id',
            passwordHash: adminPassword,
            role: client_1.Role.MUSYRIF,
        },
    });
    const pimpinanUser = await prisma.user.create({
        data: {
            tenantId: tenant.id,
            nama: 'Mudir Pondok',
            email: 'mudir@mahad.id',
            passwordHash: adminPassword,
            role: client_1.Role.PIMPINAN,
        },
    });
    if (!tenant.adminAwalId) {
        await prisma.tenant.update({ where: { id: tenant.id }, data: { adminAwalId: admin.id } });
    }
    const ustadz = await prisma.ustadz.create({
        data: { tenantId: tenant.id, nama: 'Ustadz Ahmad', jenis: 'GURU', userId: ustadzUser.id },
    });
    await prisma.ustadz.create({
        data: { tenantId: tenant.id, nama: 'Ustadzah Siti', jenis: 'GURU' },
    });
    const musyrif = await prisma.ustadz.create({
        data: { tenantId: tenant.id, nama: 'Musyrif Ali', jenis: 'MUSYRIF', userId: musyrifUser.id },
    });
    const mapelTahfidz = await prisma.mataPelajaran.upsert({
        where: { tenantId_namaMapel: { tenantId: tenant.id, namaMapel: 'Tahfidzul Qur\'an' } },
        update: {},
        create: { tenantId: tenant.id, namaMapel: 'Tahfidzul Qur\'an', jenis: 'TAHFIDZ' },
    });
    const mapelArab = await prisma.mataPelajaran.upsert({
        where: { tenantId_namaMapel: { tenantId: tenant.id, namaMapel: 'Bahasa Arab' } },
        update: {},
        create: { tenantId: tenant.id, namaMapel: 'Bahasa Arab', jenis: 'BAHASA_ARAB' },
    });
    const mapelFiqih = await prisma.mataPelajaran.upsert({
        where: { tenantId_namaMapel: { tenantId: tenant.id, namaMapel: 'Fiqih Ibadah' } },
        update: {},
        create: { tenantId: tenant.id, namaMapel: 'Fiqih Ibadah' },
    });
    const kelas1 = await prisma.kelas.upsert({
        where: {
            tenantId_namaKelas_tahunAjaranId: {
                tenantId: tenant.id,
                namaKelas: '7A',
                tahunAjaranId: tahunAjaran.id,
            },
        },
        update: {},
        create: {
            tenantId: tenant.id,
            namaKelas: '7A',
            tingkat: '7',
            waliKelasId: ustadz.id,
            tahunAjaranId: tahunAjaran.id,
        },
    });
    const kelas2 = await prisma.kelas.upsert({
        where: {
            tenantId_namaKelas_tahunAjaranId: {
                tenantId: tenant.id,
                namaKelas: '7B',
                tahunAjaranId: tahunAjaran.id,
            },
        },
        update: {},
        create: {
            tenantId: tenant.id,
            namaKelas: '7B',
            tingkat: '7',
            waliKelasId: musyrif.id,
            tahunAjaranId: tahunAjaran.id,
        },
    });
    const waliBudi = await prisma.waliSantri.create({
        data: { tenantId: tenant.id, nama: 'H. Budi Santoso', noHp: '08123456789', hubungan: 'Ayah' },
    });
    const waliSiti = await prisma.waliSantri.create({
        data: { tenantId: tenant.id, nama: 'Ibu Siti Rahma', noHp: '08987654321', hubungan: 'Ibu' },
    });
    const waliUser = await prisma.user.create({
        data: {
            tenantId: tenant.id,
            nama: 'H. Budi Santoso',
            email: 'wali@mahad.id',
            passwordHash: adminPassword,
            role: client_1.Role.WALI_SANTRI,
        },
    });
    await prisma.waliSantri.update({ where: { id: waliBudi.id }, data: { userId: waliUser.id } });
    const santri1 = await prisma.santri.upsert({
        where: { tenantId_nis: { tenantId: tenant.id, nis: '2026001' } },
        update: { kelasId: kelas1.id, waliId: waliBudi.id },
        create: {
            tenantId: tenant.id,
            nis: '2026001',
            nama: 'Muhammad Fathir',
            jenisKelamin: 'L',
            tanggalLahir: new Date('2012-03-15'),
            kelasId: kelas1.id,
            asrama: 'Putra',
            waliId: waliBudi.id,
            tahunMasuk: 2026,
        },
    });
    const santri2 = await prisma.santri.upsert({
        where: { tenantId_nis: { tenantId: tenant.id, nis: '2026002' } },
        update: { kelasId: kelas1.id, waliId: waliBudi.id },
        create: {
            tenantId: tenant.id,
            nis: '2026002',
            nama: 'Abdullah Hasan',
            jenisKelamin: 'L',
            tanggalLahir: new Date('2012-07-20'),
            kelasId: kelas1.id,
            asrama: 'Putra',
            waliId: waliBudi.id,
            tahunMasuk: 2026,
        },
    });
    await prisma.santri.upsert({
        where: { tenantId_nis: { tenantId: tenant.id, nis: '2026003' } },
        update: { kelasId: kelas2.id, waliId: waliSiti.id },
        create: {
            tenantId: tenant.id,
            nis: '2026003',
            nama: 'Aisyah Nur',
            jenisKelamin: 'P',
            tanggalLahir: new Date('2012-01-10'),
            kelasId: kelas2.id,
            asrama: 'Putri',
            waliId: waliSiti.id,
            tahunMasuk: 2026,
        },
    });
    const today = new Date();
    await prisma.absensi.createMany({
        data: [
            { tenantId: tenant.id, santriId: santri1.id, kelasId: kelas1.id, mapelId: mapelFiqih.id, tanggal: today, status: 'HADIR', inputOleh: ustadzUser.id },
            { tenantId: tenant.id, santriId: santri2.id, kelasId: kelas1.id, mapelId: mapelFiqih.id, tanggal: today, status: 'SAKIT', inputOleh: ustadzUser.id },
        ],
        skipDuplicates: true,
    });
    await prisma.nilai.createMany({
        data: [
            { tenantId: tenant.id, santriId: santri1.id, mapelId: mapelTahfidz.id, jenis: 'TAHFIDZ', nilai: 90, tanggal: today, inputOleh: ustadzUser.id },
            { tenantId: tenant.id, santriId: santri1.id, mapelId: mapelArab.id, jenis: 'BAHASA_ARAB', nilai: 85, tanggal: today, inputOleh: ustadzUser.id },
            { tenantId: tenant.id, santriId: santri2.id, mapelId: mapelTahfidz.id, jenis: 'TAHFIDZ', nilai: 78, tanggal: today, inputOleh: ustadzUser.id },
        ],
        skipDuplicates: true,
    });
    await prisma.capaianTahfidz.createMany({
        data: [
            { tenantId: tenant.id, santriId: santri1.id, juz: 1, halaman: 15, tanggalSetor: today, catatanUstadz: 'Lancar', inputOleh: ustadzUser.id },
            { tenantId: tenant.id, santriId: santri2.id, juz: 1, halaman: 8, tanggalSetor: today, catatanUstadz: 'Perlu perbaikan makhraj', inputOleh: ustadzUser.id },
        ],
        skipDuplicates: true,
    });
    await prisma.pelanggaran.createMany({
        data: [
            { tenantId: tenant.id, santriId: santri2.id, jenisPelanggaran: 'Terlambat jamaah shalat', poin: 5, tanggal: today, pelaporId: musyrifUser.id, tindakLanjut: 'Nasehat lisan' },
        ],
        skipDuplicates: true,
    });
    await prisma.perizinan.createMany({
        data: [
            { tenantId: tenant.id, santriId: santri1.id, jenis: 'KELUAR', tanggalKeluar: today, alasan: 'Beli buku', statusApproval: 'DIAJUKAN' },
        ],
        skipDuplicates: true,
    });
    await prisma.kesehatanLog.createMany({
        data: [
            { tenantId: tenant.id, santriId: santri2.id, keluhan: 'Demam ringan', tindakan: 'Istirahat & obat batuk', tanggal: today, status: 'RAWAT_JALAN', inputOleh: musyrifUser.id },
        ],
        skipDuplicates: true,
    });
    console.log('Seeding selesai. Tenant demo:');
    console.log('  - Admin   : admin@mahad.id / admin123');
    console.log('  - Ustadz  : ustadz@mahad.id / admin123');
    console.log('  - Musyrif : musyrif@mahad.id / admin123');
    console.log('  - Mudir   : mudir@mahad.id / admin123');
    console.log('  - Wali    : wali@mahad.id / admin123');
    console.log('Super Admin : superadmin@sistempesantren.com / superadmin123');
    console.log('Kode tenant : ' + kodeTenant);
}
main()
    .catch((e) => {
    console.error(e);
    process.exit(1);
})
    .finally(async () => {
    await prisma.$disconnect();
});
//# sourceMappingURL=seed.js.map