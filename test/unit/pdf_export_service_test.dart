import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/data/models/category_model.dart';
import 'package:kasbicara/data/models/transaction_model.dart';
import 'package:kasbicara/data/models/transaction_type.dart';
import 'package:kasbicara/features/export/application/export_data.dart';
import 'package:kasbicara/features/export/application/pdf_export_service.dart';

void main() {
  const makanan = Category(
    id: 'expense-makanan-minuman',
    name: 'Makanan & Minuman',
    type: TransactionType.keluar,
    icon: 'food',
    isDefault: true,
  );

  ExportData buildData({List<Transaction> transactions = const []}) {
    return ExportData(
      transactions: transactions,
      categoriesById: {'expense-makanan-minuman': makanan},
      periodLabel: 'Agustus 2026',
    );
  }

  test(
    'menghasilkan bytes PDF valid (header %PDF) untuk data terisi',
    () async {
      final date = DateTime(2026, 8, 8);
      final data = buildData(
        transactions: [
          Transaction(
            id: 't1',
            type: TransactionType.keluar,
            amount: 50000,
            category: 'expense-makanan-minuman',
            note: 'Makan siang',
            date: date,
            createdAt: date,
            updatedAt: date,
          ),
        ],
      );

      final bytes = await buildPdfBytes(data);

      expect(bytes, isNotEmpty);
      // File PDF selalu diawali magic header "%PDF".
      expect(ascii.decode(bytes.sublist(0, 4)), '%PDF');
    },
  );

  test('tetap menghasilkan PDF valid walau tidak ada transaksi', () async {
    final bytes = await buildPdfBytes(buildData());

    expect(bytes, isNotEmpty);
    expect(ascii.decode(bytes.sublist(0, 4)), '%PDF');
  });
}
