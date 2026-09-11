# SIM Pesantren — Catatan untuk Agent

## Menjalankan / restart
- Backend berjalan dari `dist/` (bukan `start:dev`). Ganti kode di `src/` → WAJIB `./restart_backend.sh` (di repo root) yang build + restart node. Cek log: `/tmp/backend.log`.
- Web disajikan dari `mobile/build/web` via `./serve_web.sh` (python http.server, port 8080). Perubahan Flutter → `cd mobile && flutter build web --release`, lalu user hard-refresh browser.
- Port 8080 bisa diambil alih Apache macOS → `brew services stop httpd` lalu jalankan `./serve_web.sh` lagi.
- MySQL: container `mysql-pesantren` (mysql:8.4, port 3306). Kredensial di `backend/.env`: `pesantren/pesantren123@localhost:3306/pesantren`. Root: `root123`. User ekstra untuk Sequel Pro/Ace: `sequel/sequel123` (mysql_native_password, container sudah dijalankan dengan `--mysql-native-password=ON`).

## Verifikasi setelah perubahan
- Backend: `curl -s -o /dev/null -w "%{http_code}" "http://localhost:3000/api/tenants/branding?kodeTenant=mahad-alquran"` → 200.
- Web: `curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/` → 200; pastikan bukan halaman "It works!" Apache.
- Flutter: `flutter analyze` harus 0 error sebelum build.

## Akun demo
- Super Admin: `superadmin@sistempesantren.com` / `superadmin123` (tanpa kode tenant)
- Tenant mahad-alquran: admin/ustadz/musyrif/mudir/wali@mahad.id, password `admin123`

## API pattern
- Routes dibawah prefix `/api`; RBAC via `@Roles(...)`; isolasi tenant otomatis dari JWT (`tenant_id`).
- Endpoint baru (Fase 2): `/api/ppdb/*`, `/api/kurikulum`, `/api/silabus`, `/api/rpp`, `/api/rekam-medis/:santriId`, `/api/paket`, `/api/subscriptions`, `/api/invoices`, `/api/tenants/branding`.
- `POST /api/ppdb/daftar` bersifat `@Public` (form pendaftaran santri). Saat status jadi `DITERIMA`, santri dibuat otomatis + NIS.
