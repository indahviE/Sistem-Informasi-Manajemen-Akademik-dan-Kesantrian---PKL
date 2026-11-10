/*
  Warnings:

  - A unique constraint covering the columns `[ujianId,santriId]` on the table `remedials` will be added. If there are existing duplicate values, this will fail.

*/
-- AlterTable
ALTER TABLE `remedials` ADD COLUMN `catatan` VARCHAR(191) NULL,
    ADD COLUMN `jadwal` DATETIME(3) NULL,
    ADD COLUMN `nilaiAwal` DOUBLE NULL,
    ADD COLUMN `nilaiRemedial` DOUBLE NULL,
    ADD COLUMN `ruang` VARCHAR(191) NULL,
    ADD COLUMN `status` ENUM('BELUM_TES', 'PROSES', 'TUNTAS') NOT NULL DEFAULT 'BELUM_TES',
    ADD COLUMN `tenggat` DATETIME(3) NULL;

-- CreateIndex
CREATE INDEX `remedials_tenantId_ujianId_idx` ON `remedials`(`tenantId`, `ujianId`);

-- CreateIndex
CREATE UNIQUE INDEX `remedials_ujianId_santriId_key` ON `remedials`(`ujianId`, `santriId`);
