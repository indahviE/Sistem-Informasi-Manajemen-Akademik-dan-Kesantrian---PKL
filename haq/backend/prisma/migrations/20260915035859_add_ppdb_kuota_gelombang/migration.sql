-- AlterTable
ALTER TABLE `tenants` ADD COLUMN `kuotaSantriPpdb` INTEGER NULL,
    ADD COLUMN `statusGelombangPpdb` ENUM('DIBUKA', 'DITUTUP') NOT NULL DEFAULT 'DITUTUP';
