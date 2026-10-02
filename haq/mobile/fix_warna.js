// fix_warna.js
//
// Cara pakai (dari folder C:\Sekolah\haq\mobile):
//     node fix_warna.js
//
// Yang dilakukan skrip ini (hanya 5 file Admin Lembaga):
//   1. Palet emerald (primary / primaryEnd / mint / sage) -> getter ke SC (ikut tema pondok)
//   2. Menambah import santri_ui.dart kalau belum ada
//   3. Menghapus kata `const` yang jadi error karena sekarang berisi getter
//   4. dashboard_screen.dart: pakai _TC hanya di bagian admin (hero, tenant body, QuickAction)
//
// Aman dijalankan berulang kali. Tiap file dibackup dulu jadi <nama>.bak.

const fs = require('fs');
const path = require('path');

const ROOT = process.cwd();

// ---------------------------------------------------------------------------
// Utilitas
// ---------------------------------------------------------------------------

/** Cari kurung penutup yang cocok dengan kurung pembuka di indeks `open`. */
function findClose(s, open) {
  const closers = { '(': ')', '[': ']', '{': '}' };
  const stack = [];
  for (let i = open; i < s.length; i++) {
    const c = s[i];
    if (c === '/' && s[i + 1] === '/') {
      while (i < s.length && s[i] !== '\n') i++;
      continue;
    }
    if (c === '/' && s[i + 1] === '*') {
      const e = s.indexOf('*/', i + 2);
      if (e < 0) return -1;
      i = e + 1;
      continue;
    }
    if (c === '"' || c === "'") {
      if (s.startsWith(c + c + c, i)) {
        const e = s.indexOf(c + c + c, i + 3);
        if (e < 0) return -1;
        i = e + 2;
        continue;
      }
      let j = i + 1;
      while (j < s.length && s[j] !== c) {
        if (s[j] === '\\') j++;
        j++;
      }
      i = j;
      continue;
    }
    if (closers[c]) {
      stack.push(closers[c]);
    } else if (c === ')' || c === ']' || c === '}') {
      if (stack.pop() !== c) return -1;
      if (stack.length === 0) return i;
    }
  }
  return -1;
}

/**
 * Hapus `const` pada ekspresi `const Foo(...)` / `const [...]` yang isinya
 * memakai warna dinamis (cocok dengan refRe). Bekerja lintas baris.
 * Mengembalikan { text, count }.
 */
