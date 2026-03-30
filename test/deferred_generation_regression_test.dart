import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'example generated feature module contains deferred import and loader',
    () {
      final path = p.join(
        Directory.current.path,
        'example',
        'lib',
        'router',
        'router_config_feature.router.g.dart',
      );
      final content = File(path).readAsStringSync();

      expect(content, contains('deferred as deferred_search_feature_'));
      expect(content, contains('DeferredRoutePage('));
      expect(content, contains('.loadLibrary()'));
      expect(content, contains("'/user/:userId/post/:postId'"));
    },
  );

  test('example main generated file still merges split modules', () {
    final path = p.join(
      Directory.current.path,
      'example',
      'lib',
      'router',
      'router_config.router.g.dart',
    );
    final content = File(path).readAsStringSync();

    expect(content, contains('...part_demo.routeHandlersDemo'));
    expect(content, contains('...part_feature.routeHandlersFeature'));
    expect(content, contains('...part_main.routeHandlersMain'));
  });
}
