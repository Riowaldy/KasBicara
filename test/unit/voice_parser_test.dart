import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/core/voice/id_voice_parser.dart';
import 'package:kasbicara/data/models/transaction_type.dart';

void main() {
  const parser = IdVoiceParser();

  group('Pola umum FR-2: [jenis] [jumlah] untuk/buat [keterangan]', () {
    test('keluar + angka kata + untuk + keterangan', () {
      final r = parser.parse('keluar lima puluh ribu untuk makan siang');
      expect(r.type, TransactionType.keluar);
      expect(r.amount, 50000);
      expect(r.amountConfident, isTrue);
      expect(r.note, 'makan siang');
      expect(r.category, 'expense-makanan-minuman');
    });

    test('masuk + angka kata + dari + keterangan (tanpa "untuk")', () {
      final r = parser.parse('masuk dua ratus ribu dari gaji');
      expect(r.type, TransactionType.masuk);
      expect(r.amount, 200000);
      expect(r.amountConfident, isTrue);
      expect(r.note, 'dari gaji');
      expect(r.category, 'income-gaji');
    });

    test('bayar (sinonim keluar) + buat + keterangan', () {
      final r = parser.parse('bayar tiga puluh ribu buat bensin');
      expect(r.type, TransactionType.keluar);
      expect(r.amount, 30000);
      expect(r.note, 'bensin');
      expect(r.category, 'expense-transportasi');
    });

    test('terima (sinonim masuk) + angka digit', () {
      final r = parser.parse('terima 150000 dari transfer teman');
      expect(r.type, TransactionType.masuk);
      expect(r.amount, 150000);
      expect(r.amountConfident, isTrue);
    });
  });

  group('Angka kata kompleks', () {
    test('dua juta lima ratus ribu', () {
      final r = parser.parse('keluar dua juta lima ratus ribu untuk sewa');
      expect(r.amount, 2500000);
    });

    test('seratus lima puluh ribu', () {
      final r = parser.parse('keluar seratus lima puluh ribu untuk belanja');
      expect(r.amount, 150000);
    });

    test('dua belas ribu', () {
      final r = parser.parse('keluar dua belas ribu untuk parkir');
      expect(r.amount, 12000);
    });

    test('sebelas ribu (kata fusi)', () {
      final r = parser.parse('keluar sebelas ribu untuk parkir');
      expect(r.amount, 11000);
    });

    test('seribu lima ratus', () {
      final r = parser.parse('keluar seribu lima ratus untuk parkir');
      expect(r.amount, 1500);
    });

    test('sejuta (kata fusi juta)', () {
      final r = parser.parse('masuk sejuta dari bonus');
      expect(r.amount, 1000000);
    });
  });

  group('Format angka digit & singkatan', () {
    test('angka berformat titik ribuan "50.000"', () {
      final r = parser.parse('keluar 50.000 untuk makan');
      expect(r.amount, 50000);
    });

    test('angka berformat titik jutaan "2.500.000"', () {
      final r = parser.parse('masuk 2.500.000 dari gaji');
      expect(r.amount, 2500000);
    });

    test('singkatan "rb" menempel ke digit', () {
      final r = parser.parse('keluar 50rb untuk jajan');
      expect(r.amount, 50000);
    });

    test('singkatan "jt" menempel ke digit', () {
      final r = parser.parse('masuk 2jt dari bonus');
      expect(r.amount, 2000000);
    });

    test('kata pengisi "rupiah"/"uang" tidak mengganggu parsing', () {
      final r = parser.parse(
        'keluar uang sebesar lima puluh ribu rupiah untuk makan',
      );
      expect(r.amount, 50000);
      expect(r.amountConfident, isTrue);
    });
  });

  group('Tanpa kata kunci jenis eksplisit', () {
    test('langsung angka di awal tetap ter-parse sebagai jumlah', () {
      final r = parser.parse('lima puluh ribu untuk makan siang');
      expect(r.type, isNull);
      expect(r.amount, 50000);
      expect(r.amountConfident, isTrue);
    });
  });

  group('Kasus ambigu / gagal parsing — TIDAK BOLEH MENEBAK (PRD §13)', () {
    test('tidak ada angka sama sekali -> amount null & tidak confident', () {
      final r = parser.parse('keluar untuk makan siang');
      expect(r.amount, isNull);
      expect(r.amountConfident, isFalse);
    });

    test('transkrip kosong -> semua field null', () {
      final r = parser.parse('');
      expect(r.type, isNull);
      expect(r.amount, isNull);
      expect(r.amountConfident, isFalse);
      expect(r.note, isNull);
    });

    test('hanya jenis tanpa angka maupun keterangan', () {
      final r = parser.parse('keluar');
      expect(r.amount, isNull);
      expect(r.amountConfident, isFalse);
      expect(r.note, isNull);
    });

    test('kategori tidak dikenali -> null, bukan tebakan sembarangan', () {
      final r = parser.parse('keluar lima puluh ribu untuk xyz123');
      expect(r.category, isNull);
    });
  });

  group('rawTranscript selalu tersimpan apa adanya', () {
    test('mempertahankan teks asli untuk ditampilkan sebagai referensi', () {
      const original = 'Keluar Lima Puluh Ribu untuk Makan Siang!';
      final r = parser.parse(original);
      expect(r.rawTranscript, original);
    });
  });
}
