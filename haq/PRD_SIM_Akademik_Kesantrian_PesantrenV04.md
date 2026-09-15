# PRD — Sistem Informasi Manajemen Akademik & Kesantrian
## Ma'had Al-Qur'an Wal Lughah

**Versi:** 0.4 (Draft)
**Fokus Fase 1:** Modul Akademik + Modul Kesantrian, sebagai **platform SaaS multi-tenant**
**Platform:** Flutter (APK + Web, satu codebase) + REST API Backend (Node.js/NestJS) + Database (MySQL, shared dengan ``)

---

## 1. Latar Belakang & Tujuan

Ma'had Al-Qur'an Wal Lughah tengah mengimplementasikan ISO 21001:2018 (Educational Organizations Management System) dengan total ±115 dokumen, SOP, dan formulir di 8 kategori. Saat ini proses administrasi akademik dan kesantrian kemungkinan masih berbasis dokumen manual/kertas atau spreadsheet terpisah, sehingga:

- Sulit memantau data santri secara real-time (nilai, kehadiran, pelanggaran, kesehatan)
- Pelaporan ke wali santri lambat dan tidak terstandardisasi
- Proses tinjauan manajemen dan audit internal ISO 21001 (klausul 9-10) memerlukan waktu lama karena data tersebar
- Sulit menghasilkan bukti kepatuhan (records) untuk audit sertifikasi

**Tujuan sistem ini:**
1. Mendigitalisasi prosetenant_ids inti akademik dan kesantrian sesuai SOP yang sudah ada
2. Menyediakan data terpusat yang bisa diakses sesuai peran (role-based)
3. Mempermudah pelaporan ke wali santri dan pimpinan
4. Menjadi bukti dokumentasi (records) yang mendukung kepatuhan ISO 21001:2018
5. **Dibangun sebagai platform SaaS multi-tenant** — awalnya dipakai Ma'had Al-Qur'an Wal Lughah sendiri, tapi sejak awal didesain agar pondok/pesantren lain juga bisa mendaftar dan pakai sistem yang sama secara terisolasi (data tidak tercampur antar pondok)

---

## 2. User Roles

| Role | Deskripsi | Akses Utama |
|---|---|---|
| **Super Admin** (level platform) | Pengelola platform SaaS (tim developer/kamu) | Kelola daftar tenant/pondok, approve pendaftaran, monitor seluruh tenant, tidak akses data akademik/kesantrian tiap pondok |
| **Admin** (level tenant) | Staf tata usaha/operator sistem per pondok | Kelola data master (santri, ustadz, kelas), input data akademik & kesantrian, kelola user — hanya di lingkup pondoknya sendiri |
| **Ustadz/Guru** | Pengajar mata pelajaran/halaqah | Input nilai, absensi, jurnal mengajar, catatan pembinaan |
| **Musyrif/Pembina Asrama** | Pembina kesantrian/asrama | Input pelanggaran, perizinan, kesehatan, catatan pembinaan karakter |
| **Wali Santri** | Orang tua/wali | Lihat nilai, kehadiran, pelanggaran, perizinan, kesehatan anaknya (read-only) |
| **Santri** | Peserta didik | Lihat jadwal, nilai, pengumuman (read-only, opsional untuk MVP) |
| **Pimpinan/Mudir** (level tenant) | Pengambil keputusan di pondoknya | Dashboard eksekutif — ringkasan lintas modul, laporan, tren, hanya untuk pondoknya sendiri |

> **Catatan akses:** Semua role bisa memilih akses via **APK (mobile)** atau **Web (browser)** — keduanya dari satu codebase Flutter yang sama, dengan fitur setara. Tujuannya fleksibilitas: sebagian tugas lebih nyaman di mobile (input cepat di lapangan), sebagian lebih nyaman di web (input massal, lihat laporan di layar besar).

---

## 3. Ruang Lingkup (Scope)

### 3.1 Fase 1 — MVP (Dashboard Dasar + Fitur Inti Ringan + Fondasi Multi-Tenant)

Kombinasi ringan lintas modul, prioritas pada **visibilitas data**, bukan seluruh workflow SOP:

