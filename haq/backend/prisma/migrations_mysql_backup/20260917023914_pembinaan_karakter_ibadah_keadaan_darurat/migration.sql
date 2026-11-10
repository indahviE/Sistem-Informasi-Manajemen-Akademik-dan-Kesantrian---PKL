-- AlterEnum
ALTER TABLE `notifikasis` MODIFY `jenis` ENUM('PELANGGARAN', 'KESEHATAN', 'PERIZINAN', 'NILAI', 'ABSENSI', 'SISTEM', 'DARURAT') NOT NULL;

-- CreateTable
CREATE TABLE `pembinaan_karakters` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `tanggal` DATETIME(3) NOT NULL,
    `kategori` VARCHAR(191) NOT NULL,
    `catatan` VARCHAR(191) NOT NULL,
    `pelaporId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `pembinaan_karakters_tenantId_santriId_idx`(`tenantId`, `santriId`),
    INDEX `pembinaan_karakters_tenantId_tanggal_idx`(`tenantId`, `tanggal`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `pembinaan_ibadahs` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `tanggal` DATETIME(3) NOT NULL,
    `jenisIbadah` VARCHAR(191) NOT NULL,
    `status` ENUM('HADIR', 'IZIN', 'ALPA') NOT NULL DEFAULT 'HADIR',
    `catatan` VARCHAR(191) NULL,
    `pelaporId` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `pembinaan_ibadahs_tenantId_santriId_idx`(`tenantId`, `santriId`),
    INDEX `pembinaan_ibadahs_tenantId_tanggal_idx`(`tenantId`, `tanggal`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `keadaan_darurats` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NULL,
    `jenis` VARCHAR(191) NOT NULL,
    `lokasi` VARCHAR(191) NULL,
    `deskripsi` VARCHAR(191) NOT NULL,
    `status` ENUM('BARU', 'DITANGANI', 'SELESAI') NOT NULL DEFAULT 'BARU',
    `tindakLanjut` VARCHAR(191) NULL,
    `pelaporId` VARCHAR(191) NULL,
    `tanggal` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `keadaan_darurats_tenantId_status_idx`(`tenantId`, `status`),
    INDEX `keadaan_darurats_tenantId_tanggal_idx`(`tenantId`, `tanggal`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `pembinaan_karakters` ADD CONSTRAINT `pembinaan_karakters_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `pembinaan_karakters` ADD CONSTRAINT `pembinaan_karakters_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `pembinaan_ibadahs` ADD CONSTRAINT `pembinaan_ibadahs_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `pembinaan_ibadahs` ADD CONSTRAINT `pembinaan_ibadahs_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `keadaan_darurats` ADD CONSTRAINT `keadaan_darurats_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `keadaan_darurats` ADD CONSTRAINT `keadaan_darurats_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;