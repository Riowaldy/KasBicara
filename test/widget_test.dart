import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kasbicara/main.dart';

void main() {
  testWidgets('App boots and shows bottom navigation with 3 tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: KasBicaraApp()));
    await tester.pumpAndSettle();

    expect(find.text('Beranda'), findsOneWidget);
    expect(find.text('Riwayat'), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.byIcon(Icons.mic), findsOneWidget);
  });
}