- **Landing page + pendaftaran tenant (pondok baru) self-service** — form daftar pondok baru, generate tenant otomatis
- **Dashboard Super Admin** — daftar tenant, status (aktif/pending), jumlah user per tenant
- **Dashboard per role** (ringkasan angka: jumlah santri, kehadiran hari ini, pelanggaran minggu ini, dsb) — data terisolasi per tenant
- **Data master**: santri, ustadz/pembina, kelas/halaqah, tahun ajaran — semua terikat ke `tenant_id`
- **Akademik ringan**: input & lihat nilai per mapel, absensi harian
- **Kesantrian ringan**: catat pelanggaran, catat perizinan keluar/pulang, catat kunjungan wali
- **Notifikasi dasar** ke wali santri (misal: santri sakit, pelanggaran, izin disetujui)

### 3.2 Fase 2 (Belum digarap, dicatat sebagai referensi roadmap)

- PPDB online, placement test digital
- Kurikulum, silabus, RPP terstruktur
- Ujian online, remedial, rapor digital, kelulusan/wisuda tahfidz
- Modul kesehatan santri (rekam medis ringan, UKS)
- Modul konseling (dengan pertimbangan privasi khusus)
- **Billing & subscription** — paket harga, limit santri per paket, invoice, payment gateway
- Branding kustom per tenant (logo, nama, warna tema)

### 3.3 Di Luar Scope Fase 1 & 2

- Modul SDM, Keuangan, Sarana, Stakeholder (dari 8 kategori infografis — dikerjakan terpisah/menyusul)

---

## 4. Modul Akademik — Breakdown Fitur

Berdasarkan 12 SOP akademik di dokumen ISO, berikut pemetaan ke fitur (✅ = Fase 1, 🔜 = Fase 2):

| SOP | Fitur Sistem | Fase |
|---|---|---|
| Penerimaan Santri Baru | Form pendaftaran online, tracking status | 🔜 |
| Placement Test | Input & lihat hasil tes penempatan | 🔜 |
| Penyusunan Kurikulum | Manajemen struktur kurikulum | 🔜 |
| Penyusunan Silabus | Upload/kelola silabus per mapel | 🔜 |
| Penyusunan RPP | Upload/kelola RPP per pertemuan | 🔜 |
| Kegiatan Pembelajaran | **Absensi harian per kelas/mapel** | ✅ |
| Pembelajaran Tahfidz | **Input capaian hafalan (juz/halaman)** | ✅ |
| Pembelajaran Bahasa Arab | **Input nilai per skill (muhadatsah, dll)** | ✅ |
| Evaluasi Pembelajaran | **Input nilai ulangan/tugas** | ✅ |
| Ujian | Jadwal ujian, input nilai ujian | 🔜 |
| Remedial | Pencatatan santri remedial & hasil | 🔜 |
| Kelulusan & Wisuda Tahfidz | Rekap kelulusan, sertifikat | 🔜 |

---

## 5. Modul Kesantrian — Breakdown Fitur

| SOP | Fitur Sistem | Fase |
|---|---|---|
| Pembinaan Karakter | Catatan pembinaan (naratif per santri) | 🔜 |
| Tata Tertib Santri | Referensi tata tertib (statis/PDF) | ✅ (statis) |
| Perizinan Santri | **Form izin keluar/pulang + approval flow** | ✅ |
| Penanganan Pelanggaran | **Input pelanggaran + poin + tindak lanjut** | ✅ |
| Pembinaan Ibadah | Rekap kehadiran ibadah (jamaah, dll) | 🔜 |
| Konseling Santri | Catatan konseling (akses terbatas/rahasia) | 🔜 |
| Kesehatan Santri | **Catat sakit/berobat + notifikasi wali** | ✅ (ringan) |
| Kunjungan Wali Santri | **Log kunjungan wali** | ✅ |
| Kepulangan Santri | Terhubung dengan modul perizinan | ✅ |
| Penanganan Keadaan Darurat | Form pelaporan darurat + notifikasi cepat | 🔜 |

---

## 6. Entitas Data Utama (Draft Data Model)

> **Catatan multi-tenant:** Semua entitas di bawah (kecuali `Tenant` sendiri) memiliki kolom `tenant_id` yang wajib diisi dan menjadi filter otomatis di setiap query backend — ini fondasi isolasi data antar pondok.

