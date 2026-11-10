-- AlterTable
ALTER TABLE `tenants` ADD COLUMN `alamat` TEXT NULL,
    ADD COLUMN `karakteristik` JSON NULL;

-- AddForeignKey
ALTER TABLE `tenants` ADD CONSTRAINT `tenants_adminAwalId_fkey` FOREIGN KEY (`adminAwalId`) REFERENCES `users`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;
