-- CreateTable
CREATE TABLE `tenants` (
    `id` VARCHAR(191) NOT NULL,
    `kodeTenant` VARCHAR(191) NOT NULL,
    `namaPondok` VARCHAR(191) NOT NULL,
    `logoUrl` VARCHAR(191) NULL,
    `status` ENUM('PENDING', 'AKTIF', 'SUSPENDED') NOT NULL DEFAULT 'PENDING',
    `adminAwalId` VARCHAR(191) NULL,
    `tanggalDaftar` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `tenants_kodeTenant_key`(`kodeTenant`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `users` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `nama` VARCHAR(191) NOT NULL,
    `email` VARCHAR(191) NOT NULL,
    `passwordHash` VARCHAR(191) NOT NULL,
    `role` ENUM('SUPER_ADMIN', 'ADMIN', 'USTADZ', 'MUSYRIF', 'WALI_SANTRI', 'SANTRI', 'PIMPINAN') NOT NULL,
    `status` ENUM('AKTIF', 'NONAKTIF') NOT NULL DEFAULT 'AKTIF',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `users_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `users_tenantId_email_key`(`tenantId`, `email`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `santris` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `nis` VARCHAR(191) NOT NULL,
    `nama` VARCHAR(191) NOT NULL,
    `jenisKelamin` VARCHAR(191) NOT NULL,
    `tanggalLahir` DATETIME(3) NULL,
    `kelasId` VARCHAR(191) NULL,
    `asrama` VARCHAR(191) NULL,
    `waliId` VARCHAR(191) NULL,
    `status` ENUM('AKTIF', 'LULUS', 'KELUAR') NOT NULL DEFAULT 'AKTIF',
    `tahunMasuk` INTEGER NOT NULL,

    INDEX `santris_tenantId_kelasId_idx`(`tenantId`, `kelasId`),
    INDEX `santris_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `santris_tenantId_nis_key`(`tenantId`, `nis`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `ustadzs` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `nama` VARCHAR(191) NOT NULL,
    `jenis` ENUM('GURU', 'MUSYRIF') NOT NULL DEFAULT 'GURU',
    `noHp` VARCHAR(191) NULL,
    `userId` VARCHAR(191) NULL,

    INDEX `ustadzs_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `kelas` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `namaKelas` VARCHAR(191) NOT NULL,
    `tingkat` VARCHAR(191) NOT NULL,
    `waliKelasId` VARCHAR(191) NULL,
    `tahunAjaranId` VARCHAR(191) NULL,

    INDEX `kelas_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `kelas_tenantId_namaKelas_tahunAjaranId_key`(`tenantId`, `namaKelas`, `tahunAjaranId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `wali_santris` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `nama` VARCHAR(191) NOT NULL,
    `noHp` VARCHAR(191) NULL,
    `email` VARCHAR(191) NULL,
    `hubungan` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NULL,

    INDEX `wali_santris_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `mata_pelajarans` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `namaMapel` VARCHAR(191) NOT NULL,
    `kode` VARCHAR(191) NULL,
    `jenis` VARCHAR(191) NULL,

    INDEX `mata_pelajarans_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `mata_pelajarans_tenantId_namaMapel_key`(`tenantId`, `namaMapel`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tahun_ajarans` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `nama` VARCHAR(191) NOT NULL,
    `aktif` BOOLEAN NOT NULL DEFAULT true,

    UNIQUE INDEX `tahun_ajarans_tenantId_nama_key`(`tenantId`, `nama`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `absensis` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `kelasId` VARCHAR(191) NULL,
    `mapelId` VARCHAR(191) NULL,
    `tanggal` DATETIME(3) NOT NULL,
    `status` ENUM('HADIR', 'IZIN', 'SAKIT', 'ALPA') NOT NULL,
    `catatan` VARCHAR(191) NULL,
    `inputOleh` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `absensis_tenantId_santriId_tanggal_idx`(`tenantId`, `santriId`, `tanggal`),
    INDEX `absensis_tenantId_tanggal_idx`(`tenantId`, `tanggal`),
    INDEX `absensis_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `nilais` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `mapelId` VARCHAR(191) NOT NULL,
    `jenis` ENUM('HARIAN', 'ULANGAN', 'TAHFIDZ', 'BAHASA_ARAB') NOT NULL,
    `nilai` DOUBLE NOT NULL,
    `keterangan` VARCHAR(191) NULL,
    `tanggal` DATETIME(3) NOT NULL,
    `inputOleh` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `nilais_tenantId_santriId_mapelId_idx`(`tenantId`, `santriId`, `mapelId`),
    INDEX `nilais_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `capaian_tahfidzs` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `juz` INTEGER NOT NULL,
    `halaman` INTEGER NOT NULL,
    `tanggalSetor` DATETIME(3) NOT NULL,
    `catatanUstadz` VARCHAR(191) NULL,
    `inputOleh` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `capaian_tahfidzs_tenantId_santriId_idx`(`tenantId`, `santriId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `pelanggarans` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `jenisPelanggaran` VARCHAR(191) NOT NULL,
    `poin` INTEGER NOT NULL,
    `tanggal` DATETIME(3) NOT NULL,
    `pelaporId` VARCHAR(191) NULL,
    `tindakLanjut` VARCHAR(191) NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'DICATAT',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `pelanggarans_tenantId_santriId_idx`(`tenantId`, `santriId`),
    INDEX `pelanggarans_tenantId_tanggal_idx`(`tenantId`, `tanggal`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `perizinan` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `jenis` ENUM('PULANG', 'KELUAR') NOT NULL,
    `tanggalKeluar` DATETIME(3) NOT NULL,
    `tanggalKembali` DATETIME(3) NULL,
    `alasan` VARCHAR(191) NOT NULL,
    `statusApproval` ENUM('DIAJUKAN', 'DISETUJUI', 'DITOLAK', 'KEMBALI', 'TELAT') NOT NULL DEFAULT 'DIAJUKAN',
    `disetujuiOleh` VARCHAR(191) NULL,
    `catatan` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `perizinan_tenantId_santriId_idx`(`tenantId`, `santriId`),
    INDEX `perizinan_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `kesehatan_logs` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `keluhan` VARCHAR(191) NOT NULL,
    `tindakan` VARCHAR(191) NULL,
    `tanggal` DATETIME(3) NOT NULL,
    `status` ENUM('RAWAT_JALAN', 'DIRUJUK', 'SEMBUH') NOT NULL DEFAULT 'RAWAT_JALAN',
    `inputOleh` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `kesehatan_logs_tenantId_santriId_idx`(`tenantId`, `santriId`),
    INDEX `kesehatan_logs_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `kunjungan_walis` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `waliId` VARCHAR(191) NULL,
    `tanggal` DATETIME(3) NOT NULL,
    `catatan` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `kunjungan_walis_tenantId_santriId_idx`(`tenantId`, `santriId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `notifikasis` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NULL,
    `jenis` ENUM('PELANGGARAN', 'KESEHATAN', 'PERIZINAN', 'NILAI', 'ABSENSI', 'SISTEM') NOT NULL,
    `pesan` VARCHAR(191) NOT NULL,
    `statusBaca` BOOLEAN NOT NULL DEFAULT false,
    `tanggal` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `notifikasis_tenantId_userId_statusBaca_idx`(`tenantId`, `userId`, `statusBaca`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `tata_tertibs` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `judul` VARCHAR(191) NOT NULL,
    `isi` VARCHAR(191) NOT NULL,
    `aktif` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `tata_tertibs_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `audit_logs` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NULL,
    `userId` VARCHAR(191) NULL,
    `userNama` VARCHAR(191) NULL,
    `action` VARCHAR(191) NOT NULL,
    `entity` VARCHAR(191) NOT NULL,
    `entityId` VARCHAR(191) NULL,
    `data` JSON NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `audit_logs_tenantId_entity_createdAt_idx`(`tenantId`, `entity`, `createdAt`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `users` ADD CONSTRAINT `users_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `santris` ADD CONSTRAINT `santris_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `santris` ADD CONSTRAINT `santris_kelasId_fkey` FOREIGN KEY (`kelasId`) REFERENCES `kelas`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `santris` ADD CONSTRAINT `santris_waliId_fkey` FOREIGN KEY (`waliId`) REFERENCES `wali_santris`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ustadzs` ADD CONSTRAINT `ustadzs_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kelas` ADD CONSTRAINT `kelas_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kelas` ADD CONSTRAINT `kelas_waliKelasId_fkey` FOREIGN KEY (`waliKelasId`) REFERENCES `ustadzs`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kelas` ADD CONSTRAINT `kelas_tahunAjaranId_fkey` FOREIGN KEY (`tahunAjaranId`) REFERENCES `tahun_ajarans`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `wali_santris` ADD CONSTRAINT `wali_santris_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `wali_santris` ADD CONSTRAINT `wali_santris_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `mata_pelajarans` ADD CONSTRAINT `mata_pelajarans_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tahun_ajarans` ADD CONSTRAINT `tahun_ajarans_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `absensis` ADD CONSTRAINT `absensis_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `absensis` ADD CONSTRAINT `absensis_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `nilais` ADD CONSTRAINT `nilais_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `nilais` ADD CONSTRAINT `nilais_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `capaian_tahfidzs` ADD CONSTRAINT `capaian_tahfidzs_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `pelanggarans` ADD CONSTRAINT `pelanggarans_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `perizinan` ADD CONSTRAINT `perizinan_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kesehatan_logs` ADD CONSTRAINT `kesehatan_logs_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kunjungan_walis` ADD CONSTRAINT `kunjungan_walis_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kunjungan_walis` ADD CONSTRAINT `kunjungan_walis_waliId_fkey` FOREIGN KEY (`waliId`) REFERENCES `wali_santris`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `notifikasis` ADD CONSTRAINT `notifikasis_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `tata_tertibs` ADD CONSTRAINT `tata_tertibs_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
