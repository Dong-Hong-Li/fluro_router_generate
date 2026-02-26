import 'package:fluro_router_generate/src/utils/path_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('pathParamNames', () {
    test('returns empty for path without params', () {
      expect(pathParamNames('/home'), isEmpty);
      expect(pathParamNames('/'), isEmpty);
      expect(pathParamNames('/a/b/c'), isEmpty);
    });

    test('extracts single path param', () {
      expect(pathParamNames('/home/:id'), ['id']);
      expect(pathParamNames('/detail/:id'), ['id']);
    });

    test('extracts multiple path params', () {
      expect(
        pathParamNames('/user/:userId/post/:postId'),
        ['userId', 'postId'],
      );
      expect(pathParamNames('/a/:b/c/:d'), ['b', 'd']);
    });

    test('ignores query string when extracting path params', () {
      expect(pathParamNames('/home/:id?foo=1'), ['id']);
      expect(pathParamNames('/search?keyword=&page=1'), isEmpty);
    });
  });

  group('queryParamNames', () {
    test('returns empty for path without query', () {
      expect(queryParamNames('/home'), isEmpty);
      expect(queryParamNames('/detail/1'), isEmpty);
    });

    test('extracts single query param name', () {
      expect(queryParamNames('/search?keyword='), ['keyword']);
      expect(queryParamNames('/page?id=1'), ['id']);
    });

    test('extracts multiple query param names', () {
      expect(
        queryParamNames('/search?keyword=&page=1'),
        ['keyword', 'page'],
      );
      expect(
        queryParamNames('/api?a=1&b=2&c=3'),
        ['a', 'b', 'c'],
      );
    });

    test('ignores fragment', () {
      expect(
        queryParamNames('/path?k=v#hash'),
        ['k'],
      );
    });
  });
}
