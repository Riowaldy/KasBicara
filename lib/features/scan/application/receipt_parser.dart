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

final _urlLike = RegExp(
  r'https?://|www\.|[a-z0-9-]+\.(com|net|id|co|org|io|shop|store)\b',
  caseSensitive: false,
);

/// Total struk di bawah nilai ini dianggap tak masuk akal (hampir pasti
/// artefak OCR, mis. "4,50" yang seharusnya "4.500") sehingga jalur kata
/// kunci tak langsung dipercaya.
const _minPlausibleTotal = 500;

_AmountHit? _findAmount(List<String> allLines) {
  // Baris URL ("olshopin.com/f/748488") memuat angka panjang yang bukan
  // nominal — buang dulu agar tak mencemari tebakan.
  final lines = allLines.where((l) => !_urlLike.hasMatch(l)).toList();

  // Σ harga baris item — patokan silang paling andal: total struk = jumlah
  // harga item (PPN sudah termasuk di ID/MY). Dipakai untuk mengoreksi jalur
  // kata kunci yang sering "nyangkut" di baris item atau baris "Bayar".
  final itemSum = _lineItemTotal(lines);

  int? keywordHit;
  var keywordConfident = false;
  int? implausible;
  var sawStrongKeyword = false;
  for (var t = 0; t < _amountKeywordTiers.length; t++) {
    final tier = _amountKeywordTiers[t];
    int? best;
    for (final line in lines) {
      final lower = line.toLowerCase();
      if (!tier.any(lower.contains)) continue;
      if (t <= 1) sawStrongKeyword = true;
      if (_amountLineBlocklist.any(lower.contains)) continue;
      for (final value in _numbersIn(line)) {
        if (best == null || value > best) best = value;
      }
    }
    // Struk thermal sering di-OCR sebagai kolom terpisah: blok label
    // ("Sub Total / Total / Bayar / Kembali", kadang tercampur nama kasir)
    // lalu blok angka di bawahnya. Bila tak ada nominal sebaris label,
    // ambil nilai yang paling sering berulang pada deretan angka itu.
    best ??= _amountFromSeparatedColumns(lines, tier);
    if (best == null) continue;
    if (best < _minPlausibleTotal) {
      implausible ??= best; // OCR menelan digit ("4,50"); catat, cari lain
      continue;
    }
    keywordHit = best;
    keywordConfident = tier != _amountKeywordTiers.last; // "subtotal" = lemah
    break;
  }

  if (keywordHit != null) {
    // Koreksi bila hasil kata kunci jelas meleset dari Σ item: terlalu kecil
    // (< 70% — nyangkut di baris item) atau terlalu besar (> 150% — nyangkut
    // di "Bayar"/"Tunai"). Selisih wajar (pajak, diskon) tetap dipertahankan.
    if (itemSum != null &&
        (keywordHit * 10 < itemSum * 7 || keywordHit * 2 > itemSum * 3)) {
      return _AmountHit(itemSum, true);
    }
    return _AmountHit(keywordHit, keywordConfident);
  }

  // Tak ada nominal kata kunci yang masuk akal. Bila struknya jelas punya
  // baris total (kata kuncinya terlihat) atau tadi ada angka mini, pakai
  // Σ harga item.
  if (itemSum != null && (implausible != null || sawStrongKeyword)) {
    return _AmountHit(itemSum, true);
  }

  // Tidak ada baris berlabel — ambil nilai "uang" terbesar di seluruh struk
  // sebagai tebakan (tandai belum yakin). Terima angka berpemisah
  // ("47.000", "47,000", "47 000") maupun bulat 4–6 digit ("47000") yang
  // berdiri sendiri — bukan bagian barcode/nomor telepon.
  int? fallback;
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (_amountLineBlocklist.any(lower.contains)) continue;
    for (final value in _numbersIn(line, requireGrouping: true)) {
      if (fallback == null || value > fallback) fallback = value;
    }
    for (final value in _bareIntAmounts(line)) {
      if (fallback == null || value > fallback) fallback = value;
    }
  }
  return fallback == null ? null : _AmountHit(fallback, false);
}

