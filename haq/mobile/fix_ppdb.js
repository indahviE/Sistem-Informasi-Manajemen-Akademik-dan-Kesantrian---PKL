// fix_ppdb.js  ->  node fix_ppdb.js
// (opsional) node fix_ppdb.js lib/screens/ppdb/ppdb_list_screen.dart
const fs = require('fs');
const path = require('path');

function cari(dir, nama) {
  for (const e of fs.readdirSync(dir, { withFileTypes: true })) {
    const p = path.join(dir, e.name);
    if (e.isDirectory()) {
      const r = cari(p, nama);
      if (r) return r;
    } else if (e.name === nama) return p;
  }
  return null;
}

const LIB = path.join(process.cwd(), 'lib');
if (!fs.existsSync(LIB)) {
  console.log('GAGAL: jalankan dari folder C:\\Sekolah\\haq\\mobile');
  process.exit(1);
}

const FILE = process.argv[2]
  ? path.resolve(process.argv[2])
  : cari(LIB, 'ppdb_list_screen.dart');
const SCUI = cari(LIB, 'santri_ui.dart');

if (!FILE || !fs.existsSync(FILE)) { console.log('GAGAL: ppdb_list_screen.dart tidak ketemu.'); process.exit(1); }
if (!SCUI) { console.log('GAGAL: santri_ui.dart tidak ketemu.'); process.exit(1); }

let src = fs.readFileSync(FILE, 'utf8');
const original = src;

// 1. Ganti warna
let jumlahWarna = 0;
const ganti = (re, to) => {
  src = src.replace(re, () => { jumlahWarna++; return to; });
};
ganti(/PColors\.primaryGradientEnd\b/g, 'SC.primaryEnd');
ganti(/PColors\.primary\b/g, 'SC.primary');
ganti(/PColors\.sage\b/g, 'SC.sage');
ganti(/PColors\.mint\b/g, 'SC.mint');
ganti(/Color\(0x1A0F3A2E\)/g, 'SC.primary.withOpacity(0.10)');
ganti(/Color\(0x0A0F3A2E\)/g, 'SC.primary.withOpacity(0.04)');

// 2. Hapus `const` yang jadi error (aman: lewati static const & deklarasi level class)
let jumlahConst = 0;
src = src.replace(/\bconst\s+(?=[A-Z_\[<])/g, (m, offset, str) => {
  const lineStart = str.lastIndexOf('\n', offset - 1) + 1;
  const prefix = str.slice(lineStart, offset);
  if (/static\s+$/.test(prefix)) return m;      // static const ...
  if (/^\s{0,2}$/.test(prefix)) return m;       // konstruktor / const level class
  jumlahConst++;
  return '';
});

// 3. Tambah import SC kalau belum ada
if (!/santri_ui\.dart/.test(src)) {
  let rel = path.relative(path.dirname(FILE), SCUI).split(path.sep).join('/');
  if (!rel.startsWith('.')) rel = './' + rel;
  const imp = "import '" + rel + "' show SC;";
  const anchor = /import '\.\.\/signup_screen\.dart';[^\n]*\n/;
  src = anchor.test(src)
    ? src.replace(anchor, (a) => a + imp + '\n')
    : imp + '\n' + src;
}

if (src === original) {
  console.log('Tidak ada yang berubah (mungkin sudah pernah dijalankan).');
  process.exit(0);
}

const bak = FILE + '.bak-ppdb';
if (!fs.existsSync(bak)) fs.copyFileSync(FILE, bak);
fs.writeFileSync(FILE, src, 'utf8');

console.log('OK: ' + FILE);
console.log(jumlahWarna + ' warna dipindah, ' + jumlahConst + ' const dihapus');
console.log('Backup: ' + bak);
console.log('Langkah berikutnya: Hot Restart, lalu cek tab Problems.');