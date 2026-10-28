-- MySQL dump 10.13  Distrib 8.4.11, for Linux (x86_64)
--
-- Host: localhost    Database: pesantren
-- ------------------------------------------------------
-- Server version	8.4.11

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `_prisma_migrations`
--

DROP TABLE IF EXISTS `_prisma_migrations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `_prisma_migrations` (
  `id` varchar(36) COLLATE utf8mb4_unicode_ci NOT NULL,
  `checksum` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `finished_at` datetime(3) DEFAULT NULL,
  `migration_name` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logs` text COLLATE utf8mb4_unicode_ci,
  `rolled_back_at` datetime(3) DEFAULT NULL,
  `started_at` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `applied_steps_count` int unsigned NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `_prisma_migrations`
--

LOCK TABLES `_prisma_migrations` WRITE;
/*!40000 ALTER TABLE `_prisma_migrations` DISABLE KEYS */;
INSERT INTO `_prisma_migrations` VALUES ('07044607-241d-437a-b9bb-665fc6bcb27d','146fb00215483f1d4b3cb830c48131faafd6d24223f491ba6628ff558c30cd58','2026-10-28 04:48:16.129','20260804072054_fase2_akademik_ujian_rapor_konseling',NULL,NULL,'2026-10-28 04:48:12.282',1),('0c1ec652-a3ca-46eb-a5e1-c61267802dd3','600e3cabcd8e429310fde90c6392e80e966fc1d9b51abda8a7b3d60f13cdf856','2026-10-28 04:48:22.449','20260928160648_tambah_jayyid_jiddan',NULL,NULL,'2026-10-28 04:48:22.297',1),('0ccc66e5-70db-46e0-b861-35fcb438800d','995d71deb2cffdb346136de5f26b591dd61f9aaef3c06eebd460aaca3459c36b','2026-10-28 04:48:25.274','20261019040956_nilai_skill',NULL,NULL,'2026-10-28 04:48:25.083',1),('118246cb-0f6d-4520-8a40-9edbc15ef592','57f8a35a5abe127c5bc68616e74bd197b6cbbc1d5de31769aedde7b1190d4b82','2026-10-28 04:48:22.989','20260930011436_remedial_fields',NULL,NULL,'2026-10-28 04:48:22.746',1),('201a48a5-4d4c-42a8-b2e2-3a41aaf9343d','e08bf1cc079f4813669722dbdc0701c03e766cbe2340c9554c20c9ea0b5b45cc','2026-10-28 04:48:24.954','20261009140552_tambah_rencana_kembali',NULL,NULL,'2026-10-28 04:48:24.822',1),('2f4957a0-4fdf-4c75-9b7d-f36be8e17372','5e8fbd72f5cf5d6c08e5cb67a2ad097d93d657ce6265d1b08ea76c877029340b','2026-10-28 04:48:16.428','20260804093249_logo_text',NULL,NULL,'2026-10-28 04:48:16.138',1),('333c9945-7d63-4446-9954-a0eff69f548a','afd299ea329ea9535a324048c250bbdc4697e6fc3a7c1950f16e8c56fddab320','2026-10-28 04:48:23.783','20261006051331_wali_notif_setting',NULL,NULL,'2026-10-28 04:48:23.687',1),('35094746-f784-496c-8ef9-41bfab3b2a56','679b6b90b3981941dadb5b54692760dd14ed4a862d14497daf207402325804e3','2026-10-28 04:48:21.183','20260921022856_audit_log_extend',NULL,NULL,'2026-10-28 04:48:20.863',1),('4420030e-41b7-4601-8292-3f0d327f9991','a25f369d6aae860d957203adda60b49a2f4b3976e23e805092995c4b59a1d461','2026-10-28 04:48:20.661','20260917023914_pembinaan_karakter_ibadah_keadaan_darurat',NULL,NULL,'2026-10-28 04:48:19.484',1),('4a37c2af-b212-4508-90f8-c50de8c61621','e1da8657005f5321f505854868b51d286eddd1ff1c46739f19afb0db85e0e178','2026-10-28 04:48:21.963','20260923061025_add_periode_paket',NULL,NULL,'2026-10-28 04:48:21.861',1),('5368303c-0e41-4650-85c2-78146023ef18','a192de7fb2ff594240f4a0b1057d0eedf7aa21afe79768bf9c31db260d4a3af0','2026-10-28 04:48:19.347','20260915035859_add_ppdb_kuota_gelombang',NULL,NULL,'2026-10-28 04:48:19.188',1),('561aa2d7-a034-47f4-8db1-e984086e273e','9e198605ba001e2998ca0c53c86bec4c1643cabf2f3a95e44840ab7a6fdfbcbd','2026-10-28 04:48:24.516','20261007024629_add_jurnal_mengajar',NULL,NULL,'2026-10-28 04:48:23.907',1),('696712cf-60e6-4593-8c7f-914ed21307b9','0ca862eedee99cb620dbc8f0cf72ca5d17eb97275434d3c533ab5fac629fd1b8','2026-10-28 04:48:25.075','20261013132942_add_notif_mudir',NULL,NULL,'2026-10-28 04:48:24.965',1),('6c5c08e8-01f9-4734-8032-6a1aaa922710','47c99e3af7b81ef0a0285d684a70a4f1402136a3c08e1464baeac02783acb173','2026-10-28 04:48:23.380','20261001051654_ujian_kunci_status_kehadiran',NULL,NULL,'2026-10-28 04:48:23.135',1),('6c72c672-64e4-45f0-bcd9-cf5adf21c2b0','10b1744f192aa618e2d0a34262d83c911f5c062ced698bd0564aa041ee82c467','2026-10-28 04:48:20.854','20260918042439_add_pengaturan_platform',NULL,NULL,'2026-10-28 04:48:20.669',1),('71a3a79d-0489-44ff-aae5-6405a55bc588','1383dfd3816bf016bb1db21ab99e75d572213d3191458bf2299d7457f64fb85d','2026-10-28 04:48:23.128','20260930023217_ujian_kkm',NULL,NULL,'2026-10-28 04:48:22.999',1),('7a3fa716-9c35-4755-bc5f-297527af242b','ad74c5e41c866909891df2280970de78ef1595765f5552f313150fe48019d674','2026-10-28 04:48:22.737','20260929042429_tambah_notif_wali_aktivasi',NULL,NULL,'2026-10-28 04:48:22.703',1),('83d2997d-8e5e-4457-a3f8-21e01bc38b23','c9bc6fc46ddb4347635021e9dec9f22820929ee3651896c8ad4bbdcecce2ec86','2026-10-28 04:48:26.278','20261023000000_add_pendamping_perizinan',NULL,NULL,'2026-10-28 04:48:26.124',1),('8457b936-8baf-4de4-a0a2-26e1e589e0c3','e609c4d8f0c3065683186d634850e8c9168e684bd37f3ff838483ae9f23ff583','2026-10-28 04:48:12.267','20260804062438_fase2',NULL,NULL,'2026-10-28 04:48:08.071',1),('91cb9100-271e-40aa-9049-f905cb7402ba','3867d4a2501f5be5fed64dc3f1f6576e3c1e3c90c53e6cc1609aa60f62663b95','2026-10-28 04:48:21.346','20260921050036_notifikasi_superadmin',NULL,NULL,'2026-10-28 04:48:21.191',1),('9e493774-3c47-4d57-8991-3758b3fd59da','0436b0d0b3afa053099aa0c5f77a2e6c2fadd4243bf7560080eae5c98ce9d1d5','2026-10-28 04:48:19.178','20260804104805_santri_cascade',NULL,NULL,'2026-10-28 04:48:16.768',1),('a5f10f65-2064-41da-a287-c9a2c6a20540','7036f566582c9a54043db7bd19d11f6406be151a17fd731386bfd082b61f8814','2026-10-28 04:48:21.853','20260923022144_add_archived_tenant_status',NULL,NULL,'2026-10-28 04:48:21.757',1),('ad1dc4ee-e27c-4bb0-90b1-d1aa8a82305c','73a90ad1cb5b8e2a5b3ec9ba4bc11a88b4ac5bca29542b143b1c94a477e1de44','2026-10-28 04:48:16.760','20260804093700_logo_mediumtext',NULL,NULL,'2026-10-28 04:48:16.437',1),('bd130f9a-1d1f-4c9c-a2b3-f0f629cec5cd','0a4a6e7a88a351eb345bc8ce9f51714a677618a7575686d82689dd31bd52581e','2026-10-28 04:48:22.693','20260929024329_add_user_notif_setting',NULL,NULL,'2026-10-28 04:48:22.460',1),('bfe98689-a67f-4d04-b74e-bff0fd31b283','2f0df0d0310cd05f1a016f8d0d1011ad1f95215fb3b411c85947989651234976','2026-10-28 04:48:26.116','20261020120000_kunjungan_nama_wali_status',NULL,NULL,'2026-10-28 04:48:25.991',1),('c7765308-680e-4a0c-b568-16445d0055bb','5052404b1ba382905395fe9a47e5fe87305d5c690a373b1aa9f5739149abc69e','2026-10-28 04:48:08.060','20260804045707_init',NULL,NULL,'2026-10-28 04:47:59.890',1),('caa47c96-33b3-4ada-9b47-4fa95e07fd4b','cd2f5d22f61177ee727bcb12385faf7c8d4aa062767e6a37371be7fb7c005dfc','2026-10-28 04:48:23.679','20261006011754_kkm_per_mapel_dan_nilai_akhir',NULL,NULL,'2026-10-28 04:48:23.388',1),('cc9eb4f3-b6c6-4b95-b034-813bb90e9402','26727972a8df1fd2fc8811f0cbad52956573af63639c330cc92fbd5b49062494','2026-10-28 04:48:19.475','20260916020001_add_berkas_ppdb',NULL,NULL,'2026-10-28 04:48:19.356',1),('cdf1069a-ef65-4f72-86c3-c72c5186d235','786eb7ce239ebcb841c032f33db7d84ac1512fe9f1b9500eb13697b321c02fe5','2026-10-28 04:48:25.982','20261019050000_ustadz_mengajar',NULL,NULL,'2026-10-28 04:48:25.284',1),('d9f2b337-e140-42a8-9cf1-55977618931c','85b343bea7ec5ebcd772f704e5ee96c64566821e87f2e6e8f5e799d46ffed1e3','2026-10-28 04:48:24.814','20261008023421_nilai_unik_per_hari',NULL,NULL,'2026-10-28 04:48:24.526',1),('deabd4b3-5743-4e5f-a012-4bb00f5f3f09','b6363ddd33bcd92f41546d609e30310f4eceb8c6fb22ae3ba0d96ebced18037f','2026-10-28 04:48:22.149','20260925024838_tambah_trash_tenant',NULL,NULL,'2026-10-28 04:48:21.970',1),('e338d488-7c18-431c-955e-5e99520737ba','7880f57411375838f12270944e805f8f19eb124061017f00eee203fa0bc4a6d7','2026-10-28 04:48:21.749','20260923014508_add_tenant_alamat_karakteristik_admin_relation',NULL,NULL,'2026-10-28 04:48:21.354',1),('e90fdf8d-7dd0-40bf-96ca-ef18fb18da4e','56827fa1e2ac1fd34a364788b1b85a6ce3e99278c9c98d67979fc34cf16e7ce7','2026-10-28 04:48:23.897','20261006103704_add_notif_ustadz',NULL,NULL,'2026-10-28 04:48:23.791',1),('f30c6534-298b-4a22-a060-6efa58ccaf3a','75fafcf7fda075f1fb528dde766616df321aae39b0406c9dbc43d651658d60b9','2026-10-28 04:48:22.283','20260928154646_tahfidz_halaman_jenis_kualitas',NULL,NULL,'2026-10-28 04:48:22.158',1);
/*!40000 ALTER TABLE `_prisma_migrations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `absensis`
--

DROP TABLE IF EXISTS `absensis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `absensis` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `kelasId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mapelId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggal` datetime(3) NOT NULL,
  `status` enum('HADIR','IZIN','SAKIT','ALPA') COLLATE utf8mb4_unicode_ci NOT NULL,
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `inputOleh` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `absensis_tenantId_santriId_tanggal_idx` (`tenantId`,`santriId`,`tanggal`),
  KEY `absensis_tenantId_tanggal_idx` (`tenantId`,`tanggal`),
  KEY `absensis_tenantId_idx` (`tenantId`),
  KEY `absensis_mapelId_fkey` (`mapelId`),
  KEY `absensis_santriId_fkey` (`santriId`),
  KEY `absensis_tenantId_mapelId_tanggal_idx` (`tenantId`,`mapelId`,`tanggal`),
  CONSTRAINT `absensis_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `absensis_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `absensis`
--

LOCK TABLES `absensis` WRITE;
/*!40000 ALTER TABLE `absensis` DISABLE KEYS */;
INSERT INTO `absensis` VALUES ('cmvrmwgrw001414nx5trthpli','cmvrmwgeu000114nxxld6x7mx','cmvrmwgpi000z14nxn1mb05gn','cmvrmwgm7000p14nxzaydi90u','cmvrmwglr000n14nxgd8ta32p','2026-10-28 04:48:35.561','HADIR',NULL,'cmvrmwggx000714nx5qh11vnv','2026-10-28 04:48:35.564'),('cmvrmwgrw001514nxymnqga0j','cmvrmwgeu000114nxxld6x7mx','cmvrmwgr1001114nxtwlcmwhd','cmvrmwgm7000p14nxzaydi90u','cmvrmwglr000n14nxgd8ta32p','2026-10-28 04:48:35.561','SAKIT',NULL,'cmvrmwggx000714nx5qh11vnv','2026-10-28 04:48:35.564');
/*!40000 ALTER TABLE `absensis` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `audit_logs`
--

DROP TABLE IF EXISTS `audit_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `audit_logs` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `userId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `userNama` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entity` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `entityId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `data` json DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `deskripsi` text COLLATE utf8mb4_unicode_ci,
  `ip` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `judul` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `kategori` enum('KEAMANAN','DATA','BILLING','SISTEM') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DATA',
  `meta` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tingkat` enum('INFO','WARNING','CRITICAL') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'INFO',
  `userRole` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `audit_logs_tenantId_entity_createdAt_idx` (`tenantId`,`entity`,`createdAt`),
  KEY `audit_logs_tenantId_createdAt_idx` (`tenantId`,`createdAt`),
  KEY `audit_logs_kategori_createdAt_idx` (`kategori`,`createdAt`),
  KEY `audit_logs_tingkat_createdAt_idx` (`tingkat`,`createdAt`),
  KEY `audit_logs_action_ip_createdAt_idx` (`action`,`ip`,`createdAt`),
  KEY `audit_logs_createdAt_idx` (`createdAt`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `audit_logs`
--

LOCK TABLES `audit_logs` WRITE;
/*!40000 ALTER TABLE `audit_logs` DISABLE KEYS */;
/*!40000 ALTER TABLE `audit_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `capaian_tahfidzs`
--

DROP TABLE IF EXISTS `capaian_tahfidzs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `capaian_tahfidzs` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `juz` int NOT NULL,
  `halaman` int NOT NULL,
  `tanggalSetor` datetime(3) NOT NULL,
  `catatanUstadz` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `inputOleh` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `halamanMulai` int DEFAULT NULL,
  `halamanSelesai` int DEFAULT NULL,
  `jenis` enum('ZIYADAH','MURAJAAH') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ZIYADAH',
  `kualitas` enum('MUMTAZ','JAYYID_JIDDAN','JAYYID','MAQBUL','DHAIF') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ayatAbsMulai` int DEFAULT NULL,
  `ayatAbsSelesai` int DEFAULT NULL,
  `ayatMulai` int DEFAULT NULL,
  `ayatSelesai` int DEFAULT NULL,
  `suratMulai` int DEFAULT NULL,
  `suratSelesai` int DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `capaian_tahfidzs_tenantId_santriId_idx` (`tenantId`,`santriId`),
  KEY `capaian_tahfidzs_santriId_fkey` (`santriId`),
  KEY `capaian_tahfidzs_tenantId_santriId_ayatAbsSelesai_idx` (`tenantId`,`santriId`,`ayatAbsSelesai`),
  CONSTRAINT `capaian_tahfidzs_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `capaian_tahfidzs`
--

LOCK TABLES `capaian_tahfidzs` WRITE;
/*!40000 ALTER TABLE `capaian_tahfidzs` DISABLE KEYS */;
INSERT INTO `capaian_tahfidzs` VALUES ('cmvrmwgsy001914nxz1n6hlmq','cmvrmwgeu000114nxxld6x7mx','cmvrmwgpi000z14nxn1mb05gn',1,15,'2026-10-28 04:48:35.561','Lancar','cmvrmwggx000714nx5qh11vnv','2026-10-28 04:48:35.603',NULL,NULL,'ZIYADAH',NULL,NULL,NULL,NULL,NULL,NULL,NULL),('cmvrmwgsy001a14nxh4napxgp','cmvrmwgeu000114nxxld6x7mx','cmvrmwgr1001114nxtwlcmwhd',1,8,'2026-10-28 04:48:35.561','Perlu perbaikan makhraj','cmvrmwggx000714nx5qh11vnv','2026-10-28 04:48:35.603',NULL,NULL,'ZIYADAH',NULL,NULL,NULL,NULL,NULL,NULL,NULL);
/*!40000 ALTER TABLE `capaian_tahfidzs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoices` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `noInvoice` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `jumlah` double NOT NULL,
  `status` enum('BELUM_BAYAR','LUNAS','BATAL') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'BELUM_BAYAR',
  `tanggalJatuhTempo` datetime(3) DEFAULT NULL,
  `tanggalBayar` datetime(3) DEFAULT NULL,
  `metodeBayar` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `invoices_tenantId_noInvoice_key` (`tenantId`,`noInvoice`),
  KEY `invoices_tenantId_idx` (`tenantId`),
  CONSTRAINT `invoices_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoices`
--

LOCK TABLES `invoices` WRITE;
/*!40000 ALTER TABLE `invoices` DISABLE KEYS */;
/*!40000 ALTER TABLE `invoices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `jurnal_mengajars`
--

DROP TABLE IF EXISTS `jurnal_mengajars`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `jurnal_mengajars` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `kelasId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mapelId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggal` datetime(3) NOT NULL,
  `materi` varchar(500) COLLATE utf8mb4_unicode_ci NOT NULL,
  `catatan` varchar(300) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `inputOleh` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `jurnal_mengajars_tenantId_tanggal_idx` (`tenantId`,`tanggal`),
  KEY `jurnal_mengajars_tenantId_kelasId_idx` (`tenantId`,`kelasId`),
  KEY `jurnal_mengajars_tenantId_inputOleh_idx` (`tenantId`,`inputOleh`),
  KEY `jurnal_mengajars_kelasId_fkey` (`kelasId`),
  KEY `jurnal_mengajars_mapelId_fkey` (`mapelId`),
  CONSTRAINT `jurnal_mengajars_kelasId_fkey` FOREIGN KEY (`kelasId`) REFERENCES `kelas` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `jurnal_mengajars_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `jurnal_mengajars_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `jurnal_mengajars`
--

LOCK TABLES `jurnal_mengajars` WRITE;
/*!40000 ALTER TABLE `jurnal_mengajars` DISABLE KEYS */;
/*!40000 ALTER TABLE `jurnal_mengajars` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `keadaan_darurats`
--

DROP TABLE IF EXISTS `keadaan_darurats`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `keadaan_darurats` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `jenis` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `lokasi` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deskripsi` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('BARU','DITANGANI','SELESAI') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'BARU',
  `tindakLanjut` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pelaporId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggal` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  KEY `keadaan_darurats_tenantId_status_idx` (`tenantId`,`status`),
  KEY `keadaan_darurats_tenantId_tanggal_idx` (`tenantId`,`tanggal`),
  KEY `keadaan_darurats_santriId_fkey` (`santriId`),
  CONSTRAINT `keadaan_darurats_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `keadaan_darurats_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `keadaan_darurats`
--

LOCK TABLES `keadaan_darurats` WRITE;
/*!40000 ALTER TABLE `keadaan_darurats` DISABLE KEYS */;
/*!40000 ALTER TABLE `keadaan_darurats` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `kelas`
--

DROP TABLE IF EXISTS `kelas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `kelas` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `namaKelas` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tingkat` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `waliKelasId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tahunAjaranId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `kelas_tenantId_namaKelas_tahunAjaranId_key` (`tenantId`,`namaKelas`,`tahunAjaranId`),
  KEY `kelas_tenantId_idx` (`tenantId`),
  KEY `kelas_waliKelasId_fkey` (`waliKelasId`),
  KEY `kelas_tahunAjaranId_fkey` (`tahunAjaranId`),
  CONSTRAINT `kelas_tahunAjaranId_fkey` FOREIGN KEY (`tahunAjaranId`) REFERENCES `tahun_ajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `kelas_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `kelas_waliKelasId_fkey` FOREIGN KEY (`waliKelasId`) REFERENCES `ustadzs` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kelas`
--

LOCK TABLES `kelas` WRITE;
/*!40000 ALTER TABLE `kelas` DISABLE KEYS */;
INSERT INTO `kelas` VALUES ('cmvrmwgm7000p14nxzaydi90u','cmvrmwgeu000114nxxld6x7mx','7A','7','cmvrmwgje000d14nxhv43rf8y','cmvrmwgfc000314nxtqezli56'),('cmvrmwgmr000r14nx741owoc7','cmvrmwgeu000114nxxld6x7mx','7B','7','cmvrmwgkd000h14nxql9o6f99','cmvrmwgfc000314nxtqezli56');
/*!40000 ALTER TABLE `kelas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `kelulusans`
--

DROP TABLE IF EXISTS `kelulusans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `kelulusans` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'LULUS',
  `tanggalKelulusan` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `predikat` enum('MEMUASKAN','HONOUR','CUM_LAUDE','SUMMA_CUM_LAUDE') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `juzYangDiHafal` int DEFAULT NULL,
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `kelulusans_tenantId_santriId_key` (`tenantId`,`santriId`),
  KEY `kelulusans_tenantId_idx` (`tenantId`),
  KEY `kelulusans_santriId_fkey` (`santriId`),
  CONSTRAINT `kelulusans_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `kelulusans_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kelulusans`
--

LOCK TABLES `kelulusans` WRITE;
/*!40000 ALTER TABLE `kelulusans` DISABLE KEYS */;
/*!40000 ALTER TABLE `kelulusans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `kesehatan_logs`
--

DROP TABLE IF EXISTS `kesehatan_logs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `kesehatan_logs` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `keluhan` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tindakan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggal` datetime(3) NOT NULL,
  `status` enum('RAWAT_JALAN','DIRUJUK','SEMBUH') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RAWAT_JALAN',
  `inputOleh` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `diagnosa` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `obat` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tempat` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'UKS',
  PRIMARY KEY (`id`),
  KEY `kesehatan_logs_tenantId_santriId_idx` (`tenantId`,`santriId`),
  KEY `kesehatan_logs_tenantId_idx` (`tenantId`),
  KEY `kesehatan_logs_santriId_fkey` (`santriId`),
  KEY `kesehatan_logs_tenantId_tanggal_idx` (`tenantId`,`tanggal`),
  CONSTRAINT `kesehatan_logs_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kesehatan_logs`
--

LOCK TABLES `kesehatan_logs` WRITE;
/*!40000 ALTER TABLE `kesehatan_logs` DISABLE KEYS */;
INSERT INTO `kesehatan_logs` VALUES ('cmvrmwgu6001d14nxvzybgrtn','cmvrmwgeu000114nxxld6x7mx','cmvrmwgr1001114nxtwlcmwhd','Demam ringan','Istirahat & obat batuk','2026-10-28 04:48:35.561','RAWAT_JALAN','cmvrmwgha000914nxjrg8v0nv','2026-10-28 04:48:35.646',NULL,NULL,'UKS');
/*!40000 ALTER TABLE `kesehatan_logs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `konselings`
--

DROP TABLE IF EXISTS `konselings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `konselings` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggal` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `konselorId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `topik` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tindakLanjut` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `privat` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `createdById` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `konselings_tenantId_idx` (`tenantId`),
  KEY `konselings_konselorId_fkey` (`konselorId`),
  KEY `konselings_santriId_fkey` (`santriId`),
  KEY `konselings_tenantId_createdById_idx` (`tenantId`,`createdById`),
  KEY `konselings_createdById_fkey` (`createdById`),
  CONSTRAINT `konselings_createdById_fkey` FOREIGN KEY (`createdById`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `konselings_konselorId_fkey` FOREIGN KEY (`konselorId`) REFERENCES `ustadzs` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `konselings_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `konselings_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `konselings`
--

LOCK TABLES `konselings` WRITE;
/*!40000 ALTER TABLE `konselings` DISABLE KEYS */;
/*!40000 ALTER TABLE `konselings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `kunjungan_walis`
--

DROP TABLE IF EXISTS `kunjungan_walis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `kunjungan_walis` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `waliId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggal` datetime(3) NOT NULL,
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `namaWali` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'BERLANGSUNG',
  `selesaiAt` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `kunjungan_walis_tenantId_santriId_idx` (`tenantId`,`santriId`),
  KEY `kunjungan_walis_waliId_fkey` (`waliId`),
  KEY `kunjungan_walis_santriId_fkey` (`santriId`),
  CONSTRAINT `kunjungan_walis_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `kunjungan_walis_waliId_fkey` FOREIGN KEY (`waliId`) REFERENCES `wali_santris` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kunjungan_walis`
--

LOCK TABLES `kunjungan_walis` WRITE;
/*!40000 ALTER TABLE `kunjungan_walis` DISABLE KEYS */;
/*!40000 ALTER TABLE `kunjungan_walis` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `kurikulums`
--

DROP TABLE IF EXISTS `kurikulums`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `kurikulums` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nama` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tahunAjaranId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `deskripsi` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `aktif` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `kurikulums_tenantId_idx` (`tenantId`),
  KEY `kurikulums_tahunAjaranId_fkey` (`tahunAjaranId`),
  CONSTRAINT `kurikulums_tahunAjaranId_fkey` FOREIGN KEY (`tahunAjaranId`) REFERENCES `tahun_ajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `kurikulums_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `kurikulums`
--

LOCK TABLES `kurikulums` WRITE;
/*!40000 ALTER TABLE `kurikulums` DISABLE KEYS */;
/*!40000 ALTER TABLE `kurikulums` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `mata_pelajarans`
--

DROP TABLE IF EXISTS `mata_pelajarans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mata_pelajarans` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `namaMapel` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `kode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `jenis` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `kkm` double NOT NULL DEFAULT '75',
  PRIMARY KEY (`id`),
  UNIQUE KEY `mata_pelajarans_tenantId_namaMapel_key` (`tenantId`,`namaMapel`),
  KEY `mata_pelajarans_tenantId_idx` (`tenantId`),
  CONSTRAINT `mata_pelajarans_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `mata_pelajarans`
--

LOCK TABLES `mata_pelajarans` WRITE;
/*!40000 ALTER TABLE `mata_pelajarans` DISABLE KEYS */;
INSERT INTO `mata_pelajarans` VALUES ('cmvrmwgkq000j14nx71fe2bht','cmvrmwgeu000114nxxld6x7mx','Tahfidzul Qur\'an',NULL,'TAHFIDZ',75),('cmvrmwglc000l14nxqnfb7q2c','cmvrmwgeu000114nxxld6x7mx','Bahasa Arab',NULL,'BAHASA_ARAB',75),('cmvrmwglr000n14nxgd8ta32p','cmvrmwgeu000114nxxld6x7mx','Fiqih Ibadah',NULL,NULL,75);
/*!40000 ALTER TABLE `mata_pelajarans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nilai_ujians`
--

DROP TABLE IF EXISTS `nilai_ujians`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nilai_ujians` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ujianId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nilai` double DEFAULT NULL,
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `inputOleh` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('HADIR','SAKIT','IZIN','ALPA') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'HADIR',
  PRIMARY KEY (`id`),
  UNIQUE KEY `nilai_ujians_ujianId_santriId_key` (`ujianId`,`santriId`),
  KEY `nilai_ujians_tenantId_idx` (`tenantId`),
  KEY `nilai_ujians_santriId_fkey` (`santriId`),
  CONSTRAINT `nilai_ujians_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `nilai_ujians_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `nilai_ujians_ujianId_fkey` FOREIGN KEY (`ujianId`) REFERENCES `ujians` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nilai_ujians`
--

LOCK TABLES `nilai_ujians` WRITE;
/*!40000 ALTER TABLE `nilai_ujians` DISABLE KEYS */;
/*!40000 ALTER TABLE `nilai_ujians` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `nilais`
--

DROP TABLE IF EXISTS `nilais`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `nilais` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mapelId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `jenis` enum('HARIAN','ULANGAN','TAHFIDZ','BAHASA_ARAB') COLLATE utf8mb4_unicode_ci NOT NULL,
  `nilai` double NOT NULL,
  `keterangan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggal` date NOT NULL,
  `inputOleh` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `skill` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '',
  `tahunAjaranId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `nilais_santriId_mapelId_jenis_skill_tanggal_key` (`santriId`,`mapelId`,`jenis`,`skill`,`tanggal`),
  KEY `nilais_tenantId_santriId_mapelId_idx` (`tenantId`,`santriId`,`mapelId`),
  KEY `nilais_tenantId_idx` (`tenantId`),
  KEY `nilais_mapelId_fkey` (`mapelId`),
  KEY `nilais_tenantId_tahunAjaranId_idx` (`tenantId`,`tahunAjaranId`),
  KEY `nilais_tenantId_tanggal_idx` (`tenantId`,`tanggal`),
  KEY `nilais_tahunAjaranId_fkey` (`tahunAjaranId`),
  CONSTRAINT `nilais_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `nilais_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `nilais_tahunAjaranId_fkey` FOREIGN KEY (`tahunAjaranId`) REFERENCES `tahun_ajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `nilais`
--

LOCK TABLES `nilais` WRITE;
/*!40000 ALTER TABLE `nilais` DISABLE KEYS */;
INSERT INTO `nilais` VALUES ('cmvrmwgse001614nxills5u4z','cmvrmwgeu000114nxxld6x7mx','cmvrmwgpi000z14nxn1mb05gn','cmvrmwgkq000j14nx71fe2bht','TAHFIDZ',90,NULL,'2026-10-28','cmvrmwggx000714nx5qh11vnv','2026-10-28 04:48:35.582','',NULL),('cmvrmwgse001714nxxgee3p71','cmvrmwgeu000114nxxld6x7mx','cmvrmwgpi000z14nxn1mb05gn','cmvrmwglc000l14nxqnfb7q2c','BAHASA_ARAB',85,NULL,'2026-10-28','cmvrmwggx000714nx5qh11vnv','2026-10-28 04:48:35.582','',NULL),('cmvrmwgse001814nx1za0spna','cmvrmwgeu000114nxxld6x7mx','cmvrmwgr1001114nxtwlcmwhd','cmvrmwgkq000j14nx71fe2bht','TAHFIDZ',78,NULL,'2026-10-28','cmvrmwggx000714nx5qh11vnv','2026-10-28 04:48:35.582','',NULL);
/*!40000 ALTER TABLE `nilais` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `notifikasis`
--

DROP TABLE IF EXISTS `notifikasis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `notifikasis` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `userId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `jenis` enum('TENANT_BARU','TAGIHAN','KEAMANAN','LAPORAN','PELANGGARAN','KESEHATAN','PERIZINAN','NILAI','ABSENSI','SISTEM','DARURAT','WALI_BELUM_AKTIVASI','RINGKASAN_HARIAN','LAPORAN_KESANTRIAN','PENDAFTARAN_BARU','LAPORAN_KEUANGAN') COLLATE utf8mb4_unicode_ci NOT NULL,
  `pesan` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `statusBaca` tinyint(1) NOT NULL DEFAULT '0',
  `tanggal` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `notifikasis_tenantId_userId_statusBaca_idx` (`tenantId`,`userId`,`statusBaca`),
  KEY `notifikasis_userId_fkey` (`userId`),
  CONSTRAINT `notifikasis_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `notifikasis`
--

LOCK TABLES `notifikasis` WRITE;
/*!40000 ALTER TABLE `notifikasis` DISABLE KEYS */;
/*!40000 ALTER TABLE `notifikasis` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pakets`
--

DROP TABLE IF EXISTS `pakets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pakets` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nama` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `harga` double NOT NULL,
  `limitSantri` int NOT NULL,
  `fitur` json DEFAULT NULL,
  `aktif` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `periode` enum('HARIAN','BULANAN','TAHUNAN') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'TAHUNAN',
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pakets`
--

LOCK TABLES `pakets` WRITE;
/*!40000 ALTER TABLE `pakets` DISABLE KEYS */;
/*!40000 ALTER TABLE `pakets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pelanggarans`
--

DROP TABLE IF EXISTS `pelanggarans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pelanggarans` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `jenisPelanggaran` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `poin` int NOT NULL,
  `tanggal` datetime(3) NOT NULL,
  `pelaporId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tindakLanjut` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DICATAT',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `pelanggarans_tenantId_santriId_idx` (`tenantId`,`santriId`),
  KEY `pelanggarans_tenantId_tanggal_idx` (`tenantId`,`tanggal`),
  KEY `pelanggarans_santriId_fkey` (`santriId`),
  CONSTRAINT `pelanggarans_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pelanggarans`
--

LOCK TABLES `pelanggarans` WRITE;
/*!40000 ALTER TABLE `pelanggarans` DISABLE KEYS */;
INSERT INTO `pelanggarans` VALUES ('cmvrmwgtg001b14nxj6lycwfb','cmvrmwgeu000114nxxld6x7mx','cmvrmwgr1001114nxtwlcmwhd','Terlambat jamaah shalat',5,'2026-10-28 04:48:35.561','cmvrmwgha000914nxjrg8v0nv','Nasehat lisan','DICATAT','2026-10-28 04:48:35.620');
/*!40000 ALTER TABLE `pelanggarans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pembinaan_ibadahs`
--

DROP TABLE IF EXISTS `pembinaan_ibadahs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pembinaan_ibadahs` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggal` datetime(3) NOT NULL,
  `jenisIbadah` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('HADIR','IZIN','ALPA') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'HADIR',
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pelaporId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `pembinaan_ibadahs_tenantId_santriId_idx` (`tenantId`,`santriId`),
  KEY `pembinaan_ibadahs_tenantId_tanggal_idx` (`tenantId`,`tanggal`),
  KEY `pembinaan_ibadahs_santriId_fkey` (`santriId`),
  CONSTRAINT `pembinaan_ibadahs_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `pembinaan_ibadahs_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pembinaan_ibadahs`
--

LOCK TABLES `pembinaan_ibadahs` WRITE;
/*!40000 ALTER TABLE `pembinaan_ibadahs` DISABLE KEYS */;
/*!40000 ALTER TABLE `pembinaan_ibadahs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pembinaan_karakters`
--

DROP TABLE IF EXISTS `pembinaan_karakters`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pembinaan_karakters` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggal` datetime(3) NOT NULL,
  `kategori` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pelaporId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `pembinaan_karakters_tenantId_santriId_idx` (`tenantId`,`santriId`),
  KEY `pembinaan_karakters_tenantId_tanggal_idx` (`tenantId`,`tanggal`),
  KEY `pembinaan_karakters_santriId_fkey` (`santriId`),
  CONSTRAINT `pembinaan_karakters_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `pembinaan_karakters_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pembinaan_karakters`
--

LOCK TABLES `pembinaan_karakters` WRITE;
/*!40000 ALTER TABLE `pembinaan_karakters` DISABLE KEYS */;
/*!40000 ALTER TABLE `pembinaan_karakters` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pendaftarans`
--

DROP TABLE IF EXISTS `pendaftarans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pendaftarans` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nama` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `jenisKelamin` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggalLahir` datetime(3) DEFAULT NULL,
  `asalSekolah` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `noHp` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `alamat` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `jalur` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('DIAJUKAN','TES','DITERIMA','DITOLAK','WAITING_LIST') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DIAJUKAN',
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggalDaftar` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `aktaLahirUrl` mediumtext COLLATE utf8mb4_unicode_ci,
  `fotoUrl` mediumtext COLLATE utf8mb4_unicode_ci,
  `kartuKeluargaUrl` mediumtext COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  KEY `pendaftarans_tenantId_status_idx` (`tenantId`,`status`),
  KEY `pendaftarans_tenantId_idx` (`tenantId`),
  CONSTRAINT `pendaftarans_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pendaftarans`
--

LOCK TABLES `pendaftarans` WRITE;
/*!40000 ALTER TABLE `pendaftarans` DISABLE KEYS */;
/*!40000 ALTER TABLE `pendaftarans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `perizinan`
--

DROP TABLE IF EXISTS `perizinan`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `perizinan` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `jenis` enum('PULANG','KELUAR') COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggalKeluar` datetime(3) NOT NULL,
  `tanggalKembali` datetime(3) DEFAULT NULL,
  `alasan` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `statusApproval` enum('DIAJUKAN','DISETUJUI','DITOLAK','KEMBALI','TELAT') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DIAJUKAN',
  `disetujuiOleh` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `rencanaKembali` datetime(3) DEFAULT NULL,
  `pendamping` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `perizinan_tenantId_santriId_idx` (`tenantId`,`santriId`),
  KEY `perizinan_tenantId_idx` (`tenantId`),
  KEY `perizinan_santriId_fkey` (`santriId`),
  KEY `perizinan_tenantId_tanggalKeluar_idx` (`tenantId`,`tanggalKeluar`),
  CONSTRAINT `perizinan_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `perizinan`
--

LOCK TABLES `perizinan` WRITE;
/*!40000 ALTER TABLE `perizinan` DISABLE KEYS */;
INSERT INTO `perizinan` VALUES ('cmvrmwgtt001c14nxq6n04jha','cmvrmwgeu000114nxxld6x7mx','cmvrmwgpi000z14nxn1mb05gn','KELUAR','2026-10-28 04:48:35.561',NULL,'Beli buku','DIAJUKAN',NULL,NULL,'2026-10-28 04:48:35.633',NULL,NULL);
/*!40000 ALTER TABLE `perizinan` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `placement_tests`
--

DROP TABLE IF EXISTS `placement_tests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `placement_tests` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pendaftaranId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mapelId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nilai` double DEFAULT NULL,
  `hasil` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggal` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `placement_tests_pendaftaranId_key` (`pendaftaranId`),
  KEY `placement_tests_tenantId_idx` (`tenantId`),
  KEY `placement_tests_mapelId_fkey` (`mapelId`),
  CONSTRAINT `placement_tests_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `placement_tests_pendaftaranId_fkey` FOREIGN KEY (`pendaftaranId`) REFERENCES `pendaftarans` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `placement_tests`
--

LOCK TABLES `placement_tests` WRITE;
/*!40000 ALTER TABLE `placement_tests` DISABLE KEYS */;
/*!40000 ALTER TABLE `placement_tests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `platform_settings`
--

DROP TABLE IF EXISTS `platform_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `platform_settings` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `autoApproveTenant` tinyint(1) NOT NULL DEFAULT '0',
  `graceDaysPending` int NOT NULL DEFAULT '14',
  `notifTenantBaru` tinyint(1) NOT NULL DEFAULT '1',
  `notifTagihan` tinyint(1) NOT NULL DEFAULT '1',
  `notifKeamanan` tinyint(1) NOT NULL DEFAULT '1',
  `notifLaporanMingguan` tinyint(1) NOT NULL DEFAULT '0',
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `platform_settings`
--

LOCK TABLES `platform_settings` WRITE;
/*!40000 ALTER TABLE `platform_settings` DISABLE KEYS */;
/*!40000 ALTER TABLE `platform_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rapors`
--

DROP TABLE IF EXISTS `rapors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rapors` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `periode` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ringkasan` json DEFAULT NULL,
  `rataRata` double DEFAULT NULL,
  `status` enum('DRAFT','TERBIT') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rapors_tenantId_santriId_periode_key` (`tenantId`,`santriId`,`periode`),
  KEY `rapors_tenantId_idx` (`tenantId`),
  KEY `rapors_santriId_fkey` (`santriId`),
  CONSTRAINT `rapors_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `rapors_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rapors`
--

LOCK TABLES `rapors` WRITE;
/*!40000 ALTER TABLE `rapors` DISABLE KEYS */;
/*!40000 ALTER TABLE `rapors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rekam_medis`
--

DROP TABLE IF EXISTS `rekam_medis`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rekam_medis` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `golonganDarah` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `alergi` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `riwayatPenyakit` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tinggiBadan` int DEFAULT NULL,
  `beratBadan` int DEFAULT NULL,
  `catatanKhusus` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `updatedAt` datetime(3) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `rekam_medis_santriId_key` (`santriId`),
  KEY `rekam_medis_tenantId_idx` (`tenantId`),
  CONSTRAINT `rekam_medis_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `rekam_medis_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rekam_medis`
--

LOCK TABLES `rekam_medis` WRITE;
/*!40000 ALTER TABLE `rekam_medis` DISABLE KEYS */;
/*!40000 ALTER TABLE `rekam_medis` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `remedials`
--

DROP TABLE IF EXISTS `remedials`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `remedials` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `santriId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ujianId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mapelId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `keterangan` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `hasil` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT 'PROSES',
  `tanggal` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `catatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `jadwal` datetime(3) DEFAULT NULL,
  `nilaiAwal` double DEFAULT NULL,
  `nilaiRemedial` double DEFAULT NULL,
  `ruang` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('BELUM_TES','PROSES','TUNTAS','BELUM_TUNTAS') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'BELUM_TES',
  `tenggat` datetime(3) DEFAULT NULL,
  `nilaiAkhir` double DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `remedials_ujianId_santriId_key` (`ujianId`,`santriId`),
  KEY `remedials_tenantId_idx` (`tenantId`),
  KEY `remedials_mapelId_fkey` (`mapelId`),
  KEY `remedials_santriId_fkey` (`santriId`),
  KEY `remedials_tenantId_ujianId_idx` (`tenantId`,`ujianId`),
  CONSTRAINT `remedials_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `remedials_santriId_fkey` FOREIGN KEY (`santriId`) REFERENCES `santris` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `remedials_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `remedials_ujianId_fkey` FOREIGN KEY (`ujianId`) REFERENCES `ujians` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `remedials`
--

LOCK TABLES `remedials` WRITE;
/*!40000 ALTER TABLE `remedials` DISABLE KEYS */;
/*!40000 ALTER TABLE `remedials` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rpps`
--

DROP TABLE IF EXISTS `rpps`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rpps` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mapelId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pertemuan` int NOT NULL,
  `judul` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tujuan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `kegiatan` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `penilaian` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fileUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `rpps_tenantId_idx` (`tenantId`),
  KEY `rpps_mapelId_fkey` (`mapelId`),
  CONSTRAINT `rpps_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `rpps_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rpps`
--

LOCK TABLES `rpps` WRITE;
/*!40000 ALTER TABLE `rpps` DISABLE KEYS */;
/*!40000 ALTER TABLE `rpps` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `santris`
--

DROP TABLE IF EXISTS `santris`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `santris` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nis` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nama` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `jenisKelamin` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggalLahir` datetime(3) DEFAULT NULL,
  `kelasId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `asrama` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `waliId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('AKTIF','LULUS','KELUAR') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AKTIF',
  `tahunMasuk` int NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `santris_tenantId_nis_key` (`tenantId`,`nis`),
  KEY `santris_tenantId_kelasId_idx` (`tenantId`,`kelasId`),
  KEY `santris_tenantId_idx` (`tenantId`),
  KEY `santris_kelasId_fkey` (`kelasId`),
  KEY `santris_waliId_fkey` (`waliId`),
  CONSTRAINT `santris_kelasId_fkey` FOREIGN KEY (`kelasId`) REFERENCES `kelas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `santris_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `santris_waliId_fkey` FOREIGN KEY (`waliId`) REFERENCES `wali_santris` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `santris`
--

LOCK TABLES `santris` WRITE;
/*!40000 ALTER TABLE `santris` DISABLE KEYS */;
INSERT INTO `santris` VALUES ('cmvrmwgpi000z14nxn1mb05gn','cmvrmwgeu000114nxxld6x7mx','2026001','Muhammad Fathir','L','2012-03-15 00:00:00.000','cmvrmwgm7000p14nxzaydi90u','Putra','cmvrmwgn8000t14nx4erjngjz','AKTIF',2026),('cmvrmwgr1001114nxtwlcmwhd','cmvrmwgeu000114nxxld6x7mx','2026002','Abdullah Hasan','L','2012-07-20 00:00:00.000','cmvrmwgm7000p14nxzaydi90u','Putra','cmvrmwgn8000t14nx4erjngjz','AKTIF',2026),('cmvrmwgrg001314nxl47fbp1d','cmvrmwgeu000114nxxld6x7mx','2026003','Aisyah Nur','P','2012-01-10 00:00:00.000','cmvrmwgmr000r14nx741owoc7','Putri','cmvrmwgnq000v14nx9cnkwn6u','AKTIF',2026);
/*!40000 ALTER TABLE `santris` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `silabus`
--

DROP TABLE IF EXISTS `silabus`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `silabus` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `kurikulumId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `mapelId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `judul` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `kompetensiDasar` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `materiPokok` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `alokasiWaktu` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `fileUrl` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `silabus_tenantId_idx` (`tenantId`),
  KEY `silabus_kurikulumId_fkey` (`kurikulumId`),
  KEY `silabus_mapelId_fkey` (`mapelId`),
  CONSTRAINT `silabus_kurikulumId_fkey` FOREIGN KEY (`kurikulumId`) REFERENCES `kurikulums` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `silabus_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `silabus_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `silabus`
--

LOCK TABLES `silabus` WRITE;
/*!40000 ALTER TABLE `silabus` DISABLE KEYS */;
/*!40000 ALTER TABLE `silabus` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `subscriptions`
--

DROP TABLE IF EXISTS `subscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `subscriptions` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `paketId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tanggalMulai` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `tanggalAkhir` datetime(3) DEFAULT NULL,
  `status` enum('AKTIF','EXPIRED','CANCELED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AKTIF',
  PRIMARY KEY (`id`),
  KEY `subscriptions_tenantId_idx` (`tenantId`),
  KEY `subscriptions_paketId_fkey` (`paketId`),
  CONSTRAINT `subscriptions_paketId_fkey` FOREIGN KEY (`paketId`) REFERENCES `pakets` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `subscriptions_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `subscriptions`
--

LOCK TABLES `subscriptions` WRITE;
/*!40000 ALTER TABLE `subscriptions` DISABLE KEYS */;
/*!40000 ALTER TABLE `subscriptions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tahun_ajarans`
--

DROP TABLE IF EXISTS `tahun_ajarans`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tahun_ajarans` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nama` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `aktif` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `tahun_ajarans_tenantId_nama_key` (`tenantId`,`nama`),
  CONSTRAINT `tahun_ajarans_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tahun_ajarans`
--

LOCK TABLES `tahun_ajarans` WRITE;
/*!40000 ALTER TABLE `tahun_ajarans` DISABLE KEYS */;
INSERT INTO `tahun_ajarans` VALUES ('cmvrmwgfc000314nxtqezli56','cmvrmwgeu000114nxxld6x7mx','2026/2027',1);
/*!40000 ALTER TABLE `tahun_ajarans` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tata_tertibs`
--

DROP TABLE IF EXISTS `tata_tertibs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tata_tertibs` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `judul` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `isi` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `aktif` tinyint(1) NOT NULL DEFAULT '1',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `tata_tertibs_tenantId_idx` (`tenantId`),
  CONSTRAINT `tata_tertibs_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tata_tertibs`
--

LOCK TABLES `tata_tertibs` WRITE;
/*!40000 ALTER TABLE `tata_tertibs` DISABLE KEYS */;
/*!40000 ALTER TABLE `tata_tertibs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tenants`
--

DROP TABLE IF EXISTS `tenants`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tenants` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `kodeTenant` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `namaPondok` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `logoUrl` mediumtext COLLATE utf8mb4_unicode_ci,
  `status` enum('PENDING','AKTIF','SUSPENDED','ARCHIVED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `adminAwalId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggalDaftar` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `warnaTema` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `kuotaSantriPpdb` int DEFAULT NULL,
  `statusGelombangPpdb` enum('DIBUKA','DITUTUP') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DITUTUP',
  `alamat` text COLLATE utf8mb4_unicode_ci,
  `karakteristik` json DEFAULT NULL,
  `deletedAt` datetime(3) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `tenants_kodeTenant_key` (`kodeTenant`),
  KEY `tenants_adminAwalId_fkey` (`adminAwalId`),
  CONSTRAINT `tenants_adminAwalId_fkey` FOREIGN KEY (`adminAwalId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tenants`
--

LOCK TABLES `tenants` WRITE;
/*!40000 ALTER TABLE `tenants` DISABLE KEYS */;
INSERT INTO `tenants` VALUES ('cmvrmwgeu000114nxxld6x7mx','mahad-alquran','Ma\'had Al-Qur\'an Wal Lughah',NULL,'AKTIF','cmvrmwggb000514nx2bn9wwyp','2026-10-28 04:48:35.095',NULL,NULL,'DITUTUP',NULL,NULL,NULL);
/*!40000 ALTER TABLE `tenants` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ujians`
--

DROP TABLE IF EXISTS `ujians`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ujians` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nama` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `jenis` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ULANGAN',
  `mapelId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `kelasId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tanggal` datetime(3) DEFAULT NULL,
  `durasiMenit` int DEFAULT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `updatedAt` datetime(3) NOT NULL,
  `kkm` double NOT NULL DEFAULT '75',
  `dibuatOleh` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dikunciOleh` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `dikunciPada` datetime(3) DEFAULT NULL,
  `periode` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ujians_tenantId_idx` (`tenantId`),
  KEY `ujians_mapelId_fkey` (`mapelId`),
  KEY `ujians_kelasId_fkey` (`kelasId`),
  CONSTRAINT `ujians_kelasId_fkey` FOREIGN KEY (`kelasId`) REFERENCES `kelas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `ujians_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `ujians_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ujians`
--

LOCK TABLES `ujians` WRITE;
/*!40000 ALTER TABLE `ujians` DISABLE KEYS */;
/*!40000 ALTER TABLE `ujians` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `user_notif_settings`
--

DROP TABLE IF EXISTS `user_notif_settings`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `user_notif_settings` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `userId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `perizinanBaru` tinyint(1) NOT NULL DEFAULT '1',
  `pelanggaranBaru` tinyint(1) NOT NULL DEFAULT '1',
  `waliBelumAktivasi` tinyint(1) NOT NULL DEFAULT '1',
  `eskalasiDarurat` tinyint(1) NOT NULL DEFAULT '1',
  `rekapAbsensiShalat` tinyint(1) NOT NULL DEFAULT '0',
  `updatedAt` datetime(3) NOT NULL,
  `absensiAnak` tinyint(1) NOT NULL DEFAULT '1',
  `kesehatanAnak` tinyint(1) NOT NULL DEFAULT '1',
  `nilaiRapor` tinyint(1) NOT NULL DEFAULT '1',
  `pelanggaranAnak` tinyint(1) NOT NULL DEFAULT '1',
  `perizinanAnak` tinyint(1) NOT NULL DEFAULT '1',
  `jadwalMengajar` tinyint(1) NOT NULL DEFAULT '1',
  `pengingatAbsensi` tinyint(1) NOT NULL DEFAULT '1',
  `pengingatNilai` tinyint(1) NOT NULL DEFAULT '1',
  `pengumumanPondok` tinyint(1) NOT NULL DEFAULT '1',
  `laporanKesantrian` tinyint(1) NOT NULL DEFAULT '1',
  `laporanKeuangan` tinyint(1) NOT NULL DEFAULT '1',
  `pendaftaranBaru` tinyint(1) NOT NULL DEFAULT '1',
  `ringkasanHarian` tinyint(1) NOT NULL DEFAULT '1',
  PRIMARY KEY (`id`),
  UNIQUE KEY `user_notif_settings_userId_key` (`userId`),
  CONSTRAINT `user_notif_settings_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `user_notif_settings`
--

LOCK TABLES `user_notif_settings` WRITE;
/*!40000 ALTER TABLE `user_notif_settings` DISABLE KEYS */;
/*!40000 ALTER TABLE `user_notif_settings` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `users`
--

DROP TABLE IF EXISTS `users`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `users` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `nama` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `passwordHash` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `role` enum('SUPER_ADMIN','ADMIN','USTADZ','MUSYRIF','WALI_SANTRI','SANTRI','PIMPINAN') COLLATE utf8mb4_unicode_ci NOT NULL,
  `status` enum('AKTIF','NONAKTIF') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'AKTIF',
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  `isRootAdmin` tinyint(1) NOT NULL DEFAULT '0',
  `noHp` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `subRole` enum('OPERASIONAL','KEUANGAN') COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `users_tenantId_email_key` (`tenantId`,`email`),
  KEY `users_tenantId_idx` (`tenantId`),
  CONSTRAINT `users_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `users`
--

LOCK TABLES `users` WRITE;
/*!40000 ALTER TABLE `users` DISABLE KEYS */;
INSERT INTO `users` VALUES ('cmvrmwga0000014nxkswf2wlo',NULL,'Super Admin Platform','superadmin@sistempesantren.com','$2a$10$aFLTYKsM3l1.V0rwV.PIXu7hzMWz7ZGBD4Po4ombmnHmTpldAZcSW','SUPER_ADMIN','AKTIF','2026-10-28 04:48:34.921',0,NULL,NULL),('cmvrmwggb000514nx2bn9wwyp','cmvrmwgeu000114nxxld6x7mx','Admin Pondok','admin@mahad.id','$2a$10$7GrSErdpVwrm9boe.LXgqOvZzY0qzvMzGW958HdCuTbFshXRcVtlG','ADMIN','AKTIF','2026-10-28 04:48:35.147',0,NULL,NULL),('cmvrmwggx000714nx5qh11vnv','cmvrmwgeu000114nxxld6x7mx','Ustadz Ahmad','ustadz@mahad.id','$2a$10$7GrSErdpVwrm9boe.LXgqOvZzY0qzvMzGW958HdCuTbFshXRcVtlG','USTADZ','AKTIF','2026-10-28 04:48:35.169',0,NULL,NULL),('cmvrmwgha000914nxjrg8v0nv','cmvrmwgeu000114nxxld6x7mx','Musyrif Ali','musyrif@mahad.id','$2a$10$7GrSErdpVwrm9boe.LXgqOvZzY0qzvMzGW958HdCuTbFshXRcVtlG','MUSYRIF','AKTIF','2026-10-28 04:48:35.183',0,NULL,NULL),('cmvrmwghp000b14nxh8gyj1cw','cmvrmwgeu000114nxxld6x7mx','Mudir Pondok','mudir@mahad.id','$2a$10$7GrSErdpVwrm9boe.LXgqOvZzY0qzvMzGW958HdCuTbFshXRcVtlG','PIMPINAN','AKTIF','2026-10-28 04:48:35.197',0,NULL,NULL),('cmvrmwgo7000x14nxu2slhumb','cmvrmwgeu000114nxxld6x7mx','H. Budi Santoso','wali@mahad.id','$2a$10$7GrSErdpVwrm9boe.LXgqOvZzY0qzvMzGW958HdCuTbFshXRcVtlG','WALI_SANTRI','AKTIF','2026-10-28 04:48:35.431',0,NULL,NULL);
/*!40000 ALTER TABLE `users` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ustadz_mengajar`
--

DROP TABLE IF EXISTS `ustadz_mengajar`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ustadz_mengajar` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ustadzId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `kelasId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `mapelId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `createdAt` datetime(3) NOT NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ustadz_mengajar_ustadzId_kelasId_mapelId_key` (`ustadzId`,`kelasId`,`mapelId`),
  KEY `ustadz_mengajar_tenantId_kelasId_idx` (`tenantId`,`kelasId`),
  KEY `ustadz_mengajar_tenantId_mapelId_idx` (`tenantId`,`mapelId`),
  KEY `ustadz_mengajar_kelasId_fkey` (`kelasId`),
  KEY `ustadz_mengajar_mapelId_fkey` (`mapelId`),
  CONSTRAINT `ustadz_mengajar_kelasId_fkey` FOREIGN KEY (`kelasId`) REFERENCES `kelas` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `ustadz_mengajar_mapelId_fkey` FOREIGN KEY (`mapelId`) REFERENCES `mata_pelajarans` (`id`) ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT `ustadz_mengajar_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `ustadz_mengajar_ustadzId_fkey` FOREIGN KEY (`ustadzId`) REFERENCES `ustadzs` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ustadz_mengajar`
--

LOCK TABLES `ustadz_mengajar` WRITE;
/*!40000 ALTER TABLE `ustadz_mengajar` DISABLE KEYS */;
/*!40000 ALTER TABLE `ustadz_mengajar` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ustadzs`
--

DROP TABLE IF EXISTS `ustadzs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ustadzs` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nama` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `jenis` enum('GURU','MUSYRIF') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'GURU',
  `noHp` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `userId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `ustadzs_tenantId_idx` (`tenantId`),
  CONSTRAINT `ustadzs_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ustadzs`
--

LOCK TABLES `ustadzs` WRITE;
/*!40000 ALTER TABLE `ustadzs` DISABLE KEYS */;
INSERT INTO `ustadzs` VALUES ('cmvrmwgje000d14nxhv43rf8y','cmvrmwgeu000114nxxld6x7mx','Ustadz Ahmad','GURU',NULL,'cmvrmwggx000714nx5qh11vnv'),('cmvrmwgjz000f14nxm9zhgl96','cmvrmwgeu000114nxxld6x7mx','Ustadzah Siti','GURU',NULL,NULL),('cmvrmwgkd000h14nxql9o6f99','cmvrmwgeu000114nxxld6x7mx','Musyrif Ali','MUSYRIF',NULL,'cmvrmwgha000914nxjrg8v0nv');
/*!40000 ALTER TABLE `ustadzs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `wali_santris`
--

DROP TABLE IF EXISTS `wali_santris`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `wali_santris` (
  `id` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `tenantId` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `nama` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `noHp` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `email` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `hubungan` varchar(191) COLLATE utf8mb4_unicode_ci NOT NULL,
  `userId` varchar(191) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `wali_santris_tenantId_idx` (`tenantId`),
  KEY `wali_santris_userId_fkey` (`userId`),
  CONSTRAINT `wali_santris_tenantId_fkey` FOREIGN KEY (`tenantId`) REFERENCES `tenants` (`id`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `wali_santris_userId_fkey` FOREIGN KEY (`userId`) REFERENCES `users` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `wali_santris`
--

LOCK TABLES `wali_santris` WRITE;
/*!40000 ALTER TABLE `wali_santris` DISABLE KEYS */;
INSERT INTO `wali_santris` VALUES ('cmvrmwgn8000t14nx4erjngjz','cmvrmwgeu000114nxxld6x7mx','H. Budi Santoso','08123456789',NULL,'Ayah','cmvrmwgo7000x14nxu2slhumb'),('cmvrmwgnq000v14nx9cnkwn6u','cmvrmwgeu000114nxxld6x7mx','Ibu Siti Rahma','08987654321',NULL,'Ibu',NULL);
/*!40000 ALTER TABLE `wali_santris` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Dumping routines for database 'pesantren'
--
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-10-28  4:50:37