final _dateOrTimeLike = RegExp(r'\d{1,4}[:/.\-]\d{1,4}');
final _bareIntPattern = RegExp(r'(?<![\d.,])\d{4,6}(?![\d.,])');

/// Baris deskripsi item yang jelas bukan nama toko / ringkasan — dilewati
/// saat menjumlahkan harga item.
bool _isNonItemLine(String lower, String line) =>
    _amountLineBlocklist.any(lower.contains) ||
    _amountKeywordTiers.any((t) => t.any(lower.contains)) ||
    _isStreetLine(line) ||
    _urlLike.hasMatch(line) ||
    lower.contains('npwp') ||
    lower.contains('kasir') ||
    lower.contains('kassa') ||
    lower.startsWith('bon ') ||
    lower.contains('sms') ||
    lower.contains('kritik') ||
    lower.contains('saran') ||
    _dateOrTimeLike.hasMatch(line);

/// Baris "kuantitas × harga" ("1 X 2,500 = 2,500", "2x 3.000").
final _qtyLine = RegExp(r'\d{1,4}\s*[xX×*]\s*\d');

/// Perkiraan total = Σ harga baris item — patokan silang untuk jalur kata
/// kunci. Dua bentuk baris item:
///  * "qty × harga = extended" → ambil nominal TERAKHIR (harga extended).
///  * baris deskripsi berharga (≥3 huruf) → ambil nominal TERBESAR (extended,
///    bukan harga satuan; sekaligus mengabaikan pengulangan "4.500 4.500").
/// Hanya menerima angka berpemisah ribuan agar kode produk 6–7 digit
/// ("253171 -> 1 X 6,545") tak ikut terjumlah.
int? _lineItemTotal(List<String> lines) {
  var sum = 0;
  var found = false;
  for (final line in lines) {
    final lower = line.toLowerCase();
    if (_isNonItemLine(lower, line)) continue;
    final isQty = _qtyLine.hasMatch(line);
    if (!isQty && line.replaceAll(RegExp(r'[^A-Za-z]'), '').length < 3) {
      continue;
    }
    final nums = _numbersIn(line, requireGrouping: true).toList();
    if (nums.isEmpty) continue;
    final v = isQty ? nums.last : nums.reduce((a, b) => a > b ? a : b);
    if (v > 0) {
      sum += v;
      found = true;
    }
  }
  return found ? sum : null;
}

/// Bilangan bulat 4–6 digit yang berdiri sendiri pada [line] sebagai kandidat
/// nominal (mis. "47000" saat OCR menghilangkan titik ribuan). Baris dengan
/// ≥2 gugus semacam itu dianggap barcode/serial dan dilewati; angka mirip
/// tahun pada baris bertanggal juga diabaikan.
Iterable<int> _bareIntAmounts(String line) sync* {
  final matches = _bareIntPattern.allMatches(line).toList();
  if (matches.length >= 2) return;
  final looksDated = _dateOrTimeLike.hasMatch(line);
  for (final m in matches) {
    final v = int.parse(m.group(0)!);
    if (v < 1000) continue;
    if (looksDated && v >= 1900 && v <= 2100) continue;
    yield v;
  }
}

