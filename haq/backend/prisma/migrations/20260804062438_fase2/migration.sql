-- AlterTable
ALTER TABLE `kesehatan_logs` ADD COLUMN `diagnosa` VARCHAR(191) NULL,
    ADD COLUMN `obat` VARCHAR(191) NULL,
    ADD COLUMN `tempat` VARCHAR(191) NOT NULL DEFAULT 'UKS';

-- AlterTable
ALTER TABLE `tenants` ADD COLUMN `warnaTema` VARCHAR(191) NULL;

-- CreateTable
CREATE TABLE `pendaftarans` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `nama` VARCHAR(191) NOT NULL,
    `jenisKelamin` VARCHAR(191) NOT NULL,
    `tanggalLahir` DATETIME(3) NULL,
    `asalSekolah` VARCHAR(191) NULL,
    `noHp` VARCHAR(191) NULL,
    `email` VARCHAR(191) NULL,
    `alamat` VARCHAR(191) NULL,
    `jalur` VARCHAR(191) NULL,
    `status` ENUM('DIAJUKAN', 'TES', 'DITERIMA', 'DITOLAK', 'WAITING_LIST') NOT NULL DEFAULT 'DIAJUKAN',
    `catatan` VARCHAR(191) NULL,
    `tanggalDaftar` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `pendaftarans_tenantId_status_idx`(`tenantId`, `status`),
    INDEX `pendaftarans_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `placement_tests` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `pendaftaranId` VARCHAR(191) NOT NULL,
    `mapelId` VARCHAR(191) NULL,
    `nilai` DOUBLE NULL,
    `hasil` VARCHAR(191) NULL,
    `catatan` VARCHAR(191) NULL,
    `tanggal` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    UNIQUE INDEX `placement_tests_pendaftaranId_key`(`pendaftaranId`),
    INDEX `placement_tests_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `kurikulums` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `nama` VARCHAR(191) NOT NULL,
    `tahunAjaranId` VARCHAR(191) NULL,
    `deskripsi` VARCHAR(191) NULL,
    `aktif` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `kurikulums_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `silabus` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `kurikulumId` VARCHAR(191) NULL,
    `mapelId` VARCHAR(191) NULL,
    `judul` VARCHAR(191) NOT NULL,
    `kompetensiDasar` VARCHAR(191) NULL,
    `materiPokok` VARCHAR(191) NULL,
    `alokasiWaktu` VARCHAR(191) NULL,
    `fileUrl` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `silabus_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `rpps` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `mapelId` VARCHAR(191) NULL,
    `pertemuan` INTEGER NOT NULL,
    `judul` VARCHAR(191) NOT NULL,
    `tujuan` VARCHAR(191) NULL,
    `kegiatan` VARCHAR(191) NULL,
    `penilaian` VARCHAR(191) NULL,
    `fileUrl` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `rpps_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `rekam_medis` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `santriId` VARCHAR(191) NOT NULL,
    `golonganDarah` VARCHAR(191) NULL,
    `alergi` VARCHAR(191) NULL,
    `riwayatPenyakit` VARCHAR(191) NULL,
    `tinggiBadan` INTEGER NULL,
    `beratBadan` INTEGER NULL,
    `catatanKhusus` VARCHAR(191) NULL,
    `updatedAt` DATETIME(3) NOT NULL,

    UNIQUE INDEX `rekam_medis_santriId_key`(`santriId`),
    INDEX `rekam_medis_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `pakets` (
    `id` VARCHAR(191) NOT NULL,
    `nama` VARCHAR(191) NOT NULL,
    `harga` DOUBLE NOT NULL,
    `limitSantri` INTEGER NOT NULL,
    `fitur` JSON NULL,
    `aktif` BOOLEAN NOT NULL DEFAULT true,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `subscriptions` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `paketId` VARCHAR(191) NOT NULL,
    `tanggalMulai` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
    `tanggalAkhir` DATETIME(3) NULL,
    `status` ENUM('AKTIF', 'EXPIRED', 'CANCELED') NOT NULL DEFAULT 'AKTIF',

    INDEX `subscriptions_tenantId_idx`(`tenantId`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- CreateTable
CREATE TABLE `invoices` (
    `id` VARCHAR(191) NOT NULL,
    `tenantId` VARCHAR(191) NOT NULL,
    `noInvoice` VARCHAR(191) NOT NULL,
    `jumlah` DOUBLE NOT NULL,
    `status` ENUM('BELUM_BAYAR', 'LUNAS', 'BATAL') NOT NULL DEFAULT 'BELUM_BAYAR',
    `tanggalJatuhTempo` DATETIME(3) NULL,
    `tanggalBayar` DATETIME(3) NULL,
    `metodeBayar` VARCHAR(191) NULL,
    `createdAt` DATETIME(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),

    INDEX `invoices_tenantId_idx`(`tenantId`),
    UNIQUE INDEX `invoices_tenantId_noInvoice_key`(`tenantId`, `noInvoice`),
    PRIMARY KEY (`id`)
) DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- AddForeignKey
ALTER TABLE `pendaftarans` ADD CONSTRAINT `pendaftarans_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `placement_tests` ADD CONSTRAINT `placement_tests_pendaftaranId_fkey` FOREIGN KEY (`pendaftaranId`) REFERENCES `pendaftarans`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `placement_tests` ADD CONSTRAINT `placement_tests_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kurikulums` ADD CONSTRAINT `kurikulums_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `kurikulums` ADD CONSTRAINT `kurikulums_tahunAjaranId_fkey` FOREIGN KEY (`tahunAjaranId`) REFERENCES `tahun_ajarans`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `silabus` ADD CONSTRAINT `silabus_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `silabus` ADD CONSTRAINT `silabus_kurikulumId_fkey` FOREIGN KEY (`kurikulumId`) REFERENCES `kurikulums`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `silabus` ADD CONSTRAINT `silabus_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rpps` ADD CONSTRAINT `rpps_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rpps` ADD CONSTRAINT `rpps_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans`(`id`) ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rekam_medis` ADD CONSTRAINT `rekam_medis_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `rekam_medis` ADD CONSTRAINT `rekam_medis_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `subscriptions` ADD CONSTRAINT `subscriptions_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `subscriptions` ADD CONSTRAINT `subscriptions_paketId_fkey` FOREIGN KEY (`paketId`) REFERENCES `pakets`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE `invoices` ADD CONSTRAINT `invoices_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants`(`id`) ON DELETE RESTRICT ON UPDATE CASCADE;