```
Tenant  ⭐ BARU
- id, nama_pondok, kode_tenant (slug unik), logo_url, status (pending/aktif/suspended),
  admin_awal_id, tanggal_daftar

User (akun login — semua role kecuali Super Admin terikat ke 1 tenant)
- id, tenant_id, nama, email, password_hash, role, status

Santri
- id, tenant_id, nis, nama, jenis_kelamin, tanggal_lahir, kelas_id, asrama_id,
  wali_id, status (aktif/lulus/keluar), tahun_masuk

Ustadz / Pembina
- id, tenant_id, nama, jenis (guru/musyrif), mapel_diampu, kelas_diampu

Kelas / Halaqah
- id, tenant_id, nama_kelas, tingkat, wali_kelas_id, tahun_ajaran

WaliSantri
- id, tenant_id, nama, no_hp, email, hubungan (ayah/ibu/wali), santri_id (relasi)

Absensi
- id, tenant_id, santri_id, kelas_id, mapel_id, tanggal, status (hadir/izin/sakit/alpa)

Nilai
- id, tenant_id, santri_id, mapel_id, jenis (harian/ulangan/tahfidz), nilai, tanggal

CapaianTahfidz
- id, tenant_id, santri_id, juz, halaman, tanggal_setor, catatan_ustadz

Pelanggaran
- id, tenant_id, santri_id, jenis_pelanggaran, poin, tanggal, pelapor_id, tindak_lanjut, status

Perizinan
- id, tenant_id, santri_id, jenis (pulang/keluar), tanggal_keluar, tanggal_kembali,
  alasan, status_approval, disetujui_oleh

KesehatanLog
- id, tenant_id, santri_id, keluhan, tindakan, tanggal, status (rawat_jalan/dirujuk/sembuh)

KunjunganWali
- id, tenant_id, santri_id, wali_id, tanggal, catatan

Notifikasi
- id, tenant_id, user_id, jenis, pesan, status_baca, tanggal
```

---

## 7. Alur Kerja Kunci (User Flow — Fase 1)

**Flow: Pendaftaran Pondok Baru (Tenant Onboarding)** ⭐ BARU
1. Pengelola pondok baru mengisi form pendaftaran di landing page (nama pondok, data admin awal, dan **memilih `kode_tenant`/slug sendiri** — misal "mahad-alquran" — divalidasi unik & URL-safe)
2. Sistem generate `tenant_id`, simpan `kode_tenant` (nanti jadi subdomain: `mahad-alquran.sistempesantren.com`), status awal "pending"
3. Super Admin review & approve pendaftaran (atau auto-approve — lihat pertanyaan terbuka)
4. Setelah aktif, admin awal pondok tsb menerima kredensial login dan bisa mulai setup data master (kelas, ustadz, dst) — bisa akses lewat subdomain webnya sendiri atau APK dengan input kode_tenant
5. Login berikutnya: **Web** otomatis kenal tenant dari subdomain yang diakses; **APK** user input `kode_tenant` + email/password — sistem otomatis scope semua data ke `tenant_id` yang sesuai

**Flow: Pelanggaran Santri**
1. Musyrif mencatat pelanggaran santri di aplikasi → pilih jenis pelanggaran (dari master data) → poin otomatis terhitung
2. Sistem kirim notifikasi ke Wali Santri
3. Admin/Pimpinan bisa lihat rekap pelanggaran per santri/kelas di dashboard

**Flow: Perizinan**
1. Musyrif/Admin input pengajuan izin santri (atau wali santri request via app — opsional)
2. Status: Diajukan → Disetujui/Ditolak (oleh Musyrif/Admin)
3. Saat santri kembali, status diupdate "Kembali" — jika telat, sistem flag otomatis
4. Notifikasi ke wali santri di setiap perubahan status

**Flow: Input Nilai/Absensi**
1. Ustadz pilih kelas & mapel → sistem tampilkan daftar santri
2. Ustadz input nilai/kehadiran per santri → simpan
3. Wali santri & santri (read-only) bisa lihat riwayat

---

## 8. Non-Functional Requirements

