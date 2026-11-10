-- CreateEnum
CREATE TYPE "Role" AS ENUM ('SUPER_ADMIN', 'ADMIN', 'USTADZ', 'MUSYRIF', 'WALI_SANTRI', 'SANTRI', 'PIMPINAN');

-- CreateEnum
CREATE TYPE "TenantStatus" AS ENUM ('PENDING', 'AKTIF', 'SUSPENDED', 'ARCHIVED');

-- CreateEnum
CREATE TYPE "StatusGelombangPpdb" AS ENUM ('DIBUKA', 'DITUTUP');

-- CreateEnum
CREATE TYPE "UserStatus" AS ENUM ('AKTIF', 'NONAKTIF');

-- CreateEnum
CREATE TYPE "PlatformSubRole" AS ENUM ('OPERASIONAL', 'KEUANGAN');

-- CreateEnum
CREATE TYPE "SantriStatus" AS ENUM ('AKTIF', 'LULUS', 'KELUAR');

-- CreateEnum
CREATE TYPE "JenisUstadz" AS ENUM ('GURU', 'MUSYRIF');

-- CreateEnum
CREATE TYPE "AbsensiStatus" AS ENUM ('HADIR', 'IZIN', 'SAKIT', 'ALPA');

-- CreateEnum
CREATE TYPE "JenisNilai" AS ENUM ('HARIAN', 'ULANGAN', 'TAHFIDZ', 'BAHASA_ARAB');

-- CreateEnum
CREATE TYPE "JenisSetoran" AS ENUM ('ZIYADAH', 'MURAJAAH');

-- CreateEnum
CREATE TYPE "KualitasSetoran" AS ENUM ('MUMTAZ', 'JAYYID_JIDDAN', 'JAYYID', 'MAQBUL', 'DHAIF');

-- CreateEnum
CREATE TYPE "JenisPerizinan" AS ENUM ('PULANG', 'KELUAR');

-- CreateEnum
CREATE TYPE "StatusApproval" AS ENUM ('DIAJUKAN', 'DISETUJUI', 'DITOLAK', 'KEMBALI', 'TELAT');

-- CreateEnum
CREATE TYPE "StatusKesehatan" AS ENUM ('RAWAT_JALAN', 'DIRUJUK', 'SEMBUH');

-- CreateEnum
CREATE TYPE "JenisNotifikasi" AS ENUM ('TENANT_BARU', 'TAGIHAN', 'KEAMANAN', 'LAPORAN', 'PELANGGARAN', 'KESEHATAN', 'PERIZINAN', 'NILAI', 'ABSENSI', 'SISTEM', 'DARURAT', 'WALI_BELUM_AKTIVASI', 'RINGKASAN_HARIAN', 'LAPORAN_KESANTRIAN', 'PENDAFTARAN_BARU', 'LAPORAN_KEUANGAN');

-- CreateEnum
CREATE TYPE "StatusIbadah" AS ENUM ('HADIR', 'IZIN', 'ALPA');

-- CreateEnum
CREATE TYPE "StatusDarurat" AS ENUM ('BARU', 'DITANGANI', 'SELESAI');

-- CreateEnum
CREATE TYPE "AuditKategori" AS ENUM ('KEAMANAN', 'DATA', 'BILLING', 'SISTEM');

-- CreateEnum
CREATE TYPE "AuditTingkat" AS ENUM ('INFO', 'WARNING', 'CRITICAL');

-- CreateEnum
CREATE TYPE "StatusPendaftaran" AS ENUM ('DIAJUKAN', 'TES', 'DITERIMA', 'DITOLAK', 'WAITING_LIST');

-- CreateEnum
CREATE TYPE "StatusSubscription" AS ENUM ('AKTIF', 'EXPIRED', 'CANCELED');

-- CreateEnum
CREATE TYPE "StatusInvoice" AS ENUM ('BELUM_BAYAR', 'LUNAS', 'BATAL');

-- CreateEnum
CREATE TYPE "PeriodePaket" AS ENUM ('HARIAN', 'BULANAN', 'TAHUNAN');

-- CreateEnum
CREATE TYPE "StatusKehadiranUjian" AS ENUM ('HADIR', 'SAKIT', 'IZIN', 'ALPA');

-- CreateEnum
CREATE TYPE "StatusRemedial" AS ENUM ('BELUM_TES', 'PROSES', 'TUNTAS', 'BELUM_TUNTAS');

-- CreateEnum
CREATE TYPE "StatusRapor" AS ENUM ('DRAFT', 'TERBIT');

-- CreateEnum
CREATE TYPE "PredikatKelulusan" AS ENUM ('MEMUASKAN', 'HONOUR', 'CUM_LAUDE', 'SUMMA_CUM_LAUDE');

