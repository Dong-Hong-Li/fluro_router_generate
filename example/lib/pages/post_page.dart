import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router.dart';

/// 传参场景：多路径参数 (pathParams)
@RouterAnnotation(
  path: '/user/:userId/post/:postId',
  description: '帖子详情页（多路径参数）',
  module: 'feature',
  defaultParams: {'userId': '0'},
  constructorParams: HandlerConstructorParams.pathParams,
)
@RouterAnnotation(
  path: '/user2/:userId/post/:postId',
  description: '帖子详情页2（多路径参数）',
  module: 'demo',
  defaultParams: {'userId': '0'},
  constructorParams: HandlerConstructorParams.pathParams,
)
class PostPage extends StatelessWidget {
  const PostPage({super.key, required this.userId, required this.postId});
  final String userId;
  final String postId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('帖子 userId=$userId postId=$postId')),
      body: Center(child: Text('PostPage userId: $userId, postId: $postId')),
    );
  }
}
