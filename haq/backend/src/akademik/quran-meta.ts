// quran-meta.ts
// Metadata Al-Qur'an: 114 surat, 6.236 ayat, 30 juz (riwayat Hafs, hitungan Kufi, standar Mushaf Madinah).
// Angka diambil dari api.alquran.cloud/v1/meta; awal Juz 4 (Ali 'Imran:93) cocok dengan Quran.com.
// ayatAbs = nomor ayat urut 1..6236 dari Al-Fatihah:1 sampai An-Nas:6.
// Nama surat hanya untuk tampilan; perhitungan hanya memakai nomor surat dan jumlah ayat.

export interface SurahMeta {
  number: number;
  name: string;
  ayat: number;
  /** ayatAbs dari ayat pertama surat ini */
  startAbs: number;
}

const RAW_SURAH: ReadonlyArray<readonly [string, number]> = [
  ["Al-Fatihah", 7],
  ["Al-Baqarah", 286],
  ["Ali 'Imran", 200],
  ["An-Nisa'", 176],
  ["Al-Ma'idah", 120],
  ["Al-An'am", 165],
  ["Al-A'raf", 206],
  ["Al-Anfal", 75],
  ["At-Taubah", 129],
  ["Yunus", 109],
  ["Hud", 123],
  ["Yusuf", 111],
  ["Ar-Ra'd", 43],
  ["Ibrahim", 52],
  ["Al-Hijr", 99],
  ["An-Nahl", 128],
  ["Al-Isra'", 111],
  ["Al-Kahf", 110],
  ["Maryam", 98],
  ["Tha-Ha", 135],
  ["Al-Anbiya'", 112],
  ["Al-Hajj", 78],
  ["Al-Mu'minun", 118],
  ["An-Nur", 64],
  ["Al-Furqan", 77],
  ["Asy-Syu'ara'", 227],
  ["An-Naml", 93],
  ["Al-Qashash", 88],
  ["Al-'Ankabut", 69],
  ["Ar-Rum", 60],
  ["Luqman", 34],
  ["As-Sajdah", 30],
  ["Al-Ahzab", 73],
  ["Saba'", 54],
  ["Fathir", 45],
  ["Ya-Sin", 83],
  ["Ash-Shaffat", 182],
  ["Shad", 88],
  ["Az-Zumar", 75],
  ["Ghafir", 85],
  ["Fushshilat", 54],
  ["Asy-Syura", 53],
  ["Az-Zukhruf", 89],
  ["Ad-Dukhan", 59],
  ["Al-Jatsiyah", 37],
  ["Al-Ahqaf", 35],
  ["Muhammad", 38],
  ["Al-Fath", 29],
  ["Al-Hujurat", 18],
  ["Qaf", 45],
  ["Adz-Dzariyat", 60],
  ["Ath-Thur", 49],
  ["An-Najm", 62],
  ["Al-Qamar", 55],
  ["Ar-Rahman", 78],
  ["Al-Waqi'ah", 96],
  ["Al-Hadid", 29],
  ["Al-Mujadilah", 22],
  ["Al-Hasyr", 24],
  ["Al-Mumtahanah", 13],
  ["Ash-Shaff", 14],
  ["Al-Jumu'ah", 11],
  ["Al-Munafiqun", 11],
  ["At-Taghabun", 18],
  ["Ath-Thalaq", 12],
  ["At-Tahrim", 12],
  ["Al-Mulk", 30],
  ["Al-Qalam", 52],
  ["Al-Haqqah", 52],
  ["Al-Ma'arij", 44],
  ["Nuh", 28],
  ["Al-Jinn", 28],
  ["Al-Muzzammil", 20],
  ["Al-Muddatstsir", 56],
  ["Al-Qiyamah", 40],
  ["Al-Insan", 31],
  ["Al-Mursalat", 50],
  ["An-Naba'", 40],
  ["An-Nazi'at", 46],
  ["'Abasa", 42],
  ["At-Takwir", 29],
  ["Al-Infithar", 19],
  ["Al-Muthaffifin", 36],
  ["Al-Insyiqaq", 25],
  ["Al-Buruj", 22],
  ["Ath-Thariq", 17],
  ["Al-A'la", 19],
  ["Al-Ghasyiyah", 26],
  ["Al-Fajr", 30],
  ["Al-Balad", 20],
  ["Asy-Syams", 15],
  ["Al-Lail", 21],
  ["Adh-Dhuha", 11],
  ["Asy-Syarh", 8],
  ["At-Tin", 8],
  ["Al-'Alaq", 19],
  ["Al-Qadr", 5],
  ["Al-Bayyinah", 8],
  ["Az-Zalzalah", 8],
  ["Al-'Adiyat", 11],
  ["Al-Qari'ah", 11],
  ["At-Takatsur", 8],
  ["Al-'Ashr", 3],
  ["Al-Humazah", 9],
  ["Al-Fil", 5],
  ["Quraisy", 4],
  ["Al-Ma'un", 7],
  ["Al-Kautsar", 3],
  ["Al-Kafirun", 6],
  ["An-Nashr", 3],
  ["Al-Lahab", 5],
  ["Al-Ikhlash", 4],
  ["Al-Falaq", 5],
  ["An-Nas", 6],
];

