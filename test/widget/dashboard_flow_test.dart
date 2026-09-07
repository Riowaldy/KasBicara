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

  testWidgets('Dashboard: saldo bersih, transaksi terakhir kosong, '
      'menu tambah 3 cara', (tester) async {
    await pumpApp(tester);

    // Dashboard adalah tab pertama & default.
    expect(find.text('Saldo Bersih'), findsOneWidget);
    expect(find.byKey(const Key('dashboard-net-balance')), findsOneWidget);
    expect(find.text('Transaksi Terakhir'), findsOneWidget);
    // Belum ada transaksi.
    expect(find.text('Belum ada transaksi'), findsOneWidget);

    // FAB membuka bottom sheet berisi carousel 3 cara; default "Lewat suara".
    await tester.tap(find.byKey(const Key('dashboard-add-fab')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-entry-pager')), findsOneWidget);
    expect(find.byKey(const Key('add-voice')), findsOneWidget);
    // Ketiga tab bernama langsung terlihat.
    expect(find.byKey(const Key('add-tab-voice')), findsOneWidget);
    expect(find.byKey(const Key('add-tab-manual')), findsOneWidget);
    expect(find.byKey(const Key('add-tab-scan')), findsOneWidget);

    // Ketuk tab membuka halaman terkait.
    await tester.tap(find.byKey(const Key('add-tab-manual')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-manual')), findsOneWidget);

    await tester.tap(find.byKey(const Key('add-tab-scan')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-scan')), findsOneWidget);
  });

  testWidgets('Dashboard: pilih "Isi manual" membuka form transaksi', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('dashboard-add-fab')));
    await tester.pumpAndSettle();
    // Buka tab "Isi manual" pada carousel (default: Lewat suara).
    await tester.tap(find.byKey(const Key('add-tab-manual')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-manual')));
    await tester.pumpAndSettle();

    expect(find.text('Tambah Transaksi'), findsOneWidget);
    expect(find.byKey(const Key('amount-field')), findsOneWidget);
  });

  testWidgets('Dashboard: transaksi tersimpan muncul di "Transaksi Terakhir"', (
    tester,
  ) async {
    await pumpApp(tester);

    // Tambah lewat FAB Dashboard -> lembar "Tambah Data" -> Isi manual.
    await tester.tap(find.byKey(const Key('dashboard-add-fab')));
    await tester.pumpAndSettle();
    // Buka tab "Isi manual" pada carousel (default: Lewat suara).
    await tester.tap(find.byKey(const Key('add-tab-manual')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-manual')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('amount-field')), '30000');
    await tester.tap(find.byKey(const Key('category-dropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Makanan & Minuman').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('save-button')));
    await tester.pumpAndSettle();

    // Form ditutup -> kembali ke Dashboard.
    expect(find.text('Belum ada transaksi'), findsNothing);
    expect(find.textContaining('Makanan & Minuman'), findsWidgets);
    // Muncul di kartu saldo bersih & baris transaksi terakhir.
    expect(find.textContaining('-Rp30.000'), findsWidgets);
  });
}
