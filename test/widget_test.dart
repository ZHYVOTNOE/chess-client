// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:client/main.dart';
import 'package:client/core/navigation/auth_refresh_listenable.dart';
import 'package:client/features/auth/domain/auth_provider.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Create mock auth provider and refresh listenable
    final authProvider = AuthProvider();
    final authRefreshListenable = AuthRefreshListenable(authProvider);

    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(authRefreshListenable: authRefreshListenable));

    // Verify app builds without errors
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
