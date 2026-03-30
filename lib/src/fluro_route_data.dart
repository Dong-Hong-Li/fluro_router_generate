import 'package:flutter/widgets.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/fluro_handler.dart';

/// A route that is added to the router tree.
class FluroRouteData {
  FluroRouteData(
    this.route,
    this.handler, {
    this.transitionType,
    this.transitionDuration,
    this.transitionCurve,
    this.transitionBuilder,
    this.opaque,
    this.disableSwipeBack = false,
  });

  /// 路由路径
  String route;

  /// 路由处理器
  dynamic handler;

  /// 过渡类型
  TransitionType? transitionType;
  Duration? transitionDuration;

  /// 过渡动画曲线
  Curve? transitionCurve;

  /// 过渡动画构建器
  RouteTransitionsBuilder? transitionBuilder;

  /// 是否透明
  bool? opaque;

  /// 是否禁用侧滑返回包装
  bool disableSwipeBack;
}

/// `RouteTreeNode` 表示路由树中的某一个节点 (路由片段)
class RouteTreeNode {
  RouteTreeNode(this.part, this.type);

  /// 节点的路径部分，例如 /home 或 :id。
  String part;

  /// 节点的类型，可以是普通节点或参数节点。
  RouteTreeNodeType? type;

  /// 父节点的引用。
  RouteTreeNode? parent;

  /// 与该节点关联的路由数据。
  var routes = <FluroRouteData>[];

  /// 子节点列表。
  var nodes = <RouteTreeNode>[];

  /// isParameter：一个布尔值，表示该节点是否是参数节点。
  bool get isParameter => type == RouteTreeNodeType.parameter;
}

///  `RouteConfiguration` 数据类，用于封装路由跳转相关配置参数。
class RouteConfiguration {
  /// 路由设置
  final RouteSettings? routeSettings;

  /// 路由参数
  final Map<String, List<String>> parameters;

  /// 是否保持状态
  final bool maintainState;

  /// 过渡类型
  final TransitionType? transition;

  /// 路由处理器
  final FluroHandler handler;

  /// 过渡动画时长
  final Duration? transitionDuration;

  /// 过渡动画曲线
  final Curve? transitionCurve;

  /// 过渡动画构建器
  final RouteTransitionsBuilder? transitionsBuilder;

  /// 路由数据
  final FluroRouteData? route;

  /// 是否不透明
  final bool? opaque;

  /// 是否禁用侧滑返回包装（SwipeBackWrapper）
  final bool disableSwipeBack;

  RouteConfiguration({
    this.routeSettings,
    required this.parameters,
    this.transition,
    required this.maintainState,
    required this.handler,
    this.transitionDuration,
    this.transitionCurve,
    this.transitionsBuilder,
    this.route,
    this.opaque,
    this.disableSwipeBack = false,
  });
}
