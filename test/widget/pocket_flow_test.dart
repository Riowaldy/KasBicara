import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/core/language/language_providers.dart';
import 'package:kasbicara/data/datasources/default_categories.dart';
import 'package:kasbicara/data/datasources/default_pockets.dart';
import 'package:kasbicara/data/providers.dart';
import 'package:kasbicara/main.dart';

import '../fakes/fake_category_repository.dart';
import '../fakes/fake_pocket_repository.dart';
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
          pocketRepositoryProvider.overrideWith(
            (ref) async => FakePocketRepository(defaultPockets),
          ),
        ],
        child: const KasBicaraApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('buat pocket baru -> muncul di selector -> dipakai di form', (
    tester,
  ) async {
    await pumpApp(tester);

    // Selector default menampilkan "Semua Pocket" + "Pocket Utama".
    expect(find.text('Semua Pocket'), findsOneWidget);
    expect(find.text('Pocket Utama'), findsWidgets);

    // Buka Kelola Pocket lewat ikon dompet di AppBar Beranda.
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(find.text('Kelola Pocket'), findsOneWidget);

    // Tambah pocket "Dana Darurat".
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), 'Dana Darurat');
    await tester.tap(find.widgetWithText(TextButton, 'Tambah'));
    await tester.pumpAndSettle();

    expect(find.text('Dana Darurat'), findsOneWidget);

    // Kembali ke Beranda: chip pocket baru tersedia di selector.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(ChoiceChip, 'Dana Darurat'), findsOneWidget);

    // Pilih pocket itu, lalu buka form manual — dropdown pocket ikut terisi.
    await tester.tap(find.widgetWithText(ChoiceChip, 'Dana Darurat'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tambah manual'));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pocket-dropdown')), findsOneWidget);
    expect(
      find.descendant(
        of: find.byKey(const Key('pocket-dropdown')),
        matching: find.text('Dana Darurat'),
      ),
      findsOneWidget,
    );
  });
}
