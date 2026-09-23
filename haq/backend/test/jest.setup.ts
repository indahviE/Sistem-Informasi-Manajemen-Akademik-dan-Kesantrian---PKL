// test/jest.setup.ts
//
// Dijalankan sekali sebelum semua e2e test. Tujuannya cuma satu: pastikan
// DATABASE_URL yang dipakai test BUKAN database development kamu — test ini
// membuat tenant dummy dan MENGHAPUSNYA lagi di akhir, jadi kalau salah
// nunjuk ke database dev, datanya bisa ikut ke-utak-atik atau terhapus.
//
// Cara pakai:
//   1. Buat database MySQL kosong khusus test, mis. `pesantren_test`.
//   2. Copy .env -> .env.test, ganti DATABASE_URL ke database itu.
//   3. `npx prisma migrate deploy` dengan DATABASE_URL menunjuk ke database
//      test itu (sekali saja, supaya schema-nya tersedia).
//   4. `npm run test:e2e`

import { config } from 'dotenv';
import { existsSync } from 'fs';
import { resolve } from 'path';

const envTestPath = resolve(__dirname, '../.env.test');

if (existsSync(envTestPath)) {
  config({ path: envTestPath, override: true });
} else {
  config(); // fallback ke .env biasa
  // eslint-disable-next-line no-console
  console.warn(
    '\n⚠️  .env.test tidak ditemukan — memakai .env biasa untuk test isolasi tenant.\n' +
      '   Test ini membuat & menghapus data tenant dummy. Sangat disarankan\n' +
      '   pakai database TEST terpisah, bukan database development kamu.\n' +
      '   Buat .env.test dengan DATABASE_URL yang berbeda untuk mematikan warning ini.\n',
  );
}

if (!/test/i.test(process.env.DATABASE_URL ?? '')) {
  // eslint-disable-next-line no-console
  console.warn(
    `\n⚠️  DATABASE_URL saat ini ("${process.env.DATABASE_URL}") sepertinya bukan\n` +
      '   database test (namanya tidak mengandung kata "test"). Lanjut dengan\n' +
      '   risiko sendiri — batalkan (Ctrl+C) kalau ini database development.\n',
  );
}