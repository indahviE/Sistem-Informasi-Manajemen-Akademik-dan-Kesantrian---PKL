// fix_dashboard.js
//
// Cara pakai (dari folder C:\Sekolah\haq\mobile):
//     node fix_dashboard.js
//
// Yang dilakukan (HANYA di lib/screens/dashboard_screen.dart):
//   Tiga bagian milik Admin Lembaga dipindah dari warna hijau tetap (_WC)
//   ke warna tema pondok (_TC -> SC):
//     1. _heroHeader      (kartu sapaan di atas)
//     2. _tenantBody      (semua kartu admin: master data, audit, akademik, log)
//     3. _QuickAction     (kartu "Tindakan Data Master")
//   Lalu kata `const` yang jadi error (karena sekarang berisi getter) dihapus
//   hanya di tiga bagian itu. Wali, Ustadz, dan Super Admin TIDAK disentuh.
//
// Aman dijalankan berulang kali. File asli dibackup sekali jadi
// dashboard_screen.dart.bak-tema

const fs = require('fs');
const path = require('path');

const FILE = path.join(process.cwd(), 'lib', 'screens', 'dashboard_screen.dart');

if (!fs.existsSync(FILE)) {
  console.log('GAGAL: file tidak ditemukan: ' + FILE);
  console.log('Pastikan kamu menjalankan perintah ini dari folder C:\\Sekolah\\haq\\mobile');
  process.exit(1);
}

let src = fs.readFileSync(FILE, 'utf8');
const original = src;

// Pengaman: kelas _TC dan import SC harus sudah ada.
if (!src.includes('class _TC')) {
  console.log('GAGAL: class _TC belum ada di dashboard_screen.dart.');
  process.exit(1);
}
if (!src.includes("santri/santri_ui.dart")) {
  console.log("GAGAL: tambahkan dulu baris  import 'santri/santri_ui.dart';  di bagian import.");
  process.exit(1);
}

// [nama, awal blok, akhir blok (tidak ikut diubah)]
const BLOCKS = [
  ['_heroHeader', 'Widget _heroHeader(String role) {', '// 1b. Hero header for WALI_SANTRI'],
  ['_tenantBody dan kartu admin', 'Widget _tenantBody() {', '// USTADZ / GURU / MUSYRIF'],
  ['_QuickAction', 'class _QuickAction extends StatelessWidget {', '/// Grid 2 kolom'],
];

let adaMasalah = false;

for (const [nama, awal, akhir] of BLOCKS) {
  const a = src.indexOf(awal);
  if (a < 0) {
    console.log('PERINGATAN: awal blok "' + nama + '" tidak ketemu, dilewati.');
    adaMasalah = true;
    continue;
  }
  const b = src.indexOf(akhir, a + awal.length);
  if (b < 0) {
    console.log('PERINGATAN: akhir blok "' + nama + '" tidak ketemu, dilewati.');
    adaMasalah = true;
    continue;
  }

  const lama = src.slice(a, b);
  let baru = lama
    // urutan penting: yang panjang dulu
    .replace(/_WC\.primaryGradientEnd\b/g, '_TC.primaryEnd')
    .replace(/_WC\.primary\b/g, '_TC.primary')
    .replace(/_WC\.mint\b/g, '_TC.mint')
    .replace(/_WC\.sage\b/g, '_TC.sage');

  const jumlahWarna = (lama.match(/_WC\.(primaryGradientEnd|primary|mint|sage)\b/g) || []).length;

  // Hapus `const` di depan widget/list (huruf besar, _ , [ atau <).
  // `const` di depan nama variabel huruf kecil tidak disentuh.
  const jumlahConst = (baru.match(/\bconst\s+(?=[A-Z_\[<])/g) || []).length;
  baru = baru.replace(/\bconst\s+(?=[A-Z_\[<])/g, '');

  src = src.slice(0, a) + baru + src.slice(b);
  console.log('OK  ' + nama + ': ' + jumlahWarna + ' warna dipindah, ' + jumlahConst + ' const dihapus');
}

if (src === original) {
  console.log('\nTidak ada yang berubah (mungkin sudah pernah dijalankan).');
  process.exit(adaMasalah ? 1 : 0);
}

const bak = FILE + '.bak-tema';
if (!fs.existsSync(bak)) fs.copyFileSync(FILE, bak);
fs.writeFileSync(FILE, src, 'utf8');

console.log('\nSelesai. Backup: dashboard_screen.dart.bak-tema');
console.log('Langkah berikutnya: Hot Restart, lalu cek tab Problems.');