export const TOTAL_AYAT = 6236;

export const SURAH: readonly SurahMeta[] = (() => {
  let acc = 0;
  return RAW_SURAH.map(([name, ayat], i) => {
    const m: SurahMeta = { number: i + 1, name, ayat, startAbs: acc + 1 };
    acc += ayat;
    return m;
  });
})();

/** Awal tiap juz sebagai [surat, ayat]. Indeks 0 = Juz 1. */
export const JUZ_START: ReadonlyArray<readonly [number, number]> = [
  [1, 1], // Juz 1
  [2, 142], // Juz 2
  [2, 253], // Juz 3
  [3, 93], // Juz 4
  [4, 24], // Juz 5
  [4, 148], // Juz 6
  [5, 82], // Juz 7
  [6, 111], // Juz 8
  [7, 88], // Juz 9
  [8, 41], // Juz 10
  [9, 93], // Juz 11
  [11, 6], // Juz 12
  [12, 53], // Juz 13
  [15, 1], // Juz 14
  [17, 1], // Juz 15
  [18, 75], // Juz 16
  [21, 1], // Juz 17
  [23, 1], // Juz 18
  [25, 21], // Juz 19
  [27, 56], // Juz 20
  [29, 46], // Juz 21
  [33, 31], // Juz 22
  [36, 28], // Juz 23
  [39, 32], // Juz 24
  [41, 47], // Juz 25
  [46, 1], // Juz 26
  [51, 31], // Juz 27
  [58, 1], // Juz 28
  [67, 1], // Juz 29
  [78, 1], // Juz 30
];

export function isValidAyah(surah: number, ayah: number): boolean {
  return (
    Number.isInteger(surah) && Number.isInteger(ayah) &&
    surah >= 1 && surah <= 114 && ayah >= 1 && ayah <= SURAH[surah - 1].ayat
  );
}

export function toAbs(surah: number, ayah: number): number {
  return SURAH[surah - 1].startAbs + ayah - 1;
}

export function fromAbs(abs: number): { surah: number; ayah: number } {
  for (let i = 113; i >= 0; i--) {
    if (abs >= SURAH[i].startAbs) return { surah: i + 1, ayah: abs - SURAH[i].startAbs + 1 };
  }
  throw new Error('ayatAbs di luar jangkauan: ' + abs);
}

export function juzStartAbs(juz: number): number {
  const [s, a] = JUZ_START[juz - 1];
  return toAbs(s, a);
}

export function juzEndAbs(juz: number): number {
  return juz >= 30 ? TOTAL_AYAT : juzStartAbs(juz + 1) - 1;
}

export function juzOfAbs(abs: number): number {
  for (let j = 30; j >= 1; j--) if (abs >= juzStartAbs(j)) return j;
  throw new Error('ayatAbs di luar jangkauan: ' + abs);
}

/**
 * Validasi setoran. Mengembalikan pesan error (bahasa Indonesia) atau null jika valid.
 * Rentang boleh lintas surat, tetapi harus berada di dalam juz yang dipilih.
 */
export function validateSetoran(
  juz: number, suratMulai: number, ayatMulai: number, suratSelesai: number, ayatSelesai: number,
): string | null {
  if (!Number.isInteger(juz) || juz < 1 || juz > 30) return 'Juz harus 1 sampai 30.';
  if (!isValidAyah(suratMulai, ayatMulai)) return 'Surat/ayat mulai tidak valid.';
  if (!isValidAyah(suratSelesai, ayatSelesai)) return 'Surat/ayat selesai tidak valid.';
  const a = toAbs(suratMulai, ayatMulai);
  const b = toAbs(suratSelesai, ayatSelesai);
  if (a > b) return 'Ayat mulai tidak boleh setelah ayat selesai.';
  if (a < juzStartAbs(juz) || b > juzEndAbs(juz)) return 'Rentang ayat berada di luar Juz ' + juz + '.';
  return null;
}