-- CreateTable
CREATE TABLE "tenants" (
    "id" TEXT NOT NULL,
    "kodeTenant" TEXT NOT NULL,
    "namaPondok" TEXT NOT NULL,
    "logoUrl" TEXT,
    "warnaTema" TEXT,
    "alamat" TEXT,
    "karakteristik" JSONB,
    "status" "TenantStatus" NOT NULL DEFAULT 'PENDING',
    "kuotaSantriPpdb" INTEGER,
    "statusGelombangPpdb" "StatusGelombangPpdb" NOT NULL DEFAULT 'DITUTUP',
    "adminAwalId" TEXT,
    "tanggalDaftar" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "deletedAt" TIMESTAMP(3),

    CONSTRAINT "tenants_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tenant_berkas" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "namaFile" TEXT NOT NULL,
    "mime" TEXT NOT NULL,
    "ukuran" INTEGER NOT NULL,
    "data" BYTEA NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tenant_berkas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "users" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT,
    "nama" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "passwordHash" TEXT NOT NULL,
    "role" "Role" NOT NULL,
    "status" "UserStatus" NOT NULL DEFAULT 'AKTIF',
    "noHp" TEXT,
    "isRootAdmin" BOOLEAN NOT NULL DEFAULT false,
    "subRole" "PlatformSubRole",
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "santris" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "nis" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "jenisKelamin" TEXT NOT NULL,
    "tanggalLahir" TIMESTAMP(3),
    "kelasId" TEXT,
    "asrama" TEXT,
    "waliId" TEXT,
    "status" "SantriStatus" NOT NULL DEFAULT 'AKTIF',
    "tahunMasuk" INTEGER NOT NULL,

    CONSTRAINT "santris_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ustadzs" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "jenis" "JenisUstadz" NOT NULL DEFAULT 'GURU',
    "noHp" TEXT,
    "userId" TEXT,

    CONSTRAINT "ustadzs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kelas" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "namaKelas" TEXT NOT NULL,
    "tingkat" TEXT NOT NULL,
    "waliKelasId" TEXT,
    "tahunAjaranId" TEXT,

    CONSTRAINT "kelas_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ustadz_mengajar" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "ustadzId" TEXT NOT NULL,
    "kelasId" TEXT NOT NULL,
    "mapelId" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ustadz_mengajar_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "jurnal_mengajars" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "kelasId" TEXT NOT NULL,
    "mapelId" TEXT,
    "tanggal" TIMESTAMP(3) NOT NULL,
    "materi" VARCHAR(500) NOT NULL,
    "catatan" VARCHAR(300),
    "inputOleh" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "jurnal_mengajars_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "wali_santris" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "noHp" TEXT,
    "email" TEXT,
    "hubungan" TEXT NOT NULL,
    "userId" TEXT,

    CONSTRAINT "wali_santris_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "mata_pelajarans" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "namaMapel" TEXT NOT NULL,
    "kode" TEXT,
    "jenis" TEXT,
    "kkm" DOUBLE PRECISION NOT NULL DEFAULT 75,

    CONSTRAINT "mata_pelajarans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tahun_ajarans" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "aktif" BOOLEAN NOT NULL DEFAULT true,

    CONSTRAINT "tahun_ajarans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "absensis" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "kelasId" TEXT,
    "mapelId" TEXT,
    "tanggal" TIMESTAMP(3) NOT NULL,
    "status" "AbsensiStatus" NOT NULL,
    "catatan" TEXT,
    "inputOleh" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "absensis_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nilais" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "mapelId" TEXT NOT NULL,
    "tahunAjaranId" TEXT,
    "jenis" "JenisNilai" NOT NULL,
    "nilai" DOUBLE PRECISION NOT NULL,
    "keterangan" TEXT,
    "skill" TEXT NOT NULL DEFAULT '',
    "tanggal" DATE NOT NULL,
    "inputOleh" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "nilais_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "capaian_tahfidzs" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "juz" INTEGER NOT NULL,
    "halaman" INTEGER NOT NULL,
    "halamanMulai" INTEGER,
    "halamanSelesai" INTEGER,
    "suratMulai" INTEGER,
    "ayatMulai" INTEGER,
    "suratSelesai" INTEGER,
    "ayatSelesai" INTEGER,
    "ayatAbsMulai" INTEGER,
    "ayatAbsSelesai" INTEGER,
    "jenis" "JenisSetoran" NOT NULL DEFAULT 'ZIYADAH',
    "kualitas" "KualitasSetoran",
    "tanggalSetor" TIMESTAMP(3) NOT NULL,
    "catatanUstadz" TEXT,
    "inputOleh" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "capaian_tahfidzs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pelanggarans" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "jenisPelanggaran" TEXT NOT NULL,
    "poin" INTEGER NOT NULL,
    "tanggal" TIMESTAMP(3) NOT NULL,
    "pelaporId" TEXT,
    "tindakLanjut" TEXT,
    "status" TEXT NOT NULL DEFAULT 'DICATAT',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pelanggarans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "perizinan" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "jenis" "JenisPerizinan" NOT NULL,
    "tanggalKeluar" TIMESTAMP(3) NOT NULL,
    "tanggalKembali" TIMESTAMP(3),
    "rencanaKembali" TIMESTAMP(3),
    "pendamping" TEXT,
    "alasan" TEXT NOT NULL,
    "statusApproval" "StatusApproval" NOT NULL DEFAULT 'DIAJUKAN',
    "disetujuiOleh" TEXT,
    "catatan" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "perizinan_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kesehatan_logs" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "keluhan" TEXT NOT NULL,
    "diagnosa" TEXT,
    "tindakan" TEXT,
    "obat" TEXT,
    "tempat" TEXT NOT NULL DEFAULT 'UKS',
    "tanggal" TIMESTAMP(3) NOT NULL,
    "status" "StatusKesehatan" NOT NULL DEFAULT 'RAWAT_JALAN',
    "inputOleh" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "kesehatan_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kunjungan_walis" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "waliId" TEXT,
    "namaWali" TEXT,
    "status" TEXT NOT NULL DEFAULT 'BERLANGSUNG',
    "tanggal" TIMESTAMP(3) NOT NULL,
    "selesaiAt" TIMESTAMP(3),
    "catatan" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "kunjungan_walis_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifikasis" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT,
    "userId" TEXT,
    "jenis" "JenisNotifikasi" NOT NULL,
    "pesan" TEXT NOT NULL,
    "statusBaca" BOOLEAN NOT NULL DEFAULT false,
    "tanggal" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifikasis_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "tata_tertibs" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "judul" TEXT NOT NULL,
    "isi" TEXT NOT NULL,
    "aktif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "tata_tertibs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "audit_logs" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT,
    "userId" TEXT,
    "userNama" TEXT,
    "userRole" TEXT,
    "action" TEXT NOT NULL,
    "entity" TEXT NOT NULL,
    "entityId" TEXT,
    "kategori" "AuditKategori" NOT NULL DEFAULT 'DATA',
    "tingkat" "AuditTingkat" NOT NULL DEFAULT 'INFO',
    "judul" TEXT,
    "deskripsi" TEXT,
    "meta" TEXT,
    "ip" TEXT,
    "data" JSONB,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "audit_logs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pendaftarans" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "jenisKelamin" TEXT NOT NULL,
    "tanggalLahir" TIMESTAMP(3),
    "asalSekolah" TEXT,
    "noHp" TEXT,
    "email" TEXT,
    "alamat" TEXT,
    "jalur" TEXT,
    "fotoUrl" TEXT,
    "kartuKeluargaUrl" TEXT,
    "aktaLahirUrl" TEXT,
    "status" "StatusPendaftaran" NOT NULL DEFAULT 'DIAJUKAN',
    "catatan" TEXT,
    "tanggalDaftar" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pendaftarans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "placement_tests" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "pendaftaranId" TEXT NOT NULL,
    "mapelId" TEXT,
    "nilai" DOUBLE PRECISION,
    "hasil" TEXT,
    "catatan" TEXT,
    "tanggal" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "placement_tests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kurikulums" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "tahunAjaranId" TEXT,
    "deskripsi" TEXT,
    "aktif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "kurikulums_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "silabus" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "kurikulumId" TEXT,
    "mapelId" TEXT,
    "judul" TEXT NOT NULL,
    "kompetensiDasar" TEXT,
    "materiPokok" TEXT,
    "alokasiWaktu" TEXT,
    "fileUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "silabus_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rpps" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "mapelId" TEXT,
    "pertemuan" INTEGER NOT NULL,
    "judul" TEXT NOT NULL,
    "tujuan" TEXT,
    "kegiatan" TEXT,
    "penilaian" TEXT,
    "fileUrl" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rpps_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rekam_medis" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "golonganDarah" TEXT,
    "alergi" TEXT,
    "riwayatPenyakit" TEXT,
    "tinggiBadan" INTEGER,
    "beratBadan" INTEGER,
    "catatanKhusus" TEXT,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rekam_medis_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pakets" (
    "id" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "harga" DOUBLE PRECISION NOT NULL,
    "limitSantri" INTEGER NOT NULL,
    "periode" "PeriodePaket" NOT NULL DEFAULT 'TAHUNAN',
    "fitur" JSONB,
    "aktif" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pakets_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "subscriptions" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "paketId" TEXT NOT NULL,
    "tanggalMulai" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "tanggalAkhir" TIMESTAMP(3),
    "status" "StatusSubscription" NOT NULL DEFAULT 'AKTIF',

    CONSTRAINT "subscriptions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "invoices" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "noInvoice" TEXT NOT NULL,
    "jumlah" DOUBLE PRECISION NOT NULL,
    "status" "StatusInvoice" NOT NULL DEFAULT 'BELUM_BAYAR',
    "tanggalJatuhTempo" TIMESTAMP(3),
    "tanggalBayar" TIMESTAMP(3),
    "metodeBayar" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "invoices_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ujians" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "nama" TEXT NOT NULL,
    "jenis" TEXT NOT NULL DEFAULT 'ULANGAN',
    "mapelId" TEXT,
    "kelasId" TEXT,
    "tanggal" TIMESTAMP(3),
    "durasiMenit" INTEGER,
    "kkm" DOUBLE PRECISION NOT NULL DEFAULT 75,
    "dibuatOleh" TEXT,
    "periode" TEXT,
    "dikunciPada" TIMESTAMP(3),
    "dikunciOleh" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ujians_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nilai_ujians" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "ujianId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "nilai" DOUBLE PRECISION,
    "status" "StatusKehadiranUjian" NOT NULL DEFAULT 'HADIR',
    "catatan" TEXT,
    "inputOleh" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "nilai_ujians_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "remedials" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "ujianId" TEXT,
    "mapelId" TEXT,
    "keterangan" TEXT NOT NULL,
    "hasil" TEXT DEFAULT 'PROSES',
    "status" "StatusRemedial" NOT NULL DEFAULT 'BELUM_TES',
    "nilaiAwal" DOUBLE PRECISION,
    "nilaiRemedial" DOUBLE PRECISION,
    "nilaiAkhir" DOUBLE PRECISION,
    "catatan" TEXT,
    "jadwal" TIMESTAMP(3),
    "ruang" TEXT,
    "tenggat" TIMESTAMP(3),
    "tanggal" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "remedials_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "rapors" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "periode" TEXT NOT NULL,
    "ringkasan" JSONB,
    "rataRata" DOUBLE PRECISION,
    "status" "StatusRapor" NOT NULL DEFAULT 'DRAFT',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "rapors_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "kelulusans" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "status" TEXT NOT NULL DEFAULT 'LULUS',
    "tanggalKelulusan" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "predikat" "PredikatKelulusan",
    "juzYangDiHafal" INTEGER,
    "catatan" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "kelulusans_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "konselings" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "tanggal" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "konselorId" TEXT,
    "createdById" TEXT,
    "topik" TEXT NOT NULL,
    "catatan" TEXT NOT NULL,
    "tindakLanjut" TEXT,
    "privat" BOOLEAN NOT NULL DEFAULT true,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "konselings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pembinaan_karakters" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "tanggal" TIMESTAMP(3) NOT NULL,
    "kategori" TEXT NOT NULL,
    "catatan" TEXT NOT NULL,
    "pelaporId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pembinaan_karakters_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "pembinaan_ibadahs" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT NOT NULL,
    "tanggal" TIMESTAMP(3) NOT NULL,
    "jenisIbadah" TEXT NOT NULL,
    "status" "StatusIbadah" NOT NULL DEFAULT 'HADIR',
    "catatan" TEXT,
    "pelaporId" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "pembinaan_ibadahs_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "keadaan_darurats" (
    "id" TEXT NOT NULL,
    "tenantId" TEXT NOT NULL,
    "santriId" TEXT,
    "jenis" TEXT NOT NULL,
    "lokasi" TEXT,
    "deskripsi" TEXT NOT NULL,
    "status" "StatusDarurat" NOT NULL DEFAULT 'BARU',
    "tindakLanjut" TEXT,
    "pelaporId" TEXT,
    "tanggal" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "keadaan_darurats_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_notif_settings" (
    "id" TEXT NOT NULL,
    "userId" TEXT NOT NULL,
    "perizinanBaru" BOOLEAN NOT NULL DEFAULT true,
    "pelanggaranBaru" BOOLEAN NOT NULL DEFAULT true,
    "waliBelumAktivasi" BOOLEAN NOT NULL DEFAULT true,
    "eskalasiDarurat" BOOLEAN NOT NULL DEFAULT true,
    "rekapAbsensiShalat" BOOLEAN NOT NULL DEFAULT false,
    "perizinanAnak" BOOLEAN NOT NULL DEFAULT true,
    "pelanggaranAnak" BOOLEAN NOT NULL DEFAULT true,
    "kesehatanAnak" BOOLEAN NOT NULL DEFAULT true,
    "nilaiRapor" BOOLEAN NOT NULL DEFAULT true,
    "absensiAnak" BOOLEAN NOT NULL DEFAULT true,
    "pengingatAbsensi" BOOLEAN NOT NULL DEFAULT true,
    "pengingatNilai" BOOLEAN NOT NULL DEFAULT true,
    "jadwalMengajar" BOOLEAN NOT NULL DEFAULT true,
    "pengumumanPondok" BOOLEAN NOT NULL DEFAULT true,
    "ringkasanHarian" BOOLEAN NOT NULL DEFAULT true,
    "laporanKesantrian" BOOLEAN NOT NULL DEFAULT true,
    "pendaftaranBaru" BOOLEAN NOT NULL DEFAULT true,
    "laporanKeuangan" BOOLEAN NOT NULL DEFAULT true,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "user_notif_settings_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "platform_settings" (
    "id" TEXT NOT NULL,
    "autoApproveTenant" BOOLEAN NOT NULL DEFAULT false,
    "graceDaysPending" INTEGER NOT NULL DEFAULT 14,
    "notifTenantBaru" BOOLEAN NOT NULL DEFAULT true,
    "notifTagihan" BOOLEAN NOT NULL DEFAULT true,
    "notifKeamanan" BOOLEAN NOT NULL DEFAULT true,
    "notifLaporanMingguan" BOOLEAN NOT NULL DEFAULT false,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "platform_settings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "tenants_kodeTenant_key" ON "tenants"("kodeTenant");

-- CreateIndex
CREATE INDEX "tenant_berkas_tenantId_idx" ON "tenant_berkas"("tenantId");

-- CreateIndex
CREATE INDEX "users_tenantId_idx" ON "users"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "users_tenantId_email_key" ON "users"("tenantId", "email");

-- CreateIndex
CREATE INDEX "santris_tenantId_kelasId_idx" ON "santris"("tenantId", "kelasId");

-- CreateIndex
CREATE INDEX "santris_tenantId_idx" ON "santris"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "santris_tenantId_nis_key" ON "santris"("tenantId", "nis");

-- CreateIndex
CREATE INDEX "ustadzs_tenantId_idx" ON "ustadzs"("tenantId");

-- CreateIndex
CREATE INDEX "kelas_tenantId_idx" ON "kelas"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "kelas_tenantId_namaKelas_tahunAjaranId_key" ON "kelas"("tenantId", "namaKelas", "tahunAjaranId");

-- CreateIndex
CREATE INDEX "ustadz_mengajar_tenantId_kelasId_idx" ON "ustadz_mengajar"("tenantId", "kelasId");

-- CreateIndex
CREATE INDEX "ustadz_mengajar_tenantId_mapelId_idx" ON "ustadz_mengajar"("tenantId", "mapelId");

-- CreateIndex
CREATE UNIQUE INDEX "ustadz_mengajar_ustadzId_kelasId_mapelId_key" ON "ustadz_mengajar"("ustadzId", "kelasId", "mapelId");

-- CreateIndex
CREATE INDEX "jurnal_mengajars_tenantId_tanggal_idx" ON "jurnal_mengajars"("tenantId", "tanggal");

-- CreateIndex
CREATE INDEX "jurnal_mengajars_tenantId_kelasId_idx" ON "jurnal_mengajars"("tenantId", "kelasId");

-- CreateIndex
CREATE INDEX "jurnal_mengajars_tenantId_inputOleh_idx" ON "jurnal_mengajars"("tenantId", "inputOleh");

-- CreateIndex
CREATE INDEX "wali_santris_tenantId_idx" ON "wali_santris"("tenantId");

-- CreateIndex
CREATE INDEX "mata_pelajarans_tenantId_idx" ON "mata_pelajarans"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "mata_pelajarans_tenantId_namaMapel_key" ON "mata_pelajarans"("tenantId", "namaMapel");

-- CreateIndex
CREATE UNIQUE INDEX "tahun_ajarans_tenantId_nama_key" ON "tahun_ajarans"("tenantId", "nama");

-- CreateIndex
CREATE INDEX "absensis_tenantId_santriId_tanggal_idx" ON "absensis"("tenantId", "santriId", "tanggal");

-- CreateIndex
CREATE INDEX "absensis_tenantId_tanggal_idx" ON "absensis"("tenantId", "tanggal");

-- CreateIndex
CREATE INDEX "absensis_tenantId_mapelId_tanggal_idx" ON "absensis"("tenantId", "mapelId", "tanggal");

-- CreateIndex
CREATE INDEX "absensis_tenantId_idx" ON "absensis"("tenantId");

-- CreateIndex
CREATE INDEX "nilais_tenantId_santriId_mapelId_idx" ON "nilais"("tenantId", "santriId", "mapelId");

-- CreateIndex
CREATE INDEX "nilais_tenantId_tahunAjaranId_idx" ON "nilais"("tenantId", "tahunAjaranId");

-- CreateIndex
CREATE INDEX "nilais_tenantId_tanggal_idx" ON "nilais"("tenantId", "tanggal");

-- CreateIndex
CREATE INDEX "nilais_tenantId_idx" ON "nilais"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "nilais_santriId_mapelId_jenis_skill_tanggal_key" ON "nilais"("santriId", "mapelId", "jenis", "skill", "tanggal");

-- CreateIndex
CREATE INDEX "capaian_tahfidzs_tenantId_santriId_idx" ON "capaian_tahfidzs"("tenantId", "santriId");

-- CreateIndex
CREATE INDEX "capaian_tahfidzs_tenantId_santriId_ayatAbsSelesai_idx" ON "capaian_tahfidzs"("tenantId", "santriId", "ayatAbsSelesai");

-- CreateIndex
CREATE INDEX "pelanggarans_tenantId_santriId_idx" ON "pelanggarans"("tenantId", "santriId");

-- CreateIndex
CREATE INDEX "pelanggarans_tenantId_tanggal_idx" ON "pelanggarans"("tenantId", "tanggal");

-- CreateIndex
CREATE INDEX "perizinan_tenantId_santriId_idx" ON "perizinan"("tenantId", "santriId");

-- CreateIndex
CREATE INDEX "perizinan_tenantId_tanggalKeluar_idx" ON "perizinan"("tenantId", "tanggalKeluar");

-- CreateIndex
CREATE INDEX "perizinan_tenantId_idx" ON "perizinan"("tenantId");

-- CreateIndex
CREATE INDEX "kesehatan_logs_tenantId_santriId_idx" ON "kesehatan_logs"("tenantId", "santriId");

-- CreateIndex
CREATE INDEX "kesehatan_logs_tenantId_tanggal_idx" ON "kesehatan_logs"("tenantId", "tanggal");

-- CreateIndex
CREATE INDEX "kesehatan_logs_tenantId_idx" ON "kesehatan_logs"("tenantId");

-- CreateIndex
CREATE INDEX "kunjungan_walis_tenantId_santriId_idx" ON "kunjungan_walis"("tenantId", "santriId");

-- CreateIndex
CREATE INDEX "notifikasis_tenantId_userId_statusBaca_idx" ON "notifikasis"("tenantId", "userId", "statusBaca");

-- CreateIndex
CREATE INDEX "tata_tertibs_tenantId_idx" ON "tata_tertibs"("tenantId");

-- CreateIndex
CREATE INDEX "audit_logs_tenantId_entity_createdAt_idx" ON "audit_logs"("tenantId", "entity", "createdAt");

-- CreateIndex
CREATE INDEX "audit_logs_tenantId_createdAt_idx" ON "audit_logs"("tenantId", "createdAt");

-- CreateIndex
CREATE INDEX "audit_logs_kategori_createdAt_idx" ON "audit_logs"("kategori", "createdAt");

-- CreateIndex
CREATE INDEX "audit_logs_tingkat_createdAt_idx" ON "audit_logs"("tingkat", "createdAt");

-- CreateIndex
CREATE INDEX "audit_logs_action_ip_createdAt_idx" ON "audit_logs"("action", "ip", "createdAt");

-- CreateIndex
CREATE INDEX "audit_logs_createdAt_idx" ON "audit_logs"("createdAt");

-- CreateIndex
CREATE INDEX "pendaftarans_tenantId_status_idx" ON "pendaftarans"("tenantId", "status");

-- CreateIndex
CREATE INDEX "pendaftarans_tenantId_idx" ON "pendaftarans"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "placement_tests_pendaftaranId_key" ON "placement_tests"("pendaftaranId");

-- CreateIndex
CREATE INDEX "placement_tests_tenantId_idx" ON "placement_tests"("tenantId");

-- CreateIndex
CREATE INDEX "kurikulums_tenantId_idx" ON "kurikulums"("tenantId");

-- CreateIndex
CREATE INDEX "silabus_tenantId_idx" ON "silabus"("tenantId");

-- CreateIndex
CREATE INDEX "rpps_tenantId_idx" ON "rpps"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "rekam_medis_santriId_key" ON "rekam_medis"("santriId");

-- CreateIndex
CREATE INDEX "rekam_medis_tenantId_idx" ON "rekam_medis"("tenantId");

-- CreateIndex
CREATE INDEX "subscriptions_tenantId_idx" ON "subscriptions"("tenantId");

-- CreateIndex
CREATE INDEX "invoices_tenantId_idx" ON "invoices"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "invoices_tenantId_noInvoice_key" ON "invoices"("tenantId", "noInvoice");

-- CreateIndex
CREATE INDEX "ujians_tenantId_idx" ON "ujians"("tenantId");

-- CreateIndex
CREATE INDEX "nilai_ujians_tenantId_idx" ON "nilai_ujians"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "nilai_ujians_ujianId_santriId_key" ON "nilai_ujians"("ujianId", "santriId");

-- CreateIndex
CREATE INDEX "remedials_tenantId_idx" ON "remedials"("tenantId");

-- CreateIndex
CREATE INDEX "remedials_tenantId_ujianId_idx" ON "remedials"("tenantId", "ujianId");

-- CreateIndex
CREATE UNIQUE INDEX "remedials_ujianId_santriId_key" ON "remedials"("ujianId", "santriId");

-- CreateIndex
CREATE INDEX "rapors_tenantId_idx" ON "rapors"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "rapors_tenantId_santriId_periode_key" ON "rapors"("tenantId", "santriId", "periode");

-- CreateIndex
CREATE INDEX "kelulusans_tenantId_idx" ON "kelulusans"("tenantId");

-- CreateIndex
CREATE UNIQUE INDEX "kelulusans_tenantId_santriId_key" ON "kelulusans"("tenantId", "santriId");

-- CreateIndex
CREATE INDEX "konselings_tenantId_idx" ON "konselings"("tenantId");

-- CreateIndex
CREATE INDEX "konselings_tenantId_createdById_idx" ON "konselings"("tenantId", "createdById");

-- CreateIndex
CREATE INDEX "pembinaan_karakters_tenantId_santriId_idx" ON "pembinaan_karakters"("tenantId", "santriId");

-- CreateIndex
CREATE INDEX "pembinaan_karakters_tenantId_tanggal_idx" ON "pembinaan_karakters"("tenantId", "tanggal");

-- CreateIndex
CREATE INDEX "pembinaan_ibadahs_tenantId_santriId_idx" ON "pembinaan_ibadahs"("tenantId", "santriId");

-- CreateIndex
CREATE INDEX "pembinaan_ibadahs_tenantId_tanggal_idx" ON "pembinaan_ibadahs"("tenantId", "tanggal");

-- CreateIndex
CREATE INDEX "keadaan_darurats_tenantId_status_idx" ON "keadaan_darurats"("tenantId", "status");

-- CreateIndex
CREATE INDEX "keadaan_darurats_tenantId_tanggal_idx" ON "keadaan_darurats"("tenantId", "tanggal");

-- CreateIndex
CREATE UNIQUE INDEX "user_notif_settings_userId_key" ON "user_notif_settings"("userId");

-- AddForeignKey
ALTER TABLE "tenants" ADD CONSTRAINT "tenants_adminAwalId_fkey" FOREIGN KEY ("adminAwalId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tenant_berkas" ADD CONSTRAINT "tenant_berkas_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "santris" ADD CONSTRAINT "santris_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "santris" ADD CONSTRAINT "santris_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "kelas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "santris" ADD CONSTRAINT "santris_waliId_fkey" FOREIGN KEY ("waliId") REFERENCES "wali_santris"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ustadzs" ADD CONSTRAINT "ustadzs_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kelas" ADD CONSTRAINT "kelas_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kelas" ADD CONSTRAINT "kelas_waliKelasId_fkey" FOREIGN KEY ("waliKelasId") REFERENCES "ustadzs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kelas" ADD CONSTRAINT "kelas_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "tahun_ajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ustadz_mengajar" ADD CONSTRAINT "ustadz_mengajar_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ustadz_mengajar" ADD CONSTRAINT "ustadz_mengajar_ustadzId_fkey" FOREIGN KEY ("ustadzId") REFERENCES "ustadzs"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ustadz_mengajar" ADD CONSTRAINT "ustadz_mengajar_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "kelas"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ustadz_mengajar" ADD CONSTRAINT "ustadz_mengajar_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "mata_pelajarans"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "jurnal_mengajars" ADD CONSTRAINT "jurnal_mengajars_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "jurnal_mengajars" ADD CONSTRAINT "jurnal_mengajars_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "kelas"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "jurnal_mengajars" ADD CONSTRAINT "jurnal_mengajars_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "mata_pelajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wali_santris" ADD CONSTRAINT "wali_santris_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "wali_santris" ADD CONSTRAINT "wali_santris_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "mata_pelajarans" ADD CONSTRAINT "mata_pelajarans_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tahun_ajarans" ADD CONSTRAINT "tahun_ajarans_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "absensis" ADD CONSTRAINT "absensis_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "absensis" ADD CONSTRAINT "absensis_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "mata_pelajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nilais" ADD CONSTRAINT "nilais_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nilais" ADD CONSTRAINT "nilais_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "mata_pelajarans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nilais" ADD CONSTRAINT "nilais_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "tahun_ajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "capaian_tahfidzs" ADD CONSTRAINT "capaian_tahfidzs_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pelanggarans" ADD CONSTRAINT "pelanggarans_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "perizinan" ADD CONSTRAINT "perizinan_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kesehatan_logs" ADD CONSTRAINT "kesehatan_logs_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kunjungan_walis" ADD CONSTRAINT "kunjungan_walis_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kunjungan_walis" ADD CONSTRAINT "kunjungan_walis_waliId_fkey" FOREIGN KEY ("waliId") REFERENCES "wali_santris"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifikasis" ADD CONSTRAINT "notifikasis_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "tata_tertibs" ADD CONSTRAINT "tata_tertibs_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pendaftarans" ADD CONSTRAINT "pendaftarans_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "placement_tests" ADD CONSTRAINT "placement_tests_pendaftaranId_fkey" FOREIGN KEY ("pendaftaranId") REFERENCES "pendaftarans"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "placement_tests" ADD CONSTRAINT "placement_tests_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "mata_pelajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kurikulums" ADD CONSTRAINT "kurikulums_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kurikulums" ADD CONSTRAINT "kurikulums_tahunAjaranId_fkey" FOREIGN KEY ("tahunAjaranId") REFERENCES "tahun_ajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "silabus" ADD CONSTRAINT "silabus_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "silabus" ADD CONSTRAINT "silabus_kurikulumId_fkey" FOREIGN KEY ("kurikulumId") REFERENCES "kurikulums"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "silabus" ADD CONSTRAINT "silabus_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "mata_pelajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rpps" ADD CONSTRAINT "rpps_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rpps" ADD CONSTRAINT "rpps_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "mata_pelajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rekam_medis" ADD CONSTRAINT "rekam_medis_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rekam_medis" ADD CONSTRAINT "rekam_medis_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "subscriptions" ADD CONSTRAINT "subscriptions_paketId_fkey" FOREIGN KEY ("paketId") REFERENCES "pakets"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "invoices" ADD CONSTRAINT "invoices_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ujians" ADD CONSTRAINT "ujians_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ujians" ADD CONSTRAINT "ujians_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "mata_pelajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ujians" ADD CONSTRAINT "ujians_kelasId_fkey" FOREIGN KEY ("kelasId") REFERENCES "kelas"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nilai_ujians" ADD CONSTRAINT "nilai_ujians_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nilai_ujians" ADD CONSTRAINT "nilai_ujians_ujianId_fkey" FOREIGN KEY ("ujianId") REFERENCES "ujians"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "nilai_ujians" ADD CONSTRAINT "nilai_ujians_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "remedials" ADD CONSTRAINT "remedials_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "remedials" ADD CONSTRAINT "remedials_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "remedials" ADD CONSTRAINT "remedials_ujianId_fkey" FOREIGN KEY ("ujianId") REFERENCES "ujians"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "remedials" ADD CONSTRAINT "remedials_mapelId_fkey" FOREIGN KEY ("mapelId") REFERENCES "mata_pelajarans"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rapors" ADD CONSTRAINT "rapors_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rapors" ADD CONSTRAINT "rapors_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kelulusans" ADD CONSTRAINT "kelulusans_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "kelulusans" ADD CONSTRAINT "kelulusans_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "konselings" ADD CONSTRAINT "konselings_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "konselings" ADD CONSTRAINT "konselings_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "konselings" ADD CONSTRAINT "konselings_konselorId_fkey" FOREIGN KEY ("konselorId") REFERENCES "ustadzs"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "konselings" ADD CONSTRAINT "konselings_createdById_fkey" FOREIGN KEY ("createdById") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pembinaan_karakters" ADD CONSTRAINT "pembinaan_karakters_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pembinaan_karakters" ADD CONSTRAINT "pembinaan_karakters_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pembinaan_ibadahs" ADD CONSTRAINT "pembinaan_ibadahs_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "pembinaan_ibadahs" ADD CONSTRAINT "pembinaan_ibadahs_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "keadaan_darurats" ADD CONSTRAINT "keadaan_darurats_tenantId_fkey" FOREIGN KEY ("tenantId") REFERENCES "tenants"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "keadaan_darurats" ADD CONSTRAINT "keadaan_darurats_santriId_fkey" FOREIGN KEY ("santriId") REFERENCES "santris"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "user_notif_settings" ADD CONSTRAINT "user_notif_settings_userId_fkey" FOREIGN KEY ("userId") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;
