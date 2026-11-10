-- CreateTable
CREATE TABLE `user_notif_settings` (
    `id` VARCHAR(191) NOT NULL,
    `userId` VARCHAR(191) NOT NULL,
    `perizinanBaru` BOOLEAN NOT NULL DEFAULT true,
    `pelanggaranBaru` BOOLEAN NOT NULL DEFAULT true,
    `waliBelumAktivasi` BOOLEAN NOT NULL DEFAULT true,
    `eskalasiDarurat` BOOLEAN NOT NULL DEFAULT true,
    `rekapAbsensiShalat` BOOLEAN NOT NULL DEFAULT false,
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `user_notif_settings_userId_key`(`userId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `user_notif_settings` ADD CONSTRAINT `user_notif_settings_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users`(`id`) ON DELETE CASCADE ON UPDATE CASCADE;
