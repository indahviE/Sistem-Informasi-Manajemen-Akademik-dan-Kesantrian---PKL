// quran_meta.dart
// Metadata Al-Qur'an: 114 surat, 6.236 ayat, 30 juz (riwayat Hafs, hitungan Kufi, standar Mushaf Madinah).
// Angka diambil dari api.alquran.cloud/v1/meta; awal Juz 4 (Ali 'Imran:93) cocok dengan Quran.com.
// ayatAbs = nomor ayat urut 1..6236 dari Al-Fatihah:1 sampai An-Nas:6.
// Harus sama persis dengan quran-meta.ts di backend.

const int kTotalAyat = 6236;

const List<String> kNamaSurat = [
  "Al-Fatihah",
  "Al-Baqarah",
  "Ali 'Imran",
  "An-Nisa'",
  "Al-Ma'idah",
  "Al-An'am",
  "Al-A'raf",
  "Al-Anfal",
  "At-Taubah",
  "Yunus",
  "Hud",
  "Yusuf",
  "Ar-Ra'd",
  "Ibrahim",
  "Al-Hijr",
  "An-Nahl",
  "Al-Isra'",
  "Al-Kahf",
  "Maryam",
  "Tha-Ha",
  "Al-Anbiya'",
  "Al-Hajj",
  "Al-Mu'minun",
  "An-Nur",
  "Al-Furqan",
  "Asy-Syu'ara'",
  "An-Naml",
  "Al-Qashash",
  "Al-'Ankabut",
  "Ar-Rum",
  "Luqman",
  "As-Sajdah",
  "Al-Ahzab",
  "Saba'",
  "Fathir",
  "Ya-Sin",
  "Ash-Shaffat",
  "Shad",
  "Az-Zumar",
  "Ghafir",
  "Fushshilat",
  "Asy-Syura",
  "Az-Zukhruf",
  "Ad-Dukhan",
  "Al-Jatsiyah",
  "Al-Ahqaf",
  "Muhammad",
  "Al-Fath",
  "Al-Hujurat",
  "Qaf",
  "Adz-Dzariyat",
  "Ath-Thur",
  "An-Najm",
  "Al-Qamar",
  "Ar-Rahman",
  "Al-Waqi'ah",
  "Al-Hadid",
  "Al-Mujadilah",
  "Al-Hasyr",
  "Al-Mumtahanah",
  "Ash-Shaff",
  "Al-Jumu'ah",
  "Al-Munafiqun",
  "At-Taghabun",
  "Ath-Thalaq",
  "At-Tahrim",
  "Al-Mulk",
  "Al-Qalam",
  "Al-Haqqah",
  "Al-Ma'arij",
  "Nuh",
  "Al-Jinn",
  "Al-Muzzammil",
  "Al-Muddatstsir",
  "Al-Qiyamah",
  "Al-Insan",
  "Al-Mursalat",
  "An-Naba'",
  "An-Nazi'at",
  "'Abasa",
  "At-Takwir",
  "Al-Infithar",
  "Al-Muthaffifin",
  "Al-Insyiqaq",
  "Al-Buruj",
  "Ath-Thariq",
  "Al-A'la",
  "Al-Ghasyiyah",
  "Al-Fajr",
  "Al-Balad",
  "Asy-Syams",
  "Al-Lail",
  "Adh-Dhuha",
  "Asy-Syarh",
  "At-Tin",
  "Al-'Alaq",
  "Al-Qadr",
  "Al-Bayyinah",
  "Az-Zalzalah",
  "Al-'Adiyat",
  "Al-Qari'ah",
  "At-Takatsur",
  "Al-'Ashr",
  "Al-Humazah",
  "Al-Fil",
  "Quraisy",
  "Al-Ma'un",
  "Al-Kautsar",
  "Al-Kafirun",
  "An-Nashr",
  "Al-Lahab",
  "Al-Ikhlash",
  "Al-Falaq",
  "An-Nas",
];

