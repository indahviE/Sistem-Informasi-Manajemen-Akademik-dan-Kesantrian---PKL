-- AlterTable
ALTER TABLE `user_notif_settings` ADD COLUMN `jadwalMengajar` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `pengingatAbsensi` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `pengingatNilai` BOOLEAN NOT NULL DEFAULT true,
    ADD COLUMN `pengumumanPondok` BOOLEAN NOT NULL DEFAULT true;
