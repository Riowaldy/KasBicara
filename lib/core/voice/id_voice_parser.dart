import 'number_parser_idms.dart';
import 'voice_parser.dart';

/// Parser ucapan Bahasa Indonesia → draft transaksi (PRD §6.1, §10).
class IdVoiceParser extends KeywordVoiceParser {
  const IdVoiceParser();

  @override
  Set<String> get outKeywords => const {
    'keluar',
    'bayar',
    'membayar',
    'beli',
    'membeli',
    'belanja',
    'habis',
    'pengeluaran',
    'keluarkan',
  };

  @override
  Set<String> get inKeywords => const {
    'masuk',
    'terima',
    'menerima',
    'nerima',
    'dapat',
    'dapet',
    'pemasukan',
  };

  @override
  Set<String> get connectorWords => const {'untuk', 'buat', 'buad', 'buwat'};

  @override
  Set<String> get amountFillerWords => idMsAmountFillerWords;

  @override
  Map<String, String> get categoryKeywords => const {
    'makan': 'expense-makanan-minuman',
    'minum': 'expense-makanan-minuman',
    'sarapan': 'expense-makanan-minuman',
    'jajan': 'expense-makanan-minuman',
    'kopi': 'expense-makanan-minuman',
    'restoran': 'expense-makanan-minuman',
    'bensin': 'expense-transportasi',
    'ojek': 'expense-transportasi',
    'gojek': 'expense-transportasi',
    'grab': 'expense-transportasi',
    'angkot': 'expense-transportasi',
    'parkir': 'expense-transportasi',
    'busway': 'expense-transportasi',
    'kereta': 'expense-transportasi',
    'taksi': 'expense-transportasi',
    'belanja': 'expense-belanja',
    'baju': 'expense-belanja',
    'sepatu': 'expense-belanja',
    'listrik': 'expense-tagihan-utilitas',
    'pulsa': 'expense-tagihan-utilitas',
    'internet': 'expense-tagihan-utilitas',
    'wifi': 'expense-tagihan-utilitas',
    'obat': 'expense-kesehatan',
    'dokter': 'expense-kesehatan',
    'rumahsakit': 'expense-kesehatan',
    'nonton': 'expense-hiburan',
    'bioskop': 'expense-hiburan',
    'game': 'expense-hiburan',
    'buku': 'expense-pendidikan',
    'kuliah': 'expense-pendidikan',
    'sekolah': 'expense-pendidikan',
    'gaji': 'income-gaji',
    'bonus': 'income-bonus',
    'investasi': 'income-investasi',
    'saham': 'income-investasi',
    'transfer': 'income-transfer-masuk',
  };

  @override
  bool isNumberToken(String token) => isIdMsNumberToken(token);

  @override
  int? parseAmountTokens(List<String> tokens) => parseIdMsAmount(tokens);

  @override
  String normalizeNumericGlue(String text) => normalizeIdMsNumericGlue(text);
}
