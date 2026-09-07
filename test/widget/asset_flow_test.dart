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

  testWidgets('buat aset baru -> muncul di selector -> dipakai di form', (
    tester,
  ) async {
    await pumpApp(tester);

    // Chip-selector default: "Semua Aset" + "Aset Utama".
    expect(find.text('Semua Aset'), findsWidgets);
    expect(find.text('Aset Utama'), findsWidgets);

    // Buka Kelola Aset lewat chip terakhir di selector.
    await tester.tap(find.widgetWithText(ActionChip, 'Kelola Aset'));
    await tester.pumpAndSettle();
    expect(find.text('Kelola Aset'), findsWidgets);

    // Tambah aset "Dana Darurat".
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Dana Darurat');
    await tester.tap(find.widgetWithText(TextButton, 'Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Dana Darurat'), findsOneWidget);

    // Kembali ke Dashboard: chip aset baru tersedia di selector.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Dana Darurat'), findsOneWidget);

    // Pilih aset itu, lalu buka form manual — dropdown aset ikut terisi.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dana Darurat'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('dashboard-add-fab')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('add-manual')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('asset-dropdown')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('asset-dropdown')),
        matching: find.text('Dana Darurat'),
      ),
      findsOneWidget,
    );
  });
}