function removeConstWithRefs(src, refRe) {
  const startRe = /\bconst\s+(?=(?:[A-Za-z_][\w.]*(?:<[\w\s,<>?]*>)?\s*\(|\[))/g;
  const ranges = [];
  let m;
  while ((m = startRe.exec(src)) !== null) {
    const constStart = m.index;
    const constEnd = m.index + m[0].length; // posisi setelah "const " + spasi

    // lewati komentar
    const lineStart = src.lastIndexOf('\n', constStart) + 1;
    const prefix = src.slice(lineStart, constStart);
    if (/^\s*(\/\/|\*|\/\*)/.test(prefix) || /\/\/.*$/.test(prefix)) continue;

    // cari kurung pembuka pertama setelah const
    let open = constEnd;
    while (open < src.length && !'([' .includes(src[open])) open++;
    const close = findClose(src, open);
    if (close < 0) continue;

    const body = src.slice(constStart, close + 1);
    if (refRe.test(body)) ranges.push([constStart, constEnd]);
  }
  let out = src;
  for (let k = ranges.length - 1; k >= 0; k--) {
    const [a, b] = ranges[k];
    out = out.slice(0, a) + out.slice(b);
  }
  return { text: out, count: ranges.length };
}

function ensureImport(src, eol) {
  if (src.includes('santri_ui.dart')) return { text: src, added: false };
  return { text: src, added: null }; // diisi per file (path import beda)
}

function addImportLine(src, line, eol, anchors) {
  if (src.includes('santri_ui.dart')) return { text: src, added: false };
  for (const a of anchors) {
    const idx = src.indexOf(a);
    if (idx >= 0) {
      return { text: src.slice(0, idx) + line + eol + src.slice(idx), added: true };
    }
  }
  // fallback: setelah import terakhir
  const re = /^import .*;[ \t]*\r?$/gm;
  let last = null;
  let mm;
  while ((mm = re.exec(src)) !== null) last = mm;
  if (last) {
    const pos = last.index + last[0].length;
    return { text: src.slice(0, pos) + eol + line + src.slice(pos), added: true };
  }
  return { text: line + eol + src, added: true };
}

// ---------------------------------------------------------------------------
// Palet -> getter ke SC
// ---------------------------------------------------------------------------
function convertPalette(src, endName) {
  let n = 0;
  const rep = (re, to) => {
    src = src.replace(re, (...a) => {
      n++;
      return to.replace(/\$1/g, a[1]);
    });
  };

  // Keadaan awal: konstanta emerald
  rep(/static const (\w+) = Color\(0xFF0F3A2E\);/g, 'static Color get $1 => SC.primary;');
  rep(/static const (\w+) = Color\(0xFF(?:164E3D|1B4D3E)\);/g, 'static Color get $1 => SC.primaryEnd;');
  rep(/static const (\w+) = Color\(0xFFD2E4DC\);/g, 'static Color get $1 => SC.mint;');
  rep(/static const (\w+) = Color\(0xFFE2ECE9\);/g, 'static Color get $1 => SC.sage;');

  // Perbaiki sisa tulisan "$1" yang terlanjur masuk ke file
  const fixLit = (target, name) => {
    const re = new RegExp('static Color get \\$1 => SC\\.' + target + ';', 'g');
    src = src.replace(re, () => {
      n++;
      return 'static Color get ' + name + ' => SC.' + target + ';';
    });
  };
  fixLit('primary', 'primary');
  fixLit('primaryEnd', endName);
  fixLit('mint', 'mint');
  fixLit('sage', 'sage');

  return { text: src, count: n };
}

// ---------------------------------------------------------------------------
// Definisi 4 file kecil
// ---------------------------------------------------------------------------
const SMALL_FILES = [
  { file: 'lib/screens/admin/notifikasi_screen.dart', cls: '_NC', endName: 'primaryEnd' },
  { file: 'lib/screens/admin/pengaturan_admin_screen.dart', cls: '_AC', endName: 'primarySoft' },
  { file: 'lib/screens/akademik/absensi_screen.dart', cls: '_AC', endName: 'primaryGradientEnd' },
  { file: 'lib/screens/master/kelas_list_screen.dart', cls: '_KC', endName: 'primary' },
];

function processSmall(cfg) {
  const full = path.join(ROOT, cfg.file);
  if (!fs.existsSync(full)) return { file: cfg.file, skip: 'file tidak ditemukan' };
  let src = fs.readFileSync(full, 'utf8');
  const original = src;
  const eol = src.includes('\r\n') ? '\r\n' : '\n';
  const log = [];

  const pal = convertPalette(src, cfg.endName);
  src = pal.text;
  if (pal.count) log.push('palet: ' + pal.count + ' baris');

  if (cfg.cls === '_KC') {
    const before = src;
    src = src.replace(/const Color\.fromRGBO\(15, 58, 46, 1\)/g, '_KC.primary');
    if (src !== before) log.push('tombol Simpan dialog -> _KC.primary');
  }

  const imp = addImportLine(
    src,
    "import '../santri/santri_ui.dart';",
    eol,
    ["import '../ui_utils.dart';", "import '../../services/app_scope.dart';"]
  );
  src = imp.text;
  if (imp.added) log.push('import santri_ui.dart ditambah');

  const refRe = new RegExp('\\b' + cfg.cls + '\\.(?:primary\\w*|mint|sage)\\b');
  const c = removeConstWithRefs(src, refRe);
  src = c.text;
  if (c.count) log.push('const dihapus: ' + c.count);

  if (src === original) return { file: cfg.file, log: ['tidak ada yang perlu diubah'] };
  return { file: cfg.file, full, src, log };
}

// ---------------------------------------------------------------------------
// dashboard_screen.dart (bagian admin saja)
// ---------------------------------------------------------------------------
function processDashboard() {
  const file = 'lib/screens/dashboard_screen.dart';
  const full = path.join(ROOT, file);
  if (!fs.existsSync(full)) return { file, skip: 'file tidak ditemukan' };
  let src = fs.readFileSync(full, 'utf8');
  const original = src;
  const eol = src.includes('\r\n') ? '\r\n' : '\n';
  const log = [];

  // 1. import
  const imp = addImportLine(src, "import 'santri/santri_ui.dart';", eol, []);
  // letakkan setelah santri_form_screen kalau ada
  if (imp.added) {
    src = original.includes("import 'santri/santri_form_screen.dart';")
      ? original.replace(
          "import 'santri/santri_form_screen.dart';",
          "import 'santri/santri_form_screen.dart';" + eol + "import 'santri/santri_ui.dart';"
        )
      : imp.text;
    log.push('import santri_ui.dart ditambah');
  }

  // 2. kelas _TC
  if (!src.includes('class _TC')) {
    const anchor = '/// Saklar SEMENTARA untuk melihat beranda Ustadz';
    const idx = src.indexOf(anchor);
    if (idx < 0) return { file, skip: 'anchor _TC tidak ditemukan' };
    const block = [
      '/// Warna utama tenant (ikut tema pondok). Dipakai bagian Admin Lembaga saja.',
      'class _TC {',
      '  _TC._();',
      '  static Color get primary => SC.primary;',
      '  static Color get primaryEnd => SC.primaryEnd;',
      '  static Color get mint => SC.mint;',
      '  static Color get sage => SC.sage;',
      '}',
      '',
      '',
    ].join(eol);
    src = src.slice(0, idx) + block + src.slice(idx);
    log.push('class _TC ditambah');
  }

  // 3. daftar warna tombol audit (tidak boleh const)
  const before3 = src;
  src = src.replace(
    /const accents = \[_WC\.errorText, _WC\.goldDark, _(?:WC|TC)\.primary\];/,
    'final accents = [_WC.errorText, _WC.goldDark, _TC.primary];'
  );
  if (src !== before3) log.push('accents -> final + _TC');

  // 4. tiga blok admin
  const blocks = [
    ['_heroHeader', 'Widget _heroHeader(String role)', 'Widget _waliHeroHeader()'],
    ['_tenantBody & kartu admin', 'Widget _tenantBody()', '// USTADZ / GURU / MUSYRIF'],
    ['_QuickAction', 'class _QuickAction extends StatelessWidget', '/// Grid 2 kolom'],
  ];

  for (const [name, startMark, endMark] of blocks) {
    const a = src.indexOf(startMark);
    if (a < 0) {
      log.push('PERINGATAN: blok ' + name + ' tidak ditemukan');
      continue;
    }
    const b = src.indexOf(endMark, a + startMark.length);
    if (b < 0) {
      log.push('PERINGATAN: akhir blok ' + name + ' tidak ditemukan');
      continue;
    }
    let seg = src.slice(a, b);
    const segOrig = seg;

    seg = seg
      .replace(/_WC\.primaryGradientEnd\b/g, '_TC.primaryEnd')
      .replace(/_WC\.primary\b/g, '_TC.primary')
      .replace(/_WC\.mint\b/g, '_TC.mint')
      .replace(/_WC\.sage\b/g, '_TC.sage');

    const c = removeConstWithRefs(seg, /\b_TC\.\w+/);
    seg = c.text;

    if (seg !== segOrig) log.push('blok ' + name + ': _WC -> _TC, const dihapus ' + c.count);
    src = src.slice(0, a) + seg + src.slice(b);
  }

  if (src === original) return { file, log: ['tidak ada yang perlu diubah'] };
  return { file, full, src, log };
}

// ---------------------------------------------------------------------------
// Jalankan
// ---------------------------------------------------------------------------
const results = [...SMALL_FILES.map(processSmall), processDashboard()];

for (const r of results) {
  if (r.skip) {
    console.log('LEWAT   ' + r.file + '  (' + r.skip + ')');
    continue;
  }
  if (r.src && r.full) {
    const bak = r.full + '.bak';
    if (!fs.existsSync(bak)) fs.copyFileSync(r.full, bak);
    fs.writeFileSync(r.full, r.src, 'utf8');
    console.log('UBAH    ' + r.file);
  } else {
    console.log('SAMA    ' + r.file);
  }
  for (const l of r.log || []) console.log('          - ' + l);
}

console.log('\nSelesai. Langkah berikutnya: jalankan  flutter analyze');