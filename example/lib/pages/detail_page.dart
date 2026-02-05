import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router.dart';

/// 传参场景：单路径参数 (pathParams)
@RouterAnnotation(
  path: '/detail/:id',
  description: '详情页（单路径参数）',
  defaultParams: {'id': '0'},
  constructorParams: HandlerConstructorParams.pathParams,
)
class DetailPage extends StatelessWidget {
  const DetailPage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('详情 id=$id')),
      body: Center(child: Text('DetailPage id: $id')),
    );
  }
}
