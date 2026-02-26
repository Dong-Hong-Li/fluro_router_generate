import 'package:fluro_router_generate/fluro_router.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListExtension.firstWhereOrNull', () {
    test('returns first matching element', () {
      final list = [1, 2, 3, 4, 5];
      expect(list.firstWhereOrNull((e) => e > 3), 4);
    });

    test('returns null when no element matches', () {
      final list = [1, 2, 3];
      expect(list.firstWhereOrNull((e) => e > 10), isNull);
    });

    test('returns null for empty list', () {
      final list = <int>[];
      expect(list.firstWhereOrNull((e) => true), isNull);
    });
  });
}
