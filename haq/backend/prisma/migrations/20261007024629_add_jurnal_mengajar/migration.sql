-- CreateTable
CREATE TABLE `jurnal_mengajars` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `kelasId` VARCHAR(191) NOT NULL,
    `mapelId` VARCHAR(191) NULL,
    `tanggal` DATETIME(3) NOT NULL,
    `materi` VARCHAR(500) NOT NULL,
    `catatan` VARCHAR(300) NULL,
    `inputOleh` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `updatedAt` DATETIME(3) NOT NULL,

    INDEX `jurnal_mengajars_tenantId_tanggal_idx`(`tenantId`, `tanggal`),
    INDEX `jurnal_mengajars_tenantId_kelasId_idx`(`tenantId`, `kelasId`),
    INDEX `jurnal_mengajars_tenantId_inputOleh_idx`(`tenantId`, `inputOleh`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `jurnal_mengajars` ADD CONSTRAINT `jurnal_mengajars_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `jurnal_mengajars` ADD CONSTRAINT `jurnal_mengajars_kelasId_fkey` FOREIGN KEY (`kelasId`) REFERENCES `kelas`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `jurnal_mengajars` ADD CONSTRAINT `jurnal_mengajars_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