/// Cari nominal untuk [tier] pada struk yang kolom label & angkanya di-OCR
/// terpisah. Cari blok baris "label" beruntun yang memuat kata kunci [tier],
/// lalu deretan baris "angka saja" persis setelahnya. Pemasangan per posisi
/// tak dapat diandalkan (blok label bisa tercampur nama kasir; kolom harga
/// item bisa mendahului kolom total), jadi ambil nilai yang **paling sering
/// berulang** — Sub Total, Total, dan Bayar lazimnya bernilai sama sehingga
/// total muncul beberapa kali. Seri dimenangkan nilai terbesar; 0 diabaikan.
int? _amountFromSeparatedColumns(List<String> lines, List<String> tier) {
  final isSubtotalTier = identical(tier, _amountKeywordTiers.last);
  for (var i = 0; i < lines.length; i++) {
    if (!_isLabelLine(lines[i])) continue;
    var j = i;
    while (j < lines.length && _isLabelLine(lines[j])) {
      j++;
    }
    final blockMatchesTier = lines.sublist(i, j).any((label) {
      final lower = label.toLowerCase();
      if (!tier.any(lower.contains)) return false;
      if (_amountLineBlocklist.any(lower.contains)) return false;
      // "Sub Total" juga memuat "total" — biar tier subtotal yang menanganinya.
      if (!isSubtotalTier && lower.contains('sub')) return false;
      return true;
    });
    i = j - 1;
    if (!blockMatchesTier) continue;

    final values = <int>[];
    for (var k = j; k < lines.length; k++) {
      final v = _soleAmount(lines[k]);
      if (v == null) break;
      if (v > 0) values.add(v);
    }
    if (values.isEmpty) continue;

    final counts = <int, int>{};
    for (final v in values) {
      counts[v] = (counts[v] ?? 0) + 1;
    }
    var bestVal = values.first;
    var bestCount = 0;
    counts.forEach((v, c) {
      if (c > bestCount || (c == bestCount && v > bestVal)) {
        bestVal = v;
        bestCount = c;
      }
    });
    return bestVal;
  }
  return null;
}

/// Baris "label": mengandung huruf tetapi tak satu pun digit.
bool _isLabelLine(String line) =>
    RegExp(r'[A-Za-z]').hasMatch(line) && !RegExp(r'\d').hasMatch(line);

/// Nilai bila [line] HANYA memuat satu nominal uang (boleh diawali "Rp",
/// spasi, pemisah ribuan, sen). Selain itu null.
int? _soleAmount(String line) {
  final s = line.replaceAll(RegExp(r'[Rr][Pp]\.?|\s'), '');
  if (s.isEmpty) return null;
  if (!RegExp(r'^\d{1,3}(?:[.,]\d{3})*(?:[.,]\d{2})?$').hasMatch(s) &&
      !RegExp(r'^\d+$').hasMatch(s)) {
    return null;
  }
  return _normalizeAmount(s);
}

/// Semua nilai uang pada satu baris. Menerima "50.000", "50,000",
/// "Rp 50.000", "50.000,00". Bila [requireGrouping] true hanya menerima
/// angka dengan pemisah ribuan (mengurangi false positive dari nomor struk).
Iterable<int> _numbersIn(String line, {bool requireGrouping = false}) sync* {
  // Bentuk berpemisah ribuan ("47.000", "1,234,567.00") ATAU bilangan bulat
  // polos ("47000", "1234567.00"). `\d+` dipisah agar rangkaian panjang tak
  // terpotong jadi 3 digit pertama saja.
  final pattern = requireGrouping
      ? RegExp(r'\d{1,3}(?:[.,\s]\d{3})+(?:[.,]\d{2})?')
      : RegExp(r'\d{1,3}(?:[.,\s]\d{3})+(?:[.,]\d{2})?|\d+(?:[.,]\d{2})?');
  for (final match in pattern.allMatches(line)) {
    final raw = match.group(0)!;
    final parsed = _normalizeAmount(raw);
    if (parsed != null && parsed > 0) yield parsed;
  }
}

/// "50.000,00" / "50,000.00" / "50.000" → 50000 (Rupiah bulat, tanpa sen).
int? _normalizeAmount(String raw) {
  var s = raw.replaceAll(RegExp(r'\s'), '');
  // Rupiah tak berdesimal. Anggap 2 digit terakhir sebagai sen HANYA bila
  // kedua pemisah muncul ("1.234.567,89" / "1,234,567.89") — jelas notasi
  // desimal. Untuk "4,50" (OCR menelan digit "4.500") jangan dipangkas jadi
  // "4"; perlakukan pemisahnya sebagai ribuan.
  if (s.contains('.') && s.contains(',')) {
    s = s.replaceFirst(RegExp(r'[.,]\d{2}$'), '');
  }
  s = s.replaceAll(RegExp(r'[.,]'), '');
  if (s.isEmpty) return null;
  return int.tryParse(s);
}

