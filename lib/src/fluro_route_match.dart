import 'package:flutter/material.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/fluro_route_data.dart';

/// 表示路由匹配结果的结构体，主要用来描述在路由匹配过程中是否成功匹配到了一个路由，以及与路由匹配相关的其他信息。
///
/// ```dart
///
///  final match = RouteMatch(
///    matchType: RouteMatchType.match,   // 匹配成功
///    route: MaterialPageRoute(builder: (context) => HomePage()),  // 匹配的路由对象
///  );
///  print(match.matchType); // 输出：RouteMatchType.match
///  print(match.route.runtimeType); // 输出：MaterialPageRoute
///
///  final match = RouteMatch(
///    matchType: RouteMatchType.noMatch,  // 未匹配
///    errorMessage: "路由 '/unknown' 不存在。", // 自定义错误信息
///  );
///  print(match.matchType); // 输出：RouteMatchType.noMatch
///  print(match.errorMessage); // 输出：路由 '/unknown' 不存在。
///
/// ```
class FluroRouteMatch {
  FluroRouteMatch({
    this.matchType = RouteMatchType.noMatch,
    this.route,
    this.errorMessage = '',
  });

  /// 匹配成功的路由对象,如果没有匹配到路由，则该值为 null。
  final Route<dynamic>? route;

  /// 路由匹配的类型,[RouteMatchType.noMatch]，表示没有匹配到任何路由。
  final RouteMatchType matchType;

  /// 路由匹配失败时的错误信息。
  final String errorMessage;
}

/// `AppRouteMatchResult` 表示整个路由的匹配结果.
class AppRouteMatchResult {
  AppRouteMatchResult(this.route);

  FluroRouteData route;
  Map<String, List<String>> parameters = <String, List<String>>{};
}

///`RouteTreeNodeMatch` 表示一段路由片段的匹配结果.
/// - `node`：匹配的节点
/// - `parameters`：保存匹配的参数
/// - [RouteTreeNodeMatch.fromMatch]：创建一个新的匹配结果对象，并继承已有的参数。
class RouteTreeNodeMatch {
  RouteTreeNodeMatch._();

  factory RouteTreeNodeMatch() => RouteTreeNodeMatch._();

  late RouteTreeNode node;

  Map<String, List<String>> parameters = <String, List<String>>{};

  RouteTreeNodeMatch.fromMatch(this.parameters, this.node);
}
