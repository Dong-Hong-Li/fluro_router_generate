import 'package:fluro_router_generate/fluro_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FluroRouter pop stack', () {
    testWidgets('popToRoot leaves only first route', (tester) async {
      final router = FluroRouter();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                const Text('root'),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: '/a'),
                        builder: (_) => Builder(
                          builder: (inner) => TextButton(
                            onPressed: () {
                              Navigator.of(inner).push(
                                MaterialPageRoute<void>(
                                  settings: const RouteSettings(name: '/b'),
                                  builder: (_) => TextButton(
                                    onPressed: () =>
                                        router.popToRoot(inner),
                                    child: const Text('leaf'),
                                  ),
                                ),
                              );
                            },
                            child: const Text('mid'),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('mid'));
      await tester.pumpAndSettle();
      expect(find.text('leaf'), findsOneWidget);

      await tester.tap(find.text('leaf'));
      await tester.pumpAndSettle();

      expect(find.text('root'), findsOneWidget);
      expect(find.text('mid'), findsNothing);
      expect(find.text('leaf'), findsNothing);
    });

    testWidgets('popUntil stops at named route', (tester) async {
      final router = FluroRouter();
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Column(
              children: [
                const Text('root'),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        settings: const RouteSettings(name: '/stop'),
                        builder: (_) => Builder(
                          builder: (inner) => TextButton(
                            onPressed: () {
                              Navigator.of(inner).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => TextButton(
                                    onPressed: () => router.popUntil(
                                      inner,
                                      (route) =>
                                          route.settings.name == '/stop',
                                    ),
                                    child: const Text('leaf'),
                                  ),
                                ),
                              );
                            },
                            child: const Text('stop-layer'),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('open'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('stop-layer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('leaf'));
      await tester.pumpAndSettle();

      expect(find.text('stop-layer'), findsOneWidget);
      expect(find.text('leaf'), findsNothing);
    });
  });
}
