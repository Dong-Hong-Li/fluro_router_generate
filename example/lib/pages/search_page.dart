import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router.dart';

/// 传参场景：查询参数 (queryParams)
@RouterAnnotation(
  path: '/search?keyword=&page=1',
  description: '搜索页（查询参数）',
  defaultParams: {'keyword': '', 'page': '1'},
  constructorParams: HandlerConstructorParams.queryParams,
)
class SearchPage extends StatelessWidget {
  const SearchPage({super.key, required this.keyword, required this.page});
  final String keyword;
  final String page;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('搜索: ${keyword.isEmpty ? "(空)" : keyword}')),
      body: Center(
        child: Text('SearchPage keyword=$keyword, page=$page'),
      ),
    );
  }
}
