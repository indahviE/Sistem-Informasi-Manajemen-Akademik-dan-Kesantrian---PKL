-- AlterTable
ALTER TABLE `users` ADD COLUMN `isRootAdmin` BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN `noHp` VARCHAR(191) NULL,
    ADD COLUMN `subRole` ENUM('OPERASIONAL', 'KEUANGAN') NULL;

-- CreateTable
CREATE TABLE `platform_settings` (
    `id` VARCHAR(191) NOT NULL,
    `autoApproveTenant` BOOLEAN NOT NULL DEFAULT false,
    `graceDaysPending` INTEGER NOT NULL DEFAULT 14,
    `notifTenantBaru` BOOLEAN NOT NULL DEFAULT true,
    `notifTagihan` BOOLEAN NOT NULL DEFAULT true,
    `notifKeamanan` BOOLEAN NOT NULL DEFAULT true,
    `notifLaporanMingguan` BOOLEAN NOT NULL DEFAULT false,
    `updatedAt` DATETIME(3) NOT NULL,

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
