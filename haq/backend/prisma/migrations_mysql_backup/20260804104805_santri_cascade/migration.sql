-- DropForeignKey
ALTER TABLE `absensis` DROP FOREIGN KEY `absensis_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `capaian_tahfidzs` DROP FOREIGN KEY `capaian_tahfidzs_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `kelulusans` DROP FOREIGN KEY `kelulusans_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `kesehatan_logs` DROP FOREIGN KEY `kesehatan_logs_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `konselings` DROP FOREIGN KEY `konselings_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `kunjungan_walis` DROP FOREIGN KEY `kunjungan_walis_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `nilai_ujians` DROP FOREIGN KEY `nilai_ujians_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `nilais` DROP FOREIGN KEY `nilais_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `pelanggarans` DROP FOREIGN KEY `pelanggarans_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `perizinan` DROP FOREIGN KEY `perizinan_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `rapors` DROP FOREIGN KEY `rapors_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `rekam_medis` DROP FOREIGN KEY `rekam_medis_santriId_fkey`;

-- DropForeignKey
ALTER TABLE `remedials` DROP FOREIGN KEY `remedials_santriId_fkey`;

-- AddForeignKey
ALTER TABLE `absensis` ADD CONSTRAINT `absensis_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `nilais` ADD CONSTRAINT `nilais_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `capaian_tahfidzs` ADD CONSTRAINT `capaian_tahfidzs_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `pelanggarans` ADD CONSTRAINT `pelanggarans_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `perizinan` ADD CONSTRAINT `perizinan_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kesehatan_logs` ADD CONSTRAINT `kesehatan_logs_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kunjungan_walis` ADD CONSTRAINT `kunjungan_walis_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rekam_medis` ADD CONSTRAINT `rekam_medis_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `nilai_ujians` ADD CONSTRAINT `nilai_ujians_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `remedials` ADD CONSTRAINT `remedials_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rapors` ADD CONSTRAINT `rapors_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kelulusans` ADD CONSTRAINT `kelulusans_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `konselings` ADD CONSTRAINT `konselings_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