const List<int> kJumlahAyat = [
  7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99, 128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60, 34, 30, 73, 54, 45, 83, 182, 88, 75, 85, 54, 53, 89, 59, 37, 35, 38, 29, 18, 45, 60, 49, 62, 55, 78, 96, 29, 22, 24, 13, 14, 11, 11, 18, 12, 12, 30, 52, 52, 44, 28, 28, 20, 56, 40, 31, 50, 40, 46, 42, 29, 19, 36, 25, 22, 17, 19, 26, 30, 20, 15, 21, 11, 8, 8, 19, 5, 8, 8, 11, 11, 8, 3, 9, 5, 4, 7, 3, 6, 3, 5, 4, 5, 6
];

/// Awal tiap juz sebagai [surat, ayat]. Indeks 0 = Juz 1.
const List<List<int>> kAwalJuz = [
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

final List<int> _startAbs = () {
  final r = <int>[];
  var acc = 0;
  for (final n in kJumlahAyat) {
    r.add(acc + 1);
    acc += n;
  }
  return r;
}();

class PosisiAyat {
  final int surat;
  final int ayat;
  const PosisiAyat(this.surat, this.ayat);
}

bool ayatValid(int surat, int ayat) =>
    surat >= 1 && surat <= 114 && ayat >= 1 && ayat <= kJumlahAyat[surat - 1];

int ayatAbs(int surat, int ayat) => _startAbs[surat - 1] + ayat - 1;

PosisiAyat dariAbs(int abs) {
  for (var i = 113; i >= 0; i--) {
    if (abs >= _startAbs[i]) return PosisiAyat(i + 1, abs - _startAbs[i] + 1);
  }
  throw RangeError('ayatAbs di luar jangkauan: $abs');
}

int juzMulaiAbs(int juz) => ayatAbs(kAwalJuz[juz - 1][0], kAwalJuz[juz - 1][1]);

int juzAkhirAbs(int juz) => juz >= 30 ? kTotalAyat : juzMulaiAbs(juz + 1) - 1;

int juzDariAbs(int abs) {
  for (var j = 30; j >= 1; j--) {
    if (abs >= juzMulaiAbs(j)) return j;
  }
  throw RangeError('ayatAbs di luar jangkauan: $abs');
}

/// Nomor surat yang ada di dalam juz tersebut (untuk dropdown surat).
List<int> suratDalamJuz(int juz) {
  final a = dariAbs(juzMulaiAbs(juz)).surat;
  final b = dariAbs(juzAkhirAbs(juz)).surat;
  return [for (var s = a; s <= b; s++) s];
}

/// Batas ayat [min, maks] yang boleh dipilih untuk [surat] di dalam [juz].
List<int> batasAyatDiJuz(int juz, int surat) {
  final awal = ayatAbs(surat, 1);
  final akhir = ayatAbs(surat, kJumlahAyat[surat - 1]);
  final lo = awal > juzMulaiAbs(juz) ? awal : juzMulaiAbs(juz);
  final hi = akhir < juzAkhirAbs(juz) ? akhir : juzAkhirAbs(juz);
  return [dariAbs(lo).ayat, dariAbs(hi).ayat];
}

/// Pesan error (Indonesia) atau null jika setoran valid.
String? validasiSetoran(int juz, int suratMulai, int ayatMulai, int suratSelesai, int ayatSelesai) {
  if (juz < 1 || juz > 30) return 'Juz harus 1 sampai 30.';
  if (!ayatValid(suratMulai, ayatMulai)) return 'Surat/ayat mulai tidak valid.';
  if (!ayatValid(suratSelesai, ayatSelesai)) return 'Surat/ayat selesai tidak valid.';
  final a = ayatAbs(suratMulai, ayatMulai);
  final b = ayatAbs(suratSelesai, ayatSelesai);
  if (a > b) return 'Ayat mulai tidak boleh setelah ayat selesai.';
  if (a < juzMulaiAbs(juz) || b > juzAkhirAbs(juz)) return 'Rentang ayat berada di luar Juz $juz.';
  return null;
}