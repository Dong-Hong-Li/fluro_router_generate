import 'package:fluro_router_generate/fluro_router.dart';
import 'package:flutter/material.dart';

abstract class FluroConfig {
  static FluroRouter get router => FluroRouter.appRouter;
  static BuildContext? _context;
  static BuildContext? get currentContext => _context;
  set context(BuildContext? value) {
    _context = value;
  }

  /// Deferred 路由全局默认：加载中/失败 UI。未设置时 [DeferredRoutePage] 使用内置默认。
  static DeferredRouteUIOptions? deferredRouteUIOptions;

  static final Map<String, DeferredRouteUIOptions> _deferredRouteOverrides = {};

  /// 为指定 path 设置 Deferred 加载中/失败 UI 或自定义 [DeferredRouteWrapper]，覆盖全局 [deferredRouteUIOptions]。
  static void setDeferredBuildersForPath(
    String path, {
    DeferredLoadingBuilder? loading,
    DeferredErrorBuilder? error,
    DeferredRouteWrapper? wrapper,
  }) {
    _deferredRouteOverrides[path] = DeferredRouteUIOptions(
      loadingBuilder: loading,
      errorBuilder: error,
      wrapper: wrapper,
    );
  }

  /// 供生成代码使用：按 path 取加载中 builder（先单路径覆盖，再全局默认）。
  static DeferredLoadingBuilder? deferredLoadingBuilderFor(String path) =>
      _deferredRouteOverrides[path]?.loadingBuilder ??
      deferredRouteUIOptions?.loadingBuilder;

  /// 供生成代码使用：按 path 取失败 builder（先单路径覆盖，再全局默认）。
  static DeferredErrorBuilder? deferredErrorBuilderFor(String path) =>
      _deferredRouteOverrides[path]?.errorBuilder ??
      deferredRouteUIOptions?.errorBuilder;

  /// 供生成代码使用：按 path 取自定义包装器（先单路径覆盖，再全局默认）。非 null 时由 [DeferredRoutePage] 使用 [wrapper] 完全接管展示。
  static DeferredRouteWrapper? deferredWrapperFor(String path) =>
      _deferredRouteOverrides[path]?.wrapper ?? deferredRouteUIOptions?.wrapper;

  static final Map<String, Future<void> Function()> _deferredLoaders = {};

  /// 注册某条 deferred 路由的 loader，用于 [preloadDeferredRoute] 预加载。
  /// 大模块（如直播、音视频剪辑）可在首页就绪或进入发现页时预加载，减少首次进入该路由时的等待。
  /// 需与生成代码中的 path 一致；loader 通常为对应 deferred 库的 loadLibrary，例如：
  /// `FluroConfig.registerDeferredLoader('/search?keyword=&page=1', () => search_lib.loadLibrary());`
  static void registerDeferredLoader(String path, Future<void> Function() loader) {
    _deferredLoaders[path] = loader;
  }

  /// 预加载指定 path 的 deferred 模块（若已注册）。同进程内重复调用只会执行一次实际加载。
  /// 建议在首页渲染完成或用户进入相关入口时调用，以分摊大模块加载时机。
  static Future<void> preloadDeferredRoute(String path) async {
    final loader = _deferredLoaders[path];
    if (loader != null) await loader();
  }

  /// 预加载所有已通过 [registerDeferredLoader] 注册的 deferred 模块。
  static Future<void> preloadAllDeferredRoutes() async {
    await Future.wait(_deferredLoaders.values.map((loader) => loader()));
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

  /// 由带 [EntranceAnnotation] 的配置类对应生成的 .router.g.dart 扩展实现；
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
    TransitionType transition = TransitionType.native,
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
