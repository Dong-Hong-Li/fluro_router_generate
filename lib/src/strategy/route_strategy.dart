import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/fluro_route_data.dart';
import 'package:fluro_router_generate/src/mixin_fluro_router_tools.dart';

/// 处理路由导航的路由策略
abstract class RouteStrategy {
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig);
}
////--------------------------- 为每种过渡类型创建具体aa的策略类 ---------------------------

/// 原生过渡策略
class NativeRouteStrategy implements RouteStrategy {
  @override
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig) {
    return MaterialPageRoute<dynamic>(
      settings: routeConfig.routeSettings,
      fullscreenDialog: routeConfig.transition == TransitionType.nativeModal,
      maintainState: routeConfig.maintainState,
      builder: (BuildContext context) {
        return routeConfig.handler.handlerFunc(
              context,
              routeConfig.parameters,
            ) ??
            const SizedBox.shrink();
      },
    );
  }
}

/// Material 过渡策略
class MaterialRouteStrategy implements RouteStrategy {
  @override
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig) {
    return MaterialPageRoute<dynamic>(
      settings: routeConfig.routeSettings,
      fullscreenDialog:
          routeConfig.transition == TransitionType.materialFullScreenDialog,
      maintainState: routeConfig.maintainState,
      builder: (BuildContext context) {
        return routeConfig.handler.handlerFunc(
              context,
              routeConfig.parameters,
            ) ??
            const SizedBox.shrink();
      },
    );
  }
}

/// Cupertino 过渡策略
class CupertinoRouteStrategy implements RouteStrategy {
  @override
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig) {
    return CupertinoPageRoute(
      settings: routeConfig.routeSettings,
      fullscreenDialog:
          routeConfig.transition == TransitionType.cupertinoFullScreenDialog,
      maintainState: routeConfig.maintainState,
      builder: (BuildContext context) {
        return routeConfig.handler.handlerFunc(
              context,
              routeConfig.parameters,
            ) ??
            const SizedBox.shrink();
      },
    );
  }
}

/// 自定义过渡策略
class CustomRouteStrategy implements RouteStrategy {
  @override
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig) {
    RouteTransitionsBuilder? routeTransitionsBuilder;

    routeTransitionsBuilder =
        routeConfig.transitionsBuilder ?? routeConfig.route?.transitionBuilder;

    return PageRouteBuilder<dynamic>(
      opaque: false,
      settings: routeConfig.routeSettings,
      maintainState: routeConfig.maintainState,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return routeConfig.handler.handlerFunc(
                  context,
                  routeConfig.parameters,
                ) ??
                const SizedBox.shrink();
          },

      ///指定页面过渡动画的持续时间
      transitionDuration: routeConfig.transition == TransitionType.none
          ? Duration.zero
          : (routeConfig.transitionDuration ??
                routeConfig.route?.transitionDuration ??
                FluroRouterTools.defaultTransitionDuration),

      /// 指定页面反向过渡动画的持续时间
      reverseTransitionDuration: routeConfig.transition == TransitionType.none
          ? Duration.zero
          : (routeConfig.transitionDuration ??
                routeConfig.route?.transitionDuration ??
                FluroRouterTools.defaultTransitionDuration),

      /// 构建过渡动画
      transitionsBuilder: routeConfig.transition == TransitionType.none
          ? (_, __, ___, child) => child
          : routeTransitionsBuilder!,
    );
  }
}

/// 用于支持手势返回,
///
///
/// 因为返回手势需要设置 opaque: false 以支持侧滑时露出下层页面
/// 页面内容需要自己设置背景色（如 Scaffold 的 backgroundColor）
class SimpleTransitionStrategy implements RouteStrategy {
  final RouteTransitionsBuilder transitionsBuilder;

  SimpleTransitionStrategy(this.transitionsBuilder);

  @override
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig) {
    return PageRouteBuilder<dynamic>(
      opaque: routeConfig.opaque ?? routeConfig.route?.opaque ?? false,
      settings: routeConfig.routeSettings,
      maintainState: routeConfig.maintainState,
      pageBuilder:
          (
            BuildContext context,
            Animation<double> animation,
            Animation<double> secondaryAnimation,
          ) {
            return routeConfig.handler.handlerFunc(
                  context,
                  routeConfig.parameters,
                ) ??
                const SizedBox.shrink();
          },
      transitionDuration:
          routeConfig.transitionDuration ??
          routeConfig.route?.transitionDuration ??
          FluroRouterTools.defaultTransitionDuration,
      reverseTransitionDuration:
          routeConfig.transitionDuration ??
          routeConfig.route?.transitionDuration ??
          FluroRouterTools.defaultTransitionDuration,
      transitionsBuilder: transitionsBuilder,
    );
  }
}
