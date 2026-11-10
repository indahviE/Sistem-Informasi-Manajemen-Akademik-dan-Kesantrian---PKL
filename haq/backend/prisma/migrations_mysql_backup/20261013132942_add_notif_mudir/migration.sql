-- AlterTable
ALTER TABLE `user_notif_settings` ADD COLUMN `laporanKesantrian` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `laporanKeuangan` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `pendaftaranBaru` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `ringkasanHarian` BOOLEAN NOT NULL DEFAULT true;
