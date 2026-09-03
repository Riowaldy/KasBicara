import 'number_parser_en.dart';
import 'voice_parser.dart';

/// Parser ucapan Bahasa Inggris → draft transaksi.
///
/// Kata kunci dan parser angka khusus Inggris — lihat konsep
/// "Trilingual KasBicara" §06.
class EnVoiceParser extends KeywordVoiceParser {
  const EnVoiceParser();

  @override
  Set<String> get outKeywords => const {
    'spent',
    'spend',
    'paid',
    'pay',
    'bought',
    'buy',
    'cost',
    'expense',
    'out',
  };

  @override
  Set<String> get inKeywords => const {
    'received',
    'receive',
    'earned',
    'earn',
    'got',
    'income',
    'in',
  };

  @override
  Set<String> get connectorWords => const {'for', 'on', 'from'};

  @override
  Set<String> get amountFillerWords => enAmountFillerWords;

  @override
  Map<String, String> get categoryKeywords => const {
    'lunch': 'expense-makanan-minuman',
    'dinner': 'expense-makanan-minuman',
    'breakfast': 'expense-makanan-minuman',
    'food': 'expense-makanan-minuman',
    'coffee': 'expense-makanan-minuman',
    'restaurant': 'expense-makanan-minuman',
    'fuel': 'expense-transportasi',
    'gas': 'expense-transportasi',
    'petrol': 'expense-transportasi',
    'taxi': 'expense-transportasi',
    'parking': 'expense-transportasi',
    'train': 'expense-transportasi',
    'bus': 'expense-transportasi',
    'groceries': 'expense-belanja',
    'clothes': 'expense-belanja',
    'shoes': 'expense-belanja',
    'shopping': 'expense-belanja',
    'electricity': 'expense-tagihan-utilitas',
    'internet': 'expense-tagihan-utilitas',
    'wifi': 'expense-tagihan-utilitas',
    'bill': 'expense-tagihan-utilitas',
    'medicine': 'expense-kesehatan',
    'doctor': 'expense-kesehatan',
    'hospital': 'expense-kesehatan',
    'movie': 'expense-hiburan',
    'cinema': 'expense-hiburan',
    'game': 'expense-hiburan',
    'book': 'expense-pendidikan',
    'tuition': 'expense-pendidikan',
    'course': 'expense-pendidikan',
    'salary': 'income-gaji',
    'bonus': 'income-bonus',
    'investment': 'income-investasi',
    'stocks': 'income-investasi',
    'transfer': 'income-transfer-masuk',
  };

  @override
  bool isNumberToken(String token) => isEnNumberToken(token);

  @override
  int? parseAmountTokens(List<String> tokens) => parseEnAmount(tokens);

  @override
  String normalizeNumericGlue(String text) => normalizeEnNumericGlue(text);
}
