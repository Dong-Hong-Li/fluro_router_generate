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

extension RouteConfigX on RouteConfig {
  /// 由 fluro_router_generate 生成的 RouterHandler 列表。
  List<RouterHandler> get generatedHandlers => [
    /// 详情页
    RouterHandler('/detail/:id', FluroHandler(handlerFunc: (context, parameters) => DetailPage(id: parameters['id']?.first ?? '0'))),

    /// 首页
    RouterHandler('/home/:id', FluroHandler(handlerFunc: (context, parameters) => HomePage(id: parameters['id']?.first ?? '-'))),
  ];

  /// 注册生成的路由到 [FluroConfig.router]，
  void initAllHandlers() {
    for (final h in generatedHandlers) {
      FluroConfig.router.define(h.path, handler: h.handler);
    }
  }
}
