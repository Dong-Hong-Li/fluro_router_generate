// GENERATED CODE - DO NOT MODIFY BY HAND
//
// **************************************************************************
// FluroRouterGenerator
// **************************************************************************
//
// GENERATED CODE - DO NOT MODIFY BY HAND
// 由 @EntranceAnnotation 在 RouteConfig 上生成

import 'package:example/router/router_config.dart';
import 'package:fluro_router_generate/fluro_router.dart';
import 'package:example/pages/detail_page.dart';
import 'package:example/pages/home_page.dart';
import 'package:example/pages/pass_args_no_defaults_page.dart';
import 'package:example/pages/pass_args_page.dart';
import 'package:example/pages/post_page.dart';
import 'package:example/pages/search_page.dart';

extension RouteConfigX on RouteConfig {
  /// 由 fluro_router_generate 生成的 RouterHandler 列表。
  List<RouterHandler> get generatedHandlers => [
    /// 详情页（单路径参数）
    RouterHandler('/detail/:id', FluroHandler(handlerFunc: (context, parameters) => DetailPage(id: parameters['id']?.first ?? '0'))),

    /// 首页（无参数）
    RouterHandler('/home', FluroHandler(handlerFunc: (context, parameters) => HomePage())),

    /// RouteSettings.arguments 传参（无 defaultParams，从构造函数推断）
    RouterHandler('/pass-args-no-defaults', FluroHandler(handlerFunc: (context, parameters) {
       final arguments = context?.arguments;
       final argsMap = arguments is Map<dynamic, dynamic> ? arguments : null;
       final message = argsMap?['message']?.toString() ?? '';
       final flag = argsMap?['flag']?.toString() ?? '';
       return PassArgsNoDefaultsPage(message: message, flag: flag);
    })),

    /// RouteSettings.arguments 传参（有 defaultParams）
    RouterHandler('/pass-args', FluroHandler(handlerFunc: (context, parameters) {
       final arguments = context?.arguments;
       final argsMap = arguments is Map<dynamic, dynamic> ? arguments : null;
       final title = argsMap?['title']?.toString() ?? '';
       final count = int.tryParse(argsMap?['count']?.toString() ?? '') ?? 0;
       return PassArgsPage(title: title, count: count);
    })),

    /// 帖子详情页（多路径参数）
    RouterHandler('/user/:userId/post/:postId', FluroHandler(handlerFunc: (context, parameters) => PostPage(userId: parameters['userId']?.first ?? '0', postId: parameters['postId']?.first ?? ''))),

    /// 搜索页（查询参数）
    RouterHandler('/search?keyword=&page=1', FluroHandler(handlerFunc: (context, parameters) => SearchPage(keyword: parameters['keyword']?.first ?? '', page: parameters['page']?.first ?? '1'))),
  ];

  /// 注册生成的路由到 [FluroConfig.router]，
  void initAllHandlers() {
    for (final h in generatedHandlers) {
      FluroConfig.router.define(h.path, handler: h.handler);
    }
  }
}