- **Keamanan data**: Data santri adalah data anak (sebagian di bawah umur) — wajib role-based access control ketat, enkripsi data sensitif (kesehatan, pelanggaran), audit log setiap perubahan data
- **Isolasi data antar tenant** ⭐ BARU: setiap query database WAJIB difilter `tenant_id` di level backend (bukan mengandalkan client) — kebocoran data antar pondok adalah risiko kritis, perlu automated testing khusus untuk memastikan tidak ada tenant yang bisa akses data tenant lain
- **Konektivitas**: Sinyal di lingkungan pondok dikonfirmasi stabil — sistem didesain **online-only** (langsung hit API), tanpa local storage/offline mode. APK dan Web murni pilihan kenyamanan akses, bukan solusi offline.
- **Performa**: Response API < 2 detik untuk operasi umum
- **Skalabilitas**: Desain database mendukung multi-tahun ajaran (histori tidak overwrite)
- **Kepatuhan ISO 21001**: Setiap input data harus bisa ditelusuri (siapa input, kapan) — mendukung audit trail untuk klausul 9 (evaluasi kinerja)
- **Bahasa**: UI Bahasa Indonesia (opsional: dukungan istilah Arab untuk beberapa field seperti nama mapel)

---

## 9. Arsitektur Teknis (Final — Disepakati)

**Keputusan:** Single codebase Flutter (build ke APK + Web) sebagai client, mengakses satu REST API (Node.js/NestJS), online-only, database MySQL **shared dengan isolasi via `tenant_id`**. Self-hosted di VPS.

```
[Flutter → APK]  ──┐
                    ├──▶  [NestJS REST API]  ──▶  [MySQL (shared, tenant_id)]
[Flutter → Web]  ──┘        (JWT Auth + tenant_id,
                              RBAC Guards,
                              Tenant Isolation Middleware,
                              Audit Log Interceptor)
```

