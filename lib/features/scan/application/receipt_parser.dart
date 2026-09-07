import '../../../data/models/transaction_type.dart';

/// Hasil membaca teks OCR sebuah struk belanja menjadi draft transaksi.
///
/// Seperti `VoiceParseResult`, `amount` hanya dianggap [amountConfident] bila
/// ditemukan pada baris berlabel total/bayar — di luar itu field dibiarkan
/// agar pengguna melengkapi/memeriksa manual (mitigasi risiko PRD §13).
class ReceiptScanResult {
  const ReceiptScanResult({
    required this.rawText,
    this.amount,
    this.amountConfident = false,
    this.date,
    this.merchant,
  });

  final String rawText;
  final int? amount;
  final bool amountConfident;
  final DateTime? date;

  /// Nama toko / baris teratas struk — dipakai sebagai keterangan awal.
  final String? merchant;

  /// Struk selalu berupa pengeluaran.
  TransactionType get type => TransactionType.keluar;

  bool get isEmpty => amount == null && date == null && merchant == null;
}

/// Kata kunci baris yang memuat nilai yang harus diambil, dari yang paling
/// tepercaya. Dicek berurutan; kelompok pertama yang cocok menang.
const _amountKeywordTiers = <List<String>>[
  [
    'grand total',
    'total akhir',
    'total bayar',
    'total belanja',
    'total tagihan',
  ],
  ['total', 'jumlah', 'amount due', 'balance due'],
  ['tunai', 'cash', 'bayar', 'dibayar', 'paid'],
  ['subtotal', 'sub total', 'sub-total'],
];

/// Baris yang harus diabaikan saat mencari nominal (bukan nilai transaksi).
const _amountLineBlocklist = <String>[
  'kembali',
  'kembalian',
  'change',
  'npwp',
  'no.',
  'telp',
  'telepon',
  'ppn',
  'pb1',
  'pajak',
  'tax',
  'discount',
  'diskon',
  'potongan',
  'hemat',
  'poin',
  'point',
];

/// Ubah teks mentah hasil OCR menjadi [ReceiptScanResult]. Fungsi murni —
/// tidak menyentuh plugin/kamera, sehingga bisa diuji unit.
ReceiptScanResult parseReceiptText(String rawText) {
  final lines = rawText
      .split('\n')
      .map((l) => l.trim())
      .where((l) => l.isNotEmpty)
      .toList();

  final amount = _findAmount(lines);
  return ReceiptScanResult(
    rawText: rawText,
    amount: amount?.value,
    amountConfident: amount?.confident ?? false,
    date: _findDate(rawText),
    merchant: _findMerchant(lines),
  );
}

class _AmountHit {
  const _AmountHit(this.value, this.confident);
  final int value;
  final bool confident;
}

_AmountHit? _findAmount(List<String> lines) {
  for (final tier in _amountKeywordTiers) {
    int? best;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!tier.any(lower.contains)) continue;
      if (_amountLineBlocklist.any(lower.contains)) continue;
      for (final value in _numbersIn(line)) {
        if (best == null || value > best) best = value;
      }
    }
    if (best != null) {
      // "subtotal" adalah fallback lemah — tetap dianggap perlu ditinjau.
      final confident = tier != _amountKeywordTiers.last;
      return _AmountHit(best, confident);
    }
  }

  // Tidak ada baris berlabel — ambil angka "uang" terbesar di seluruh struk
  // sebagai tebakan, tapi tandai belum yakin.
  int? fallback;
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (_amountLineBlocklist.any(lower.contains)) continue;
    for (final value in _numbersIn(line, requireGrouping: true)) {
      if (fallback == null || value > fallback) fallback = value;
    }
  }
  return fallback == null ? null : _AmountHit(fallback, false);
}

/// Semua nilai uang pada satu baris. Menerima "50.000", "50,000",
/// "Rp 50.000", "50.000,00". Bila [requireGrouping] true hanya menerima
/// angka dengan pemisah ribuan (mengurangi false positive dari nomor struk).
Iterable<int> _numbersIn(String line, {bool requireGrouping = false}) sync* {
  final pattern = requireGrouping
      ? RegExp(r'\d{1,3}(?:[.\s]\d{3})+(?:,\d{2})?')
      : RegExp(r'\d{1,3}(?:[.,\s]\d{3})*(?:[.,]\d{2})?|\d+');
  for (final match in pattern.allMatches(line)) {
    final raw = match.group(0)!;
    final parsed = _normalizeAmount(raw);
    if (parsed != null && parsed > 0) yield parsed;
  }
}

/// "50.000,00" / "50,000.00" / "50.000" → 50000 (Rupiah bulat, tanpa sen).
int? _normalizeAmount(String raw) {
  var s = raw.replaceAll(RegExp(r'\s'), '');
  // Buang bagian desimal 2 digit di akhir (sen), apapun pemisahnya.
  s = s.replaceFirst(RegExp(r'[.,]\d{2}$'), '');
  // Sisa pemisah ribuan dibuang.
  s = s.replaceAll(RegExp(r'[.,]'), '');
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

DateTime? _findDate(String text) {
  // yyyy-mm-dd (ISO) diperiksa lebih dulu agar tidak salah dibaca sebagai
  // dd-mm-yy oleh pola di bawahnya. `(?<!\d)`/`(?!\d)` menahan pola menempel
  // ke rangkaian digit lain (mis. nomor struk).
  final ymd = RegExp(r'(?<!\d)(\d{4})[/\-.](\d{1,2})[/\-.](\d{1,2})(?!\d)');
  for (final m in ymd.allMatches(text)) {
    final d = _validDate(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
    if (d != null) return d;
  }
  // dd/mm/yyyy · dd-mm-yy · dd.mm.yyyy (urutan hari-bulan, umum di ID/MY).
  final dmy = RegExp(r'(?<!\d)(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})(?!\d)');
  for (final m in dmy.allMatches(text)) {
    final day = int.parse(m.group(1)!);
    final month = int.parse(m.group(2)!);
    var year = int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    final d = _validDate(year, month, day);
    if (d != null) return d;
  }
  return null;
}

DateTime? _validDate(int year, int month, int day) {
  if (month < 1 || month > 12 || day < 1 || day > 31) return null;
  if (year < 2000 || year > 2100) return null;
  final d = DateTime(year, month, day);
  if (d.month != month || d.day != day) return null; // mis. 31 Feb
  // Struk tidak mungkin dari masa depan jauh.
  if (d.isAfter(DateTime.now().add(const Duration(days: 1)))) return null;
  return d;
}

String? _findMerchant(List<String> lines) {
  for (final line in lines.take(6)) {
    final letters = line.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 3) continue;
    final lower = line.toLowerCase();
    if (lower.contains('struk') ||
        lower.contains('receipt') ||
        lower.contains('invoice') ||
        lower.contains('npwp') ||
        lower.startsWith('jl') ||
        lower.startsWith('jalan')) {
      continue;
    }
    // Rapikan spasi ganda, batasi panjang agar layak jadi keterangan.
    final cleaned = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.length > 40 ? cleaned.substring(0, 40).trim() : cleaned;
  }
  return null;
}
