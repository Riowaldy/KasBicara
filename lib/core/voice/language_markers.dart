// Tabel kata penanda + bobot untuk `LanguageDetector` (konsep
// "Trilingual KasBicara" §04). Semua token lowercase, satu kata.

// --- Tahap 1: gerbang Inggris ---------------------------------------------

/// Kata kerja transaksi khas Inggris — bobot 3.
const enVerbMarkers = {
  'spent',
  'spend',
  'paid',
  'pay',
  'bought',
  'buy',
  'received',
  'earned',
  'got',
  'cost',
};

/// Kata fungsi & kategori khas Inggris — bobot 2.
const enFunctionMarkers = {
  'the',
  'for',
  'from',
  'on',
  'my',
  'and',
  'a',
  'food',
  'lunch',
  'dinner',
  'coffee',
  'fuel',
  'gas',
  'groceries',
  'rent',
  'salary',
  'bonus',
  'dollars',
};

// --- Tahap 2: Indonesia vs Melayu ---------------------------------------------

/// Grup A — isyarat mata uang, bobot 3 (nyaris pasti).
const msCurrencyMarkers = {'ringgit', 'rm', 'sen'};
const idCurrencyMarkers = {'rupiah', 'rp', 'perak'};

/// Grup B — kosakata khas, bobot 2.
const msLexicalMarkers = {
  'duit',
  'wang',
  'kedai',
  'tambang',
  'minyak',
  'basikal',
  'kereta',
  'wayang',
  'ubat',
  'bil',
  'kasut',
  'teksi',
  'doktor',
  'yuran',
};
const idLexicalMarkers = {
  'uang',
  'warung',
  'bensin',
  'mobil',
  'motor',
  'ojek',
  'gojek',
  'grab',
  'pulsa',
  'bon',
  'sepatu',
  'dokter',
};

/// Grup C — partikel & kata fungsi, bobot 1.
const msFunctionMarkers = {
  'tak',
  'nak',
  'kena',
  'sebab',
  'daripada',
  'kepada',
  'boleh',
  'dah',
  'ni',
};
const idFunctionMarkers = {
  'nggak',
  'gak',
  'udah',
  'buat',
  'banget',
  'aja',
  'dong',
  'sama',
};
