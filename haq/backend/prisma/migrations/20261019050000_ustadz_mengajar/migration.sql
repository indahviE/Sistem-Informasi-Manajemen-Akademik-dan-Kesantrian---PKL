-- CreateTable
CREATE TABLE `ustadz_mengajar` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `ustadzId` VARCHAR(191) NOT NULL,
    `kelasId` VARCHAR(191) NOT NULL,
    `mapelId` VARCHAR(191) NOT NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `ustadz_mengajar_tenantId_kelasId_idx`(`tenantId`, `kelasId`),
    INDEX `ustadz_mengajar_tenantId_mapelId_idx`(`tenantId`, `mapelId`),
    UNIQUE INDEX `ustadz_mengajar_ustadzId_kelasId_mapelId_key`(`ustadzId`, `kelasId`, `mapelId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `ustadz_mengajar` ADD CONSTRAINT `ustadz_mengajar_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ustadz_mengajar` ADD CONSTRAINT `ustadz_mengajar_ustadzId_fkey` FOREIGN KEY (`ustadzId`) REFERENCES `ustadzs`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ustadz_mengajar` ADD CONSTRAINT `ustadz_mengajar_kelasId_fkey` FOREIGN KEY (`kelasId`) REFERENCES `kelas`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `ustadz_mengajar` ADD CONSTRAINT `ustadz_mengajar_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

