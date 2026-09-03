import 'number_parser_idms.dart';
import 'voice_parser.dart';

/// Parser ucapan Bahasa Melayu (Malaysia) → draft transaksi.
///
/// Angka identik dengan Bahasa Indonesia (modul `number_parser_idms.dart`);
/// yang berbeda kata kerja, penghubung, dan kategori — lihat konsep
/// "Trilingual KasBicara" §06.
class MsVoiceParser extends KeywordVoiceParser {
  const MsVoiceParser();

  @override
  Set<String> get outKeywords => const {
    'keluar',
    'beli',
    'membeli',
    'bayar',
    'membayar',
    'belanja',
    'berbelanja',
    'habis',
    'guna',
    'perbelanjaan',
  };

  @override
  Set<String> get inKeywords => const {
    'masuk',
    'terima',
    'menerima',
    'dapat',
    'dapap',
    'pendapatan',
    'pemasukan',
  };

  @override
  Set<String> get connectorWords => const {'untuk', 'bagi', 'buat'};

  @override
  Set<String> get amountFillerWords => idMsAmountFillerWords;

  @override
  Map<String, String> get categoryKeywords => const {
    'makan': 'expense-makanan-minuman',
    'minum': 'expense-makanan-minuman',
    'sarapan': 'expense-makanan-minuman',
    'kopi': 'expense-makanan-minuman',
    'restoran': 'expense-makanan-minuman',
    'restoren': 'expense-makanan-minuman',
    'minyak': 'expense-transportasi',
    'petrol': 'expense-transportasi',
    'tambang': 'expense-transportasi',
    'grab': 'expense-transportasi',
    'teksi': 'expense-transportasi',
    'basikal': 'expense-transportasi',
    'parkir': 'expense-transportasi',
    'kereta': 'expense-transportasi',
    'bas': 'expense-transportasi',
    'lrt': 'expense-transportasi',
    'kedai': 'expense-belanja',
    'baju': 'expense-belanja',
    'kasut': 'expense-belanja',
    'pasaraya': 'expense-belanja',
    'elektrik': 'expense-tagihan-utilitas',
    'bil': 'expense-tagihan-utilitas',
    'internet': 'expense-tagihan-utilitas',
    'wifi': 'expense-tagihan-utilitas',
    'ubat': 'expense-kesehatan',
    'doktor': 'expense-kesehatan',
    'klinik': 'expense-kesehatan',
    'hospital': 'expense-kesehatan',
    'wayang': 'expense-hiburan',
    'pawagam': 'expense-hiburan',
    'game': 'expense-hiburan',
    'buku': 'expense-pendidikan',
    'kuliah': 'expense-pendidikan',
    'sekolah': 'expense-pendidikan',
    'yuran': 'expense-pendidikan',
    'gaji': 'income-gaji',
    'bonus': 'income-bonus',
    'pelaburan': 'income-investasi',
    'saham': 'income-investasi',
    'pindahan': 'income-transfer-masuk',
    'transfer': 'income-transfer-masuk',
  };

  @override
  bool isNumberToken(String token) => isIdMsNumberToken(token);

  @override
  int? parseAmountTokens(List<String> tokens) => parseIdMsAmount(tokens);

  @override
  String normalizeNumericGlue(String text) => normalizeIdMsNumericGlue(text);
}
