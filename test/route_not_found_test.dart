import 'package:fluro_router_generate/fluro_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RouteNotFoundException', () {
    test('toString contains path and message', () {
      const path = '/unknown';
      const message = 'Not found';
      final e = RouteNotFoundException(message, path);
      expect(e.path, path);
      expect(e.message, message);
      expect(e.toString(), contains(path));
    });
  });
}
