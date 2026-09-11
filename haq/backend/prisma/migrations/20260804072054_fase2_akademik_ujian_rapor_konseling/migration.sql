-- CreateTable
CREATE TABLE `ujians` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `nama` VARCHAR(191) NOT NULL,
    `jenis` VARCHAR(191) NOT NULL DEFAULT 'ULANGAN',
    `mapelId` VARCHAR(191) NULL,
    `kelasId` VARCHAR(191) NULL,
    `tanggal` DATETIME(3) NULL,
    `durasiMenit` INTEGER NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `ujians_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `nilai_ujians` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `ujianId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `nilai` DOUBLE NOT NULL,
    `catatan` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `nilai_ujians_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `nilai_ujians_ujianId_santriId_key`(`ujianId`, `santriId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `remedials` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `ujianId` VARCHAR(191) NULL,
    `mapelId` VARCHAR(191) NULL,
    `keterangan` VARCHAR(191) NOT NULL,
    `hasil` VARCHAR(191) NULL DEFAULT 'PROSES',
    `tanggal` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `remedials_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `rapors` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `periode` VARCHAR(191) NOT NULL,
    `ringkasan` JSON NULL,
    `rataRata` DOUBLE NULL,
    `status` ENUM('DRAFT', 'TERBIT') NOT NULL DEFAULT 'DRAFT',
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `rapors_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `rapors_tenantId_santriId_periode_key`(`tenantId`, `santriId`, `periode`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `kelulusans` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `status` VARCHAR(191) NOT NULL DEFAULT 'LULUS',
    `tanggalKelulusan` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `predikat` ENUM('MEMUASKAN', 'HONOUR', 'CUM_LAUDE', 'SUMMA_CUM_LAUDE') NULL,
    `juzYangDiHafal` INTEGER NULL,
    `catatan` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `kelulusans_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `kelulusans_tenantId_santriId_key`(`tenantId`, `santriId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `konselings` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `tanggal` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `konselorId` VARCHAR(191) NULL,
    `topik` VARCHAR(191) NOT NULL,
    `catatan` VARCHAR(191) NOT NULL,
    `tindakLanjut` VARCHAR(191) NULL,
    `privat` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `konselings_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `ujians` ADD CONSTRAINT `ujians_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ujians` ADD CONSTRAINT `ujians_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ujians` ADD CONSTRAINT `ujians_kelasId_fkey` FOREIGN KEY (`kelasId`) REFERENCES `kelas`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `nilai_ujians` ADD CONSTRAINT `nilai_ujians_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `nilai_ujians` ADD CONSTRAINT `nilai_ujians_ujianId_fkey` FOREIGN KEY (`ujianId`) REFERENCES `ujians`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `nilai_ujians` ADD CONSTRAINT `nilai_ujians_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `remedials` ADD CONSTRAINT `remedials_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `remedials` ADD CONSTRAINT `remedials_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `remedials` ADD CONSTRAINT `remedials_ujianId_fkey` FOREIGN KEY (`ujianId`) REFERENCES `ujians`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `remedials` ADD CONSTRAINT `remedials_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rapors` ADD CONSTRAINT `rapors_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rapors` ADD CONSTRAINT `rapors_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kelulusans` ADD CONSTRAINT `kelulusans_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kelulusans` ADD CONSTRAINT `kelulusans_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `konselings` ADD CONSTRAINT `konselings_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `konselings` ADD CONSTRAINT `konselings_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `konselings` ADD CONSTRAINT `konselings_konselorId_fkey` FOREIGN KEY (`konselorId`) REFERENCES `ustadzs`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
