import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/core/language/language_providers.dart';
import 'package:kasbicara/data/datasources/default_assets.dart';
import 'package:kasbicara/data/datasources/default_categories.dart';
import 'package:kasbicara/data/providers.dart';
import 'package:kasbicara/main.dart';

import '../fakes/fake_asset_repository.dart';
import '../fakes/fake_category_repository.dart';
import '../fakes/fake_transaction_repository.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // Pin bahasa ke Indonesia (host test memakai locale en-US, yang
          // kini otomatis memilih English — lihat activeLanguageProvider).
          deviceLocaleProvider.overrideWithValue(const Locale('id')),
          transactionRepositoryProvider.overrideWith(
            (ref) async => FakeTransactionRepository(),
          ),
          categoryRepositoryProvider.overrideWith(
            (ref) async => FakeCategoryRepository(defaultCategories),
          ),
          assetRepositoryProvider.overrideWith(
            (ref) async => FakeAssetRepository(defaultAssets),
          ),
        ],
        child: const KasBicaraApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('tambah manual -> tampil di riwayat -> edit -> hapus', (
    tester,
  ) async {
    await pumpApp(tester);

    // 1. Tambah transaksi manual via FAB Dashboard (default jenis: Keluar).
    await tester.tap(find.byKey(const Key('dashboard-add-fab')));
    await tester.pumpAndSettle();
    // Buka tab "Isi manual" pada carousel (default: Lewat suara).
    await tester.tap(find.byKey(const Key('add-tab-manual')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-manual')));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount-field')), '50000');
    await tester.tap(find.byKey(const Key('category-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Makanan & Minuman').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    // Kembali ke Dashboard; saldo & transaksi terakhir mencerminkan tx keluar.
    expect(find.textContaining('50.000'), findsWidgets);

    // 2. Pindah ke tab Riwayat, transaksi baru harus tampil.
    await tester.tap(find.text('Riwayat'));
    await tester.pumpAndSettle();

    expect(find.text('Makanan & Minuman'), findsOneWidget);
    expect(find.textContaining('Rp50.000'), findsOneWidget);

    // 3. Edit transaksi — ubah jumlah jadi 75.000.
    await tester.tap(find.text('Makanan & Minuman'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amount-field')), '75000');
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Rp75.000'), findsOneWidget);
    expect(find.textContaining('Rp50.000'), findsNothing);

    // 4. Hapus transaksi via swipe + konfirmasi dialog.
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Hapus transaksi?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Hapus'));
    await tester.pumpAndSettle();

    expect(find.text('Belum ada transaksi'), findsOneWidget);
  });
}
