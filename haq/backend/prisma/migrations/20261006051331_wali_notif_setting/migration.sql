-- AlterTable
ALTER TABLE `user_notif_settings` ADD COLUMN `absensiAnak` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `kesehatanAnak` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `nilaiRapor` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `pelanggaranAnak` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `perizinanAnak` BOOLEAN NOT NULL DEFAULT true;
