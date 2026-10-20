-- AlterTable
ALTER TABLE `nilais` ADD COLUMN `skill` VARCHAR(191) NOT NULL DEFAULT '';

-- CreateIndex (index baru dibuat DULU supaya foreign key santriId tetap punya index)
CREATE UNIQUE INDEX `nilais_santriId_mapelId_jenis_skill_tanggal_key` ON `nilais`(`santriId`, `mapelId`, `jenis`, `skill`, `tanggal`);

-- DropIndex (baru dihapus setelah yang baru ada)
DROP INDEX `nilais_santriId_mapelId_jenis_tanggal_key` ON `nilais`;