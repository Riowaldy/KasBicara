import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kasbicara/core/language/language_providers.dart';
import 'package:kasbicara/data/datasources/default_categories.dart';
import 'package:kasbicara/data/datasources/default_pockets.dart';
import 'package:kasbicara/data/providers.dart';
import 'package:kasbicara/main.dart';

import 'fakes/fake_category_repository.dart';
import 'fakes/fake_pocket_repository.dart';
import 'fakes/fake_transaction_repository.dart';

void main() {
  testWidgets('App boots and shows bottom navigation with 3 tabs', (
    WidgetTester tester,
  ) async {
    // Override ke repository fake in-memory — Beranda mengonsumsi
    // balanceProvider yang butuh repository nyata (platform channel SQLCipher
    // tidak tersedia di widget test biasa), sama seperti pola di
    // transaction_flow_test.dart.
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
          pocketRepositoryProvider.overrideWith(
            (ref) async => FakePocketRepository(defaultPockets),
          ),
        ],
        child: const KasBicaraApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
