import 'package:fluro_router_generate/fluro_router.dart';
import 'package:flutter/material.dart';

abstract class FluroConfig {
  static FluroRouter get router => FluroRouter.appRouter;
  static BuildContext? _context;
  static BuildContext? get currentContext => _context;
  set context(BuildContext? value) {
    _context = value;
  }

  /// 当用户尝试导航到一个未定义的路由时 返回一个边界路由
  set notFoundHandler(FluroHandler? handler) {
    router.notFoundHandler = handler;
  }

  /// 注册路由守卫。守卫在每次 [push]/[navigateTo] 时、**执行 [Navigator.push] 之前** 按注册顺序执行，
  /// 可返回 [GuardResult.allow]（放行）、[GuardResult.redirect]（重定向）、[GuardResult.cancel]（取消）、[GuardResult.suspend]（挂起）。
  /// 与 [NavigatorObserver] 不同，守卫用于跳转前拦截或重定向；Observer 仅能事后回调（didPush/didPop 等）。
  static void addGuard(RouteGuard guard) {
    router.guards.add(guard);
  }

  /// 是否存在被挂起的路由（例如在守卫中返回 [GuardResult.suspend] 后可挂起，外部流程满足条件后用 [resumePendingRoute] 恢复）。
  static bool get hasPendingRoute => router.hasPendingRoute;

  /// 清除被挂起的路由意图（例如外部流程未通过时调用），当前页不变。
  static void clearPendingRoute() => router.clearPendingRoute();

  /// 使用 [context] 继续执行此前挂起的导航（例如外部流程满足条件后调用）；若无挂起则 no-op。执行后自动清除挂起意图。
  static Future<T?> resumePendingRoute<T extends Object?>(
    BuildContext context,
  ) => router.resumePendingRoute<T>(context);

  /// 跳转边界路由是否清空堆栈
  set notFoundClearStack(bool value) {
    router.notFoundClearStack = value;
  }

  /// 由带 [EntranceAnnotation] 的配置类对应生成的 .g.dart 扩展实现；
  /// 子类通过扩展获得 [initAllHandlers]，基类不声明以避免遮蔽扩展方法。

  /// 导航到指定路径的路由，并可配置路由的导航行为和过渡效果。
  ///
  /// - `path`：路由路径
  /// - `replace`：是否替换当前路由
  /// - `clearStack`：是否清空路由栈
  /// - `maintainState`：是否保持状态
  /// - `rootNavigator`：是否使用根导航器
  /// - `context`：上下文对象
  /// - `transition`：过渡效果
  /// - `transitionDuration`：过渡时间 默认100ms
  /// - `transitionCurve`：过渡动画曲线
  /// - `transitionBuilder`：自定义过渡效果的构建器
  /// - `routeSettings`：路由设置a
  /// - `opaque`：是否透明
  ///
  /// ```dart
  /// push(
  ///   '/details',
  ///   context: context,
  ///   replace: true,
  ///   clearStack: true,
  ///   transition: TransitionType.inFromRight,
  ///   transitionCurve: Curves.easeOutCubic,
  /// );
  /// ```
  static Future<T?> push<T extends Object?>(
    String path, {
    bool replace = false,
    bool clearStack = false,
    bool maintainState = true,
    bool rootNavigator = false,
    BuildContext? context,
    TransitionType transition = TransitionType.inFromRight,
    Duration? transitionDuration,
    Curve? transitionCurve,
    RouteTransitionsBuilder? transitionBuilder,
    RouteSettings? routeSettings,
    bool? opaque,
  }) async {
    if (context == null && _context == null) {
      throw Exception('context is not set, please set context in FiuroConfig');
    }
    return await router.navigateTo(
      context ?? _context!,
      path,
      replace: replace,
      clearStack: clearStack,
      maintainState: maintainState,
      rootNavigator: rootNavigator,
      transition: transition,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      transitionBuilder: transitionBuilder,
      routeSettings: routeSettings,
      opaque: opaque,
    );
  }
}