DateTime? _findDate(String text) {
  // yyyy-mm-dd (ISO) diperiksa lebih dulu agar tidak salah dibaca sebagai
  // dd-mm-yy oleh pola di bawahnya. Pemisah dibatasi "-" / "/" (bukan ".")
  // supaya string versi seperti "V.2017.4.1" tak dikira tanggal. `\s*`
  // menoleransi spasi sisipan OCR ("19-05- 2017").
  final ymd = RegExp(
    r'(?<!\d)(\d{4})\s*[/\-]\s*(\d{1,2})\s*[/\-]\s*(\d{1,2})(?!\d)',
  );
  for (final m in ymd.allMatches(text)) {
    final d = _validDate(
      int.parse(m.group(1)!),
      int.parse(m.group(2)!),
      int.parse(m.group(3)!),
    );
    if (d != null) return d;
  }
  // dd/mm/yyyy · dd-mm-yy · dd.mm.yyyy (urutan hari-bulan, umum di ID/MY).
  final dmy = RegExp(
    r'(?<!\d)(\d{1,2})\s*[/\-.]\s*(\d{1,2})\s*[/\-.]\s*(\d{2,4})(?!\d)',
  );
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

/// Kata kunci baris yang jelas bukan nama toko.
const _merchantLineBlocklist = <String>[
  'struk',
  'receipt',
  'invoice',
  'npwp',
  'kasir',
  'cashier',
  'kassa',
  'telp',
  'telepon',
  'phone',
  'www',
  'http',
  'terima kasih',
  'thank',
  'nota',
  'faktur',
];

final _streetPrefix = RegExp(
  r'^(jl|jln|jalan|j1|gg|gang|blok|kav|ruko|rukan|perum|perumahan|'
  r'komp|komplek|kompleks|kel|kec|desa|rt|rw)[.\s]',
);

/// Baris yang diawali penanda jalan/lokasi — sering di-OCR sebagai "J1."
/// (angka satu) alih-alih "Jl.", jadi dicek longgar.
bool _isStreetLine(String line) => _streetPrefix.hasMatch(
  line.toLowerCase().replaceAll(RegExp(r'^[^a-z0-9]+'), ''),
);

/// Baris beralamat — penanda jalan ATAU pola "no. rumah, kota". Aturan koma
/// dipakai HANYA untuk memilih nama toko (bukan untuk logika nominal, agar
/// "4,500 4,500" tak salah dikira alamat).
bool _looksLikeAddress(String line) {
  if (_isStreetLine(line)) return true;
  final l = line.toLowerCase();
  return RegExp(r'\d').hasMatch(l) && l.contains(',');
}

String? _findMerchant(List<String> lines) {
  for (final line in lines.take(8)) {
    final letters = line.replaceAll(RegExp(r'[^A-Za-z]'), '');
    if (letters.length < 3) continue;
    // Harus didominasi huruf — singkirkan barcode / nomor struk / tanggal.
    final compact = line.replaceAll(RegExp(r'\s'), '');
    if (letters.length * 2 < compact.length) continue;
    final lower = line.toLowerCase();
    if (_merchantLineBlocklist.any(lower.contains)) continue;
    if (_looksLikeAddress(line)) continue;
    if (RegExp(r'\d{1,2}[:/.\-]\d{2}').hasMatch(line)) continue; // jam/tanggal
    // Rapikan spasi ganda, batasi panjang agar layak jadi keterangan.
    final cleaned = line.replaceAll(RegExp(r'\s+'), ' ').trim();
    return cleaned.length > 40 ? cleaned.substring(0, 40).trim() : cleaned;
  }
  return null;
}
