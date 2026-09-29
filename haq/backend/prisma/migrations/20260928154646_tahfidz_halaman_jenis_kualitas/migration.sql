-- AlterTable
ALTER TABLE `capaian_tahfidzs` ADD COLUMN `halamanMulai` INTEGER NULL,
    ADD COLUMN `halamanSelesai` INTEGER NULL,
    ADD COLUMN `jenis` ENUM('ZIYADAH', 'MURAJAAH') NOT NULL DEFAULT 'ZIYADAH',
    ADD COLUMN `kualitas` ENUM('MUMTAZ', 'JAYYID', 'MAQBUL', 'DHAIF') NULL;
