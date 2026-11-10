-- AlterTable
ALTER TABLE `nilai_ujians` ADD COLUMN `inputOleh` VARCHAR(191) NULL,
    ADD COLUMN `status` ENUM('HADIR', 'SAKIT', 'IZIN', 'ALPA') NOT NULL DEFAULT 'HADIR',
    MODIFY `nilai` DOUBLE NULL;

-- AlterTable
ALTER TABLE `ujians` ADD COLUMN `dibuatOleh` VARCHAR(191) NULL,
    ADD COLUMN `dikunciOleh` VARCHAR(191) NULL,
    ADD COLUMN `dikunciPada` DATETIME(3) NULL,
    ADD COLUMN `periode` VARCHAR(191) NULL;
