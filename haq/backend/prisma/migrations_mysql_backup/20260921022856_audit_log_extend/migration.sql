-- AlterTable
ALTER TABLE `audit_logs` ADD COLUMN `deskripsi` TEXT NULL,
    ADD COLUMN `ip` VARCHAR(191) NULL,
    ADD COLUMN `judul` VARCHAR(191) NULL,
    ADD COLUMN `kategori` ENUM('KEAMANAN', 'DATA', 'BILLING', 'SISTEM') NOT NULL DEFAULT 'DATA',
    ADD COLUMN `meta` VARCHAR(191) NULL,
    ADD COLUMN `tingkat` ENUM('INFO', 'WARNING', 'CRITICAL') NOT NULL DEFAULT 'INFO',
    ADD COLUMN `userRole` VARCHAR(191) NULL;

-- CreateIndex
CREATE INDEX `audit_logs_tenantId_createdAt_idx` ON `audit_logs`(`tenantId`, `createdAt`);

-- CreateIndex
CREATE INDEX `audit_logs_kategori_createdAt_idx` ON `audit_logs`(`kategori`, `createdAt`);

-- CreateIndex
CREATE INDEX `audit_logs_tingkat_createdAt_idx` ON `audit_logs`(`tingkat`, `createdAt`);

-- CreateIndex
CREATE INDEX `audit_logs_action_ip_createdAt_idx` ON `audit_logs`(`action`, `ip`, `createdAt`);

-- CreateIndex
CREATE INDEX `audit_logs_createdAt_idx` ON `audit_logs`(`createdAt`);