- **Client (Flutter)**: satu codebase untuk APK dan Web. Semua role bebas pilih akses lewat mana saja — tidak ada pembedaan fitur antara APK dan Web.
- **Identifikasi tenant saat login** ⭐ BARU — dua jalur, satu identifier (`kode_tenant`/slug):
  - **Web**: otomatis dari subdomain (`{kode_tenant}.sistempesantren.com`) — backend baca `Host` header untuk resolve tenant, user tidak perlu input apa pun soal tenant
  - **APK**: user input `kode_tenant` manual di layar login (tidak ada konsep subdomain di aplikasi native)
  - Setelah login sukses (jalur mana pun), `tenant_id` tersimpan di JWT — request berikutnya seragam, tidak perlu identifikasi ulang
  - Butuh infrastruktur tambahan: **wildcard DNS** (`*.sistempesantren.com`) + **wildcard SSL certificate** (Let's Encrypt DNS challenge)
- **Tanpa local storage/SQLite**: semua operasi baca/tulis langsung ke API (online-only), karena konektivitas di lingkungan pondok sudah dikonfirmasi stabil.
- **Backend (NestJS)**: satu API melayani APK dan Web sekaligus, sekarang juga melayani multi-tenant:
  - **Autentikasi**: JWT (access token + refresh token), payload token menyertakan `tenant_id` dan `role`
  - **Tenant Isolation Middleware** ⭐ BARU: setiap request (kecuali Super Admin) otomatis di-scope ke `tenant_id` dari token — dipasang di level global (guard/interceptor), bukan diulang manual tiap endpoint, supaya tidak ada celah lupa filter
  - **RBAC**: NestJS Guards + Decorators per role (Super Admin, Admin, Ustadz, Musyrif, Wali Santri, Santri, Pimpinan/Mudir)
  - **Audit log**: Interceptor otomatis mencatat siapa mengubah data apa & kapan (termasuk `tenant_id`) — mendukung klausul 9 ISO 21001 per tenant
  - **ORM**: Prisma (type-safe, migrasi schema mudah, cocok untuk MySQL, mendukung query scoping tenant dengan middleware Prisma)
- **Database (MySQL)**: satu database, satu-satunya source of truth untuk semua tenant, hanya diakses lewat backend API. Index composite pada `tenant_id` + kolom yang sering di-query (misal `tenant_id + kelas_id`) penting untuk performa di skala banyak tenant.
- **Hosting (Self-hosted VPS)**:
  - **Wildcard DNS** (`*.sistempesantren.com` → IP VPS) + **wildcard SSL certificate** (Let's Encrypt via DNS challenge) — fondasi untuk subdomain per tenant
  - Nginx sebagai reverse proxy (routing berdasarkan subdomain ke tenant yang tepat + routing API + Flutter Web, SSL/TLS)
  - PM2 atau Docker untuk process management backend
  - **Backup MySQL terjadwal (wajib)** — krusial mengingat ini data anak & bukti kepatuhan audit ISO dari banyak pondok sekaligus
  - Rencanakan firewall/hardening dasar VPS (akses SSH terbatas, MySQL tidak expose ke publik)
  - Perlu monitoring resource VPS lebih ketat karena beban bertambah seiring jumlah tenant bertambah

---

## 10. Roadmap Fase (Ringkas)

| Fase | Fokus | Estimasi Lingkup |
|---|---|---|
| Fase 1 (MVP) | Dashboard + Akademik & Kesantrian ringan + fondasi multi-tenant (signup, isolasi data) | ~4 modul inti, 7 role (termasuk Super Admin) |
| Fase 2 | PPDB, Kurikulum, Ujian, Rapor, Kesehatan penuh, Konseling, **Billing & Subscription**, branding kustom per tenant | Menyusul |
| Fase 3 | Modul SDM, Keuangan, Sarana, Stakeholder | Menyusul (di luar scope dokumen ini) |

---

## 11. Pertanyaan Terbuka

**Sudah terjawab:**
1. ✅ Wali santri perlu login (APK atau Web)
2. ✅ Skala: **2000+ santri** (untuk tenant pertama) — perlu diperhitungkan di desain database (indexing, pagination di API)
3. ✅ Tidak ada sistem lama — tidak perlu proses migrasi data
4. ✅ Sistem poin pelanggaran **sudah ada di pondok** — perlu sesi terpisah untuk dokumentasikan skema poin existing ini ke dalam struktur data `Pelanggaran` (lihat bagian 6)
5. ✅ Arsitektur final: Flutter (APK + Web, satu codebase) → NestJS REST API → MySQL, online-only, self-hosted VPS (lihat bagian 9)
6. ✅ Sinyal di pondok stabil — tidak perlu offline mode; APK/Web murni pilihan kenyamanan, bukan solusi konektivitas
7. ✅ Sistem dibangun sebagai **SaaS multi-tenant** sejak awal
8. ✅ Strategi isolasi data: **shared database + `tenant_id`**
9. ✅ Onboarding tenant baru: **self-service signup** lewat landing page
10. ✅ Billing/subscription: **belum masuk Fase 1**, menyusul Fase 2
11. ✅ Identifikasi tenant: **keduanya dipakai** — subdomain otomatis untuk Web, `kode_tenant` manual untuk APK, satu identifier yang sama

**Masih perlu divalidasi:**
1. Skema poin pelanggaran existing — perlu didokumentasikan detail (kategori, bobot poin, ambang batas sanksi) untuk masuk ke data model
2. Spesifikasi VPS (RAM/CPU/storage) — perlu disesuaikan dengan estimasi beban multi-tenant + 2000+ santri di tenant pertama
3. Kebijakan retensi data & backup MySQL — seberapa sering backup, disimpan di mana, berapa lama retensi
4. Detail hak akses per role di setiap fitur (matriks permission) — perlu dirinci sebelum implementasi Guards di NestJS
5. **Approval tenant baru** — setelah signup, apakah langsung aktif otomatis, atau perlu direview manual oleh Super Admin dulu sebelum bisa dipakai?
6. **Batasan tenant "pending"** — kalau ada masa tunggu approval, apa saja yang bisa/tidak bisa dilakukan admin awal selama status pending?
7. **Domain utama platform** — belum ditentukan. Tidak blocking untuk development awal (bisa pakai domain placeholder/local), tapi wajib difinalisasi sebelum setup wildcard DNS & SSL menjelang go-live

---

*Dokumen ini adalah draft (v0.4) dan akan diperbarui seiring diskusi lebih lanjut.*
