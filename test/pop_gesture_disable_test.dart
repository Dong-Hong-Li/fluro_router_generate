import 'package:fluro_router_generate/fluro_router.dart';
import 'package:fluro_router_generate/src/strategy/route_strategy.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

FluroHandler _dummyHandler() =>
    FluroHandler(handlerFunc: (_, __) => const Scaffold(body: SizedBox()));

void main() {
  group('disableSwipeBack and popGestureEnabled', () {
    testWidgets(
      'NativeRouteStrategy: disableSwipeBack true -> popGestureEnabled false after push',
      (tester) async {
        PageRoute<dynamic>? pushed;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  final config = RouteConfiguration(
                    routeSettings: const RouteSettings(name: '/child'),
                    parameters: {},
                    transition: TransitionType.native,
                    maintainState: true,
                    handler: _dummyHandler(),
                    disableSwipeBack: true,
                  );
                  pushed = NativeRouteStrategy().createRoute(config);
                  Navigator.of(context).push(pushed!);
                },
                child: const Text('go'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        expect(pushed, isNotNull);
        expect(pushed!.popGestureEnabled, isFalse);
      },
    );

    testWidgets(
      'NativeRouteStrategy: disableSwipeBack false -> popGestureEnabled true when stack allows',
      (tester) async {
        PageRoute<dynamic>? pushed;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  final config = RouteConfiguration(
                    routeSettings: const RouteSettings(name: '/child'),
                    parameters: {},
                    transition: TransitionType.native,
                    maintainState: true,
                    handler: _dummyHandler(),
                    disableSwipeBack: false,
                  );
                  pushed = NativeRouteStrategy().createRoute(config);
                  Navigator.of(context).push(pushed!);
                },
                child: const Text('go'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        expect(pushed, isNotNull);
        expect(pushed!.popGestureEnabled, isTrue);
      },
    );

    testWidgets(
      'CupertinoRouteStrategy: disableSwipeBack true -> popGestureEnabled false',
      (tester) async {
        PageRoute<dynamic>? pushed;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  final config = RouteConfiguration(
                    routeSettings: const RouteSettings(name: '/c'),
                    parameters: {},
                    transition: TransitionType.cupertino,
                    maintainState: true,
                    handler: _dummyHandler(),
                    disableSwipeBack: true,
                  );
                  pushed = CupertinoRouteStrategy().createRoute(config);
                  Navigator.of(context).push(pushed!);
                },
                child: const Text('go'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        expect(pushed!.popGestureEnabled, isFalse);
      },
    );

    testWidgets(
      'SimpleTransitionStrategy inFromLeft: disableSwipeBack true -> popGestureEnabled false',
      (tester) async {
        PageRoute<dynamic>? pushed;
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  final config = RouteConfiguration(
                    routeSettings: const RouteSettings(name: '/s'),
                    parameters: {},
                    transition: TransitionType.inFromLeft,
                    maintainState: true,
                    handler: _dummyHandler(),
                    disableSwipeBack: true,
                  );
                  pushed = SimpleTransitionStrategy(
                    TransitionEffect.inFromLeftTransitionWithCurve(
                      Curves.easeInOut,
                      disableSwipeBack: true,
                    ),
                  ).createRoute(config);
                  Navigator.of(context).push(pushed!);
                },
                child: const Text('go'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        expect(pushed!.popGestureEnabled, isFalse);
      },
    );

    testWidgets(
      'FluroRouter.navigateTo forwards disableSwipeBack to matched route',
      (tester) async {
        final router = FluroRouter();
        router.define(
          '/nav-swipe',
          handler: FluroHandler(
            handlerFunc: (_, __) =>
                const Scaffold(body: Text('nav-swipe-body')),
          ),
          transitionType: TransitionType.inFromLeft,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  router.navigateTo<void>(
                    context,
                    '/nav-swipe',
                    transition: TransitionType.inFromLeft,
                    disableSwipeBack: true,
                  );
                },
                child: const Text('go'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('go'));
        await tester.pumpAndSettle();
        final route =
            ModalRoute.of(tester.element(find.text('nav-swipe-body')))!
                as PageRoute<dynamic>;
        expect(route.popGestureEnabled, isFalse);
      },
    );

    testWidgets(
      'FluroConfig.push forwards disableSwipeBack true (must not be hardcoded in fluro_config)',
      (tester) async {
        FluroConfig.router.define(
          '/_ut_fluro_cfg_sw_true',
          handler: FluroHandler(
            handlerFunc: (_, __) =>
                const Scaffold(body: Text('body-fluro-cfg-true')),
          ),
          transitionType: TransitionType.inFromLeft,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  FluroConfig.push<void>(
                    '/_ut_fluro_cfg_sw_true',
                    context: context,
                    transition: TransitionType.inFromLeft,
                    disableSwipeBack: true,
                  );
                },
                child: const Text('tap-fluro-cfg-true'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('tap-fluro-cfg-true'));
        await tester.pumpAndSettle();
        final route =
            ModalRoute.of(tester.element(find.text('body-fluro-cfg-true')))!
                as PageRoute<dynamic>;
        expect(route.popGestureEnabled, isFalse);
      },
    );

    testWidgets(
      'FluroConfig.push forwards disableSwipeBack false (regression: no forced disable)',
      (tester) async {
        FluroConfig.router.define(
          '/_ut_fluro_cfg_sw_false',
          handler: FluroHandler(
            handlerFunc: (_, __) =>
                const Scaffold(body: Text('body-fluro-cfg-false')),
          ),
          transitionType: TransitionType.inFromLeft,
        );
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () {
                  FluroConfig.push<void>(
                    '/_ut_fluro_cfg_sw_false',
                    context: context,
                    transition: TransitionType.inFromLeft,
                    disableSwipeBack: false,
                  );
                },
                child: const Text('tap-fluro-cfg-false'),
              ),
            ),
          ),
        );
        await tester.tap(find.text('tap-fluro-cfg-false'));
        await tester.pumpAndSettle();
        final route =
            ModalRoute.of(tester.element(find.text('body-fluro-cfg-false')))!
                as PageRoute<dynamic>;
        expect(route.popGestureEnabled, isTrue);
      },
    );
  });
}
