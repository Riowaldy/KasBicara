import 'dart:math' as math;

/// Sepotong teks hasil OCR beserta posisi kotak batasnya (koordinat piksel
/// gambar). Sengaja lepas dari tipe ML Kit agar [assembleReceiptText] bisa
/// diuji unit tanpa plugin.
class TextFragment {
  const TextFragment({
    required this.text,
    required this.top,
    required this.bottom,
    required this.left,
  });

  final String text;
  final double top;
  final double bottom;
  final double left;
}

/// Susun ulang potongan-potongan OCR menjadi teks berbaris sesuai TATA LETAK
/// visual struk, bukan sekadar urutan blok ML Kit.
///
/// ML Kit memberi tiap baris beserta kotak batasnya, tapi `recognized.text`
/// membuang geometri itu sehingga kolom kiri (label: "Total", "Bayar") dan
/// kolom kanan (nominal) bisa terpencar jauh. Di sini potongan yang rentang
/// vertikalnya bertumpang tindih digabung jadi satu baris (diurut kiri→kanan),
/// lalu baris-baris diurut atas→bawah. Hasilnya `Total   55.745` kembali utuh
/// dalam satu baris — jauh lebih mudah diparser.
String assembleReceiptText(Iterable<TextFragment> input) {
  final frags = input.where((f) => f.text.trim().isNotEmpty).toList()
    ..sort((a, b) => a.top.compareTo(b.top));
  if (frags.isEmpty) return '';

  final rows = <_Row>[];
  for (final f in frags) {
    _Row? best;
    var bestOverlap = 0.0;
    for (final row in rows) {
      final overlap = math.min(row.bottom, f.bottom) - math.max(row.top, f.top);
      final minHeight = math.min(row.bottom - row.top, f.bottom - f.top);
      final norm = minHeight <= 0 ? 1.0 : minHeight;
      // Baris yang sama bila tumpang tindih vertikal > 30% tinggi baris
      // terpendek — toleran terhadap struk yang miring/kusut.
      if (overlap > 0.3 * norm && overlap > bestOverlap) {
        best = row;
        bestOverlap = overlap;
      }
    }
    if (best == null) {
      rows.add(_Row(f));
    } else {
      best.add(f);
    }
  }

  rows.sort((a, b) => a.top.compareTo(b.top));
  return rows.map((r) => r.render()).join('\n');
}

class _Row {
  _Row(TextFragment first)
    : _frags = [first],
      top = first.top,
      bottom = first.bottom;

  final List<TextFragment> _frags;
  double top;
  double bottom;

  void add(TextFragment f) {
    _frags.add(f);
    if (f.top < top) top = f.top;
    if (f.bottom > bottom) bottom = f.bottom;
  }

  String render() {
    final ordered = [..._frags]..sort((a, b) => a.left.compareTo(b.left));
    return ordered
        .map((f) => f.text.trim())
        .where((t) => t.isNotEmpty)
        .join('  ');
  }
}
