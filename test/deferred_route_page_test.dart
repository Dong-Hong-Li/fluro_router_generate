import 'dart:async';

import 'package:fluro_router_generate/fluro_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('DeferredRoutePage loads and renders target widget', (
    tester,
  ) async {
    final completer = Completer<void>();
    await tester.pumpWidget(
      MaterialApp(
        home: DeferredRoutePage(
          loader: () => completer.future,
          builder: (_) => const Text('loaded-page'),
        ),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('loaded-page'), findsNothing);

    completer.complete();
    await tester.pumpAndSettle();

    expect(find.text('loaded-page'), findsOneWidget);
  });

  testWidgets('DeferredRoutePage supports errorBuilder', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DeferredRoutePage(
          loader: () => Future<void>.error(StateError('load failed')),
          builder: (_) => const SizedBox.shrink(),
          errorBuilder: (_, error, __) => Text(error.toString()),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining('load failed'), findsOneWidget);
  });
}
