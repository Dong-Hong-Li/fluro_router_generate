import 'package:flutter/material.dart';
import 'package:fluro_router_generate/src/fluro_handler.dart';
import 'package:fluro_router_generate/src/fluro_route_data.dart';
import 'package:fluro_router_generate/src/strategy/route_strategy.dart';
import 'package:fluro_router_generate/src/strategy/route_strategy_factory.dart';

mixin FluroRouterTools {
  /// 过渡动画默认时长
  static const defaultTransitionDuration = Duration(milliseconds: 250);

  /// 过渡动画默认曲线
  static const Curve defaultTransitionCurve = Curves.easeInOut;

  /// 未找到路由的处理函数
  ///
  /// - `context`：上下文对象
  /// - `path`：路径
  /// - `notFoundHandler`：未找到路由的处理函数
  /// - `maintainState`：是否保持状态
  Route<void> notFoundRoute(
    BuildContext context,
    String path,
    FluroHandler notFoundHandler, {
    bool? maintainState,
  }) {
    return MaterialPageRoute<void>(
      settings: RouteSettings(name: path),
      maintainState: maintainState ?? true,
      builder: (BuildContext context) {
        return notFoundHandler.handlerFunc(context, {}) ??
            const SizedBox.shrink();
      },
    );
  }

  ///处理 `RouteSettings`
  ///
  ///- `routeSettings`：路由设置
  ///- `path`：路径
  RouteSettings settingsHandle(RouteSettings? routeSettings, String? path) =>
      (routeSettings?.name == null)
      ? RouteSettings(name: path)
      : routeSettings!;

  /// 路由生成方法。这个函数可以用来动态创建原生路由
  ///
  /// - `routeConfig`：封装着路由跳转相关配置
  PageRoute<dynamic> creatNativeRoute(RouteConfiguration routeConfig) {
    RouteStrategy strategy = RouteStrategyFactory.getStrategy(
      routeConfig.transition,
      curve: routeConfig.transitionCurve,
    );
    return strategy.createRoute(routeConfig);
  }
}
