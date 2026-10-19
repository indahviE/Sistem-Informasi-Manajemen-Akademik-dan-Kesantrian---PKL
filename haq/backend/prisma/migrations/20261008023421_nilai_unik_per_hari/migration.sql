/*
  Warnings:

  - A unique constraint covering the columns `[santriId,mapelId,jenis,tanggal]` on the table `nilais` will be added. If there are existing duplicate values, this will fail.

*/
-- Bersihkan data ganda: per santri+mapel+jenis+hari, sisakan yang paling baru
DELETE n1 FROM `nilais` n1
JOIN `nilais` n2
  ON n1.`santriId` = n2.`santriId`
 AND n1.`mapelId`  = n2.`mapelId`
 AND n1.`jenis`    = n2.`jenis`
 AND DATE(n1.`tanggal`) = DATE(n2.`tanggal`)
 AND (n1.`createdAt` < n2.`createdAt`
      OR (n1.`createdAt` = n2.`createdAt` AND n1.`id` < n2.`id`));
      
-- AlterTable
ALTER TABLE `nilais` MODIFY `tanggal` DATE NOT NULL;

-- CreateIndex
CREATE UNIQUE INDEX `nilais_santriId_mapelId_jenis_tanggal_key` ON `nilais`(`santriId`, `mapelId`, `jenis`, `tanggal`);
