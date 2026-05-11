import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/fluro_route_data.dart';
import 'package:fluro_router_generate/src/mixin_fluro_router_tools.dart';

/// [disableSwipeBack] 为 true 时，除不包 [SwipeBackWrapper] 外，关闭
/// [ModalRoute.popGestureEnabled]，以禁用 iOS 上 [MaterialPageRoute] /
/// [CupertinoPageRoute] 自带的左缘返回（与 [SwipeBackWrapper] 不是同一套手势）。
class _NoPopGestureMaterialPageRoute<T> extends MaterialPageRoute<T> {
  _NoPopGestureMaterialPageRoute({
    required super.builder,
    super.settings,
    super.requestFocus,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
    super.traversalEdgeBehavior,
    super.directionalTraversalEdgeBehavior,
  });

  @override
  bool get popGestureEnabled => false;
}

class _NoPopGestureCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  _NoPopGestureCupertinoPageRoute({
    required super.builder,
    super.title,
    super.settings,
    super.requestFocus,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
    super.barrierDismissible,
  });

  @override
  bool get popGestureEnabled => false;
}

class _NoPopGesturePageRouteBuilder<T> extends PageRouteBuilder<T> {
  _NoPopGesturePageRouteBuilder({
    super.settings,
    super.requestFocus,
    required super.pageBuilder,
    super.transitionsBuilder,
    super.transitionDuration,
    super.reverseTransitionDuration,
    super.opaque,
    super.barrierDismissible,
    super.barrierColor,
    super.barrierLabel,
    super.maintainState,
    super.fullscreenDialog,
    super.allowSnapshotting,
  });

  @override
  bool get popGestureEnabled => false;
}

/// 处理路由导航的路由策略
abstract class RouteStrategy {
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig);
}
////--------------------------- 为每种过渡类型创建具体aa的策略类 ---------------------------

/// 原生过渡策略
class NativeRouteStrategy implements RouteStrategy {
  @override
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig) {
    final builder = (BuildContext context) {
      return routeConfig.handler.handlerFunc(
            context,
            routeConfig.parameters,
          ) ??
          const SizedBox.shrink();
    };
    if (routeConfig.disableSwipeBack) {
      return _NoPopGestureMaterialPageRoute<dynamic>(
        settings: routeConfig.routeSettings,
        fullscreenDialog: routeConfig.transition == TransitionType.nativeModal,
        maintainState: routeConfig.maintainState,
        builder: builder,
      );
    }
    return MaterialPageRoute<dynamic>(
      settings: routeConfig.routeSettings,
      fullscreenDialog: routeConfig.transition == TransitionType.nativeModal,
      maintainState: routeConfig.maintainState,
      builder: builder,
    );
  }
}

/// Material 过渡策略
class MaterialRouteStrategy implements RouteStrategy {
  @override
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig) {
    final builder = (BuildContext context) {
      return routeConfig.handler.handlerFunc(
            context,
            routeConfig.parameters,
          ) ??
          const SizedBox.shrink();
    };
    if (routeConfig.disableSwipeBack) {
      return _NoPopGestureMaterialPageRoute<dynamic>(
        settings: routeConfig.routeSettings,
        fullscreenDialog:
            routeConfig.transition == TransitionType.materialFullScreenDialog,
        maintainState: routeConfig.maintainState,
        builder: builder,
      );
    }
    return MaterialPageRoute<dynamic>(
      settings: routeConfig.routeSettings,
      fullscreenDialog:
          routeConfig.transition == TransitionType.materialFullScreenDialog,
      maintainState: routeConfig.maintainState,
      builder: builder,
    );
  }
}

/// Cupertino 过渡策略
class CupertinoRouteStrategy implements RouteStrategy {
  @override
  PageRoute<dynamic> createRoute(RouteConfiguration routeConfig) {
    final builder = (BuildContext context) {
      return routeConfig.handler.handlerFunc(
            context,
            routeConfig.parameters,
          ) ??
          const SizedBox.shrink();
    };
    if (routeConfig.disableSwipeBack) {
      return _NoPopGestureCupertinoPageRoute<dynamic>(
        settings: routeConfig.routeSettings,
        fullscreenDialog:
            routeConfig.transition == TransitionType.cupertinoFullScreenDialog,
        maintainState: routeConfig.maintainState,
        builder: builder,
      );
    }
    return CupertinoPageRoute<dynamic>(
      settings: routeConfig.routeSettings,
      fullscreenDialog:
          routeConfig.transition == TransitionType.cupertinoFullScreenDialog,
      maintainState: routeConfig.maintainState,
      builder: builder,
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

    final RoutePageBuilder pageBuilder =
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
        };

    final td = routeConfig.transition == TransitionType.none
        ? Duration.zero
        : (routeConfig.transitionDuration ??
              routeConfig.route?.transitionDuration ??
              FluroRouterTools.defaultTransitionDuration);

    final rt = routeConfig.transition == TransitionType.none
        ? Duration.zero
        : (routeConfig.transitionDuration ??
              routeConfig.route?.transitionDuration ??
              FluroRouterTools.defaultTransitionDuration);

    final RouteTransitionsBuilder tb =
        routeConfig.transition == TransitionType.none
        ? (BuildContext _, Animation<double> __, Animation<double> ___, Widget child) =>
              child
        : routeTransitionsBuilder!;

    if (routeConfig.disableSwipeBack) {
      return _NoPopGesturePageRouteBuilder<dynamic>(
        opaque: false,
        settings: routeConfig.routeSettings,
        maintainState: routeConfig.maintainState,
        pageBuilder: pageBuilder,
        transitionDuration: td,
        reverseTransitionDuration: rt,
        transitionsBuilder: tb,
      );
    }
    return PageRouteBuilder<dynamic>(
      opaque: false,
      settings: routeConfig.routeSettings,
      maintainState: routeConfig.maintainState,
      pageBuilder: pageBuilder,
      transitionDuration: td,
      reverseTransitionDuration: rt,
      transitionsBuilder: tb,
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
    final RoutePageBuilder pageBuilder =
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
        };

    final td =
        routeConfig.transitionDuration ??
        routeConfig.route?.transitionDuration ??
        FluroRouterTools.defaultTransitionDuration;

    if (routeConfig.disableSwipeBack) {
      return _NoPopGesturePageRouteBuilder<dynamic>(
        opaque: routeConfig.opaque ?? routeConfig.route?.opaque ?? false,
        settings: routeConfig.routeSettings,
        maintainState: routeConfig.maintainState,
        pageBuilder: pageBuilder,
        transitionDuration: td,
        reverseTransitionDuration: td,
        transitionsBuilder: transitionsBuilder,
      );
    }
    return PageRouteBuilder<dynamic>(
      opaque: routeConfig.opaque ?? routeConfig.route?.opaque ?? false,
      settings: routeConfig.routeSettings,
      maintainState: routeConfig.maintainState,
      pageBuilder: pageBuilder,
      transitionDuration: td,
      reverseTransitionDuration: td,
      transitionsBuilder: transitionsBuilder,
    );
  }
}
