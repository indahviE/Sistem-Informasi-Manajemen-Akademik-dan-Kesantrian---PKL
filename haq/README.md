# SIM Akademik & Kesantrian — Ma'had Al-Qur'an Wal Lughah

Sistem Informasi Manajemen Akademik & Kesantrian, platform **SaaS multi-tenant** sesuai PRD v0.4.
Client **Flutter** (satu codebase → APK + Web) + **NestJS REST API** + **MySQL** (shared, isolasi via `tenant_id`).

## Struktur
```
backend/   NestJS + Prisma (MySQL). API: /api
mobile/    Flutter (Android + Web)
serve_web.sh  Sajikan Flutter Web hasil build (port 8080)
```

## Menjalankan

### 1. Database (MySQL via Docker / colima)
```bash
docker run -d --name mysql-pesantren \
  -e MYSQL_ROOT_PASSWORD=root123 -e MYSQL_DATABASE=pesantren \
  -e MYSQL_USER=pesantren -e MYSQL_PASSWORD=pesantren123 \
  -p 3306:3306 mysql:8.4 --mysql-native-password=ON
```
> Flag `--mysql-native-password=ON` agar MySQL 8.4 bisa dikonek Sequel Pro/Ace (user `sequel`/`sequel123`).

### 2. Backend
```bash
cd backend
npm install
cp .env.example .env   # lalu isi DATABASE_URL + secret
npm run prisma:generate
npm run prisma:migrate   # migrasi
npm run db:seed          # data demo
npm run start:dev        # API di http://localhost:3000/api
```

### 3. Client Flutter (Web)
```bash
cd mobile
flutter pub get
flutter build web
../serve_web.sh          # http://localhost:8080
```
Untuk APK Android: `flutter run` / `flutter build apk`.

## Cara melihat perubahan di web localhost
| Perubahan | Perintah | Refresh browser |
|---|---|---|
| UI Flutter | `cd mobile && flutter build web --release` | Cmd+Shift+R |
| Backend API | `./restart_backend.sh` (build + restart node) | reload saja |
| Menu/role/menu baru | kedua perintah di atas | Cmd+Shift+R |

- Server web `serve_web.sh` menyajikan `mobile/build/web` (statis) — cukup rebuild, lalu hard-refresh browser.
- Backend berjalan dari `dist/`, jadi perubahan `src/` WAJIB `./restart_backend.sh` (atau `npm run start:dev` untuk auto-reload).
- Port 8080 diambil alih Apache macOS? Hentikan: `brew services stop httpd`, lalu `./serve_web.sh`.

## Akun demo (lihat juga `prisma/seed.ts`)
| Role | Email | Password | Kode Tenant |
|---|---|---|---|
| Super Admin | superadmin@sistempesantren.com | superadmin123 | (kosong) |
| Admin | admin@mahad.id | admin123 | mahad-alquran |
| Ustadz/Guru | ustadz@mahad.id | admin123 | mahad-alquran |
| Musyrif/Pembina | musyrif@mahad.id | admin123 | mahad-alquran |
| Pimpinan/Mudir | mudir@mahad.id | admin123 | mahad-alquran |
| Wali Santri | wali@mahad.id | admin123 | mahad-alquran |

## Fitur Fase 1 yang diimplementasikan
- Landing + **pendaftaran pondok self-service** (`POST /api/tenants/signup`)
- **Super Admin**: kelola/approve/suspend tenant, dashboard platform
- **Auth JWT** (access + refresh), **RBAC** 7 role, **tingkat guard + decorator**
- **Isolasi multi-tenant** otomatis via `tenant_id` di JWT (guard global) + audit log interceptor
- Modul akademik: absensi (single/bulk), nilai (harian/ulangan/tahfidz/bahasa-arab), capaian tahfidz
- Modul kesantrian: pelanggaran (+poin, notifikasi wali), perizinan (approval flow + deteksi telat),
  kesehatan (notifikasi wali), kunjungan wali, tata tertib
- Notifikasi per user; dashboard eksekutif per role; CRUD santri/ustadz/kelas/mapel/tahun-ajaran/wali/user

## Endpoint utama
`/api/auth/login` • `/api/dashboard` • `/api/tenants/*` • `/api/santri` • `/api/ustadz`
`/api/kelas` • `/api/mapel` • `/api/absensi` • `/api/nilai` • `/api/tahfidz`
`/api/pelanggaran` • `/api/perizinan` • `/api/kesehatan` • `/api/kunjungan`
`/api/tata-tertib` • `/api/notifikasi` • `/api/users` • `/api/wali/*`