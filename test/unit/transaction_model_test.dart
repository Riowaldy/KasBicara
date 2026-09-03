import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/models/pocket_model.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';

void main() {
  Transaction buildTransaction({
    String id = 't1',
    TransactionType type = TransactionType.keluar,
    int amount = 50000,
    String category = 'expense-makanan-minuman',
    String? note = 'Makan siang',
  }) {
    final now = DateTime(2026, 8, 8, 10, 30);
    return Transaction(
      id: id,
      type: type,
      amount: amount,
      category: category,
      note: note,
      date: DateTime(2026, 8, 8),
      createdAt: now,
      updatedAt: now,
    );
  }

  group('Transaction.toMap / fromMap', () {
    test('round-trip mempertahankan semua field', () {
      final original = buildTransaction();
      final restored = Transaction.fromMap(original.toMap());

      expect(restored, original);
    });

    test('date diserialisasi sebagai string YYYY-MM-DD', () {
      final map = buildTransaction().toMap();
      expect(map['date'], '2026-08-08');
    });

    test('note null tetap null setelah round-trip', () {
      final original = buildTransaction(note: null);
      final restored = Transaction.fromMap(original.toMap());
      expect(restored.note, isNull);
    });

    test('baris pra-migrasi tanpa pocket_id di-backfill ke Pocket Utama '
        '(konsep §04 / FR-P7)', () {
      final map = buildTransaction().toMap()..remove('pocket_id');
      expect(Transaction.fromMap(map).pocketId, kMainPocketId);
    });

    test('pocket_id bertahan lewat round-trip', () {
      final original = buildTransaction().copyWith(pocketId: 'kas-warung');
      expect(Transaction.fromMap(original.toMap()).pocketId, 'kas-warung');
    });
  });

  group('Transaction.validate', () {
    test('lolos untuk amount > 0 dan kategori terisi', () {
      expect(() => buildTransaction(amount: 1).validate(), returnsNormally);
    });

    test('menolak amount 0', () {
      expect(() => buildTransaction(amount: 0).validate(), throwsArgumentError);
    });

    test('menolak amount negatif', () {
      expect(
        () => buildTransaction(amount: -1000).validate(),
        throwsArgumentError,
      );
    });

    test('menolak kategori kosong', () {
      expect(
        () => buildTransaction(category: '  ').validate(),
        throwsArgumentError,
      );
    });
  });

  group('Transaction.copyWith', () {
    test('mengganti field yang diberikan, mempertahankan sisanya', () {
      final original = buildTransaction();
      final updated = original.copyWith(
        amount: 75000,
        category: 'expense-lainnya',
      );

      expect(updated.amount, 75000);
      expect(updated.category, 'expense-lainnya');
      expect(updated.id, original.id);
      expect(updated.note, original.note);
    });

    test('bisa menghapus note eksplisit ke null', () {
      final original = buildTransaction(note: 'ada catatan');
      final updated = original.copyWith(note: null);

      expect(updated.note, isNull);
    });
  });
}
