import 'dart:async';
import 'package:fluro_router_generate/src/mixin_fluro_router_tools.dart';
import 'package:flutter/material.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/extension.dart';
import 'package:fluro_router_generate/src/fluro_handler.dart';
import 'package:fluro_router_generate/src/fluro_route_data.dart';
import 'package:fluro_router_generate/src/fluro_route_match.dart';
import 'package:fluro_router_generate/src/fluro_route_storager.dart';
import 'route_guard.dart';

/// {@template fluro_router_generate}
/// `FluroRouter` 是 Fluro 路由库的核心方法类，它提供了路由的定义、匹配、导航、过渡动画等功能。
///
/// 通过将 [FluroRouter.generator] 绑定到 [MaterialApp.onGenerateRoute]，你可以让 `FluroRouter` 接管
/// 默认的路由生成机制。
/// ```dart
///  MaterialApp(
///    onGenerateRoute: FluroRouter.generator,
///     ..........
///  );
///
/// ```
/// 使用 [FluroRouter.define] 来定义路由，并可以指定路由的过渡动画和路径参数。
/// ```dart
///  FluroRouter.define(item.path, handler: FluroHandler);
///
/// ```
/// 导航时，可以选择使用 [FluroRouter.navigateTo] 进行路由跳转
/// {@endtemplate}
///
class FluroRouter with FluroRouterTools {
  /// 的静态/单例实例的 [FluroRouter]
  ///
  /// {@macro fluro_router_generate}
  static final appRouter = FluroRouter();

  /// 用来存储和管理通过 [FluroRouter.define] 定义的所有路由。
  final _routeTree = FluroRouteStorager();

  /// 当用户尝试导航到一个未定义的路由时 返回一个边界路由
  FluroHandler? notFoundHandler;

  /// 跳转边界路由是否清空堆栈
  bool notFoundClearStack = false;

  /// 路由守卫列表。在 [navigateTo] 中、执行 [Navigator.push] 之前按顺序执行；
  /// 任一返回 [GuardResult.redirect] 则用新路径重新导航，返回 [GuardResult.cancel] / [GuardResult.suspend] 则终止本次跳转。
  final List<RouteGuard> guards = [];

  /// 是否存在被挂起的路由（挂起意图与 Completer 由 [GuardSuspend] 承载）。
  bool get hasPendingRoute => GuardSuspend.hasPending;

  /// 清除被挂起的路由意图（例如外部流程未通过时调用），当前页不变。
  void clearPendingRoute() => GuardSuspend.clearPending();

  /// 使用 [context] 继续执行此前挂起的导航（例如外部流程满足条件后调用）；若无挂起则 no-op。
  /// 会再次经过守卫；执行后自动清除挂起意图。
  Future<T?> resumePendingRoute<T extends Object?>(BuildContext context) async {
    final pending = GuardSuspend.takePending();
    if (pending == null) return null as T?;

    try {
      final result = await navigateTo<T>(
        context,
        pending.path,
        replace: pending.replace,
        clearStack: pending.clearStack,
        maintainState: pending.maintainState,
        rootNavigator: pending.rootNavigator,
        transition: pending.transition,
        transitionDuration: pending.transitionDuration,
        transitionCurve: pending.transitionCurve,
        transitionBuilder: pending.transitionBuilder,
        routeSettings: pending.routeSettings,
        opaque: pending.opaque,
        disableSwipeBack: pending.disableSwipeBack,
      );
      pending.complete(result);
      return result;
    } catch (e, st) {
      pending.completeError(e, st);
      rethrow;
    }
  }

  ///定义一个新的路由 [PageRoute]。它将一个路由路径（routePath）与对应的处理逻辑 [FluroHandler]
  ///以及动画过渡相关的设置绑定在一起，并存储到 _routeTree 中。
  ///
  /// - `routePath`：定义的路由路径，例如 /home 或 /details/:id。
  /// - `handler`: 处理此路由的逻辑（如页面构建器）。
  /// - `TransitionType`: 页面切换时的动画类型（如淡入、滑动等）。
  /// - `transitionDuration`: 动画过渡的持续时间。
  /// - `transitionBuilder`: 自定义的动画过渡构建器。
  /// - `opaque`: 是否使新页面背景透明（默认 true，表示页面不透明）。
  ///
  ///```dart
  ///
  /// //定义路由
  /// router.define(
  ///   '/example',
  ///   handler: FluroHandler(
  ///     handlerFunc: (BuildContext? context, Map<String, List<String>> params) {
  ///       return ExamplePage();
  ///     },
  ///   ),
  ///   transitionType: TransitionType.fadeIn,
  ///   transitionDuration: FluroRouter.FluroRouterTools.defaultTransitionDuration,
  ///   transitionCurve: Curves.easeInOut, // 自定义动画曲线
  /// );
  ///```
  void define(
    String routePath, {
    required FluroHandler? handler,
    TransitionType? transitionType,
    Duration transitionDuration = FluroRouterTools.defaultTransitionDuration,
    Curve transitionCurve = FluroRouterTools.defaultTransitionCurve,
    RouteTransitionsBuilder? transitionBuilder,
    bool? opaque,
    bool disableSwipeBack = false,
  }) {
    final routeData = FluroRouteData(
      routePath,
      handler,
      transitionType: transitionType,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      transitionBuilder: transitionBuilder,
      opaque: opaque,
      disableSwipeBack: disableSwipeBack,
    );
    _routeTree.addRoute(routeData);
  }

  /// 此方法类似于 [Navigator.push]，但包含了额外的功能，如自定义过渡类型、
  /// 控制导航堆栈以及处理未定义路由的情况。
  ///
  ///  - `context`：BuildContext 上下文对象
  ///  - `path`：跳转路由
  ///  - `replace`：是否替换当前的路由。新的路由会替代当前路由
  ///  - `clearStack`：否清空路由堆栈。新路由会成为唯一的路由。
  ///  - `maintainState`保持当前路由的状态,当导航回到当前路由时，会保留之前的状态。
  ///  - `rootNavigator`：是否使用根导航器进行导航
  ///  - `transitionDuration`：过渡效果的持续时间。
  ///  - `transitionBuilder`：自定义过渡效果的构建器。提供了自定义构建器，将忽略 transition 参数。
  ///  - `transition`：要使用的过渡类型，默认为 [TransitionType.fadeIn]。
  ///  - `routeSettings`：路由的设置，例如路由名称和其他路由特定的信息。可以用于传参。
  ///  - `opaque`：如果设置为 true，新的路由将是透明的，阻止与下层路由交互。
  ///
  ///```dart
  ///
  ///  //等待上层路由 Navigator.pop
  ///  var result = await FluroRouter.navigateTo(context,path);
  ///  // 如果有返回结果并且提供了 pushResult 回调函数，则调用回调
  ///  if (result != null && pushResult != null) pushResult(result);
  ///```
  /// 守卫重定向最大次数，防止重定向死循环。
  static const int _maxGuardRedirects = 5;

  Future<T?> navigateTo<T extends Object?>(
    BuildContext context,
    String path, {
    bool replace = false,
    bool clearStack = false,
    bool maintainState = true,
    bool rootNavigator = false,
    TransitionType? transition,
    Duration? transitionDuration,
    Curve? transitionCurve,
    RouteTransitionsBuilder? transitionBuilder,
    RouteSettings? routeSettings,
    bool? opaque,
    bool disableSwipeBack = false,
  }) async {
    return _navigateToInternal<T>(
      context,
      path,
      redirectCount: 0,
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
      disableSwipeBack: disableSwipeBack,
    );
  }

  /// 内部导航方法，用于处理导航逻辑。
  Future<T?> _navigateToInternal<T extends Object?>(
    BuildContext context,
    String path, {
    required int redirectCount,
    bool replace = false,
    bool clearStack = false,
    bool maintainState = true,
    bool rootNavigator = false,
    TransitionType? transition,
    Duration? transitionDuration,
    Curve? transitionCurve,
    RouteTransitionsBuilder? transitionBuilder,
    RouteSettings? routeSettings,
    bool? opaque,
    bool disableSwipeBack = false,
  }) async {
    /// 根据给定的路径匹配路由。如果没有匹配到路由，RouteMatchType.noMatch 表示未找到匹配的路由。
    FluroRouteMatch routeMatch = matchRoute(
      context,
      path,
      transitionType: transition,
      transitionsBuilder: transitionBuilder,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      maintainState: maintainState,
      routeSettings: routeSettings,
      opaque: opaque,
      disableSwipeBack: disableSwipeBack,
    );

    // 在真正执行 Navigator.push 之前执行守卫（跳转前拦截/重定向）
    if (guards.isNotEmpty && redirectCount < _maxGuardRedirects) {
      final guardContext = RouteGuardContext(
        context: context,
        path: path,
        replace: replace,
        clearStack: clearStack,
        maintainState: maintainState,
        rootNavigator: rootNavigator,
        routeMatch: routeMatch,
        routeSettings: routeSettings,
      );
      for (final guard in guards) {
        final result = await guard(guardContext);
        if (result is GuardRedirect) {
          if (!context.mounted) return null as T?;
          return _navigateToInternal<T>(
            context,
            result.newPath,
            redirectCount: redirectCount + 1,
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
            disableSwipeBack: disableSwipeBack,
          );
        }
        if (result is GuardCancel) {
          return null as T?;
        }
        if (result is GuardSuspend) {
          final pending = GuardSuspend.setPending(
            path: path,
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
            disableSwipeBack: disableSwipeBack,
          );
          // `pending.future` 是 `Future<Object?>`，不能直接强转为 `Future<T?>`（会在运行时崩溃）。
          // 用 then 包一层把值转成 `T?`，以保证 `FluroConfig.push<T>` 的返回类型正确。
          return pending.future.then<T?>((v) => v as T?);
        }
      }
      if (!context.mounted) return null as T?;
    }

    Route<dynamic>? route = routeMatch.route;

    // 创建异步操作对象,用于等待路由跳转完成。
    Completer completer = Completer();
    Future future = completer.future;

    if (routeMatch.matchType == RouteMatchType.nonVisual) {
      completer.complete('非视觉路由类型。');
    } else {
      // 如果没有匹配到路由，并且存在未定义路由的处理函数（notFoundHandler），
      if (route == null && notFoundHandler != null) {
        final navigator = Navigator.of(context, rootNavigator: rootNavigator);
        final notRoute = notFoundRoute(
          context,
          path,
          notFoundHandler!,
          maintainState: maintainState,
        );
        if (notFoundClearStack) {
          future = navigator.pushAndRemoveUntil(notRoute, (_) => false);
        } else {
          future = navigator.push(notRoute);
        }
      } else if (route == null && notFoundHandler == null) {
        completer.completeError(
          RouteNotFoundException(
            'No matching route was found. Procedure',
            path,
          ),
        );
      }

      // 如果路由存在，执行跳转操作。
      if (route != null) {
        final navigator = Navigator.of(context, rootNavigator: rootNavigator);
        if (clearStack) {
          //  `pushAndRemoveUntil` 方法清除所有路由，并将新路由作为根路由。
          future = navigator.pushAndRemoveUntil(route, (check) => false);
        } else {
          //  如果 replace 为 true，则 `pushReplacement` 替换当前路由,否则，推送新路由
          future = replace
              ? navigator.pushReplacement(route)
              : navigator.push(route);
        }
        completer.complete();
      }
    }

    // `Navigator.push/pushReplacement/...` 返回的是 `Future<dynamic>`，
    // 不能直接强转成 `Future<T?>`（例如 `Future<dynamic>` 不是 `Future<bool?>` 的子类型）。
    return future.then<T?>((v) => v as T?);
  }

  /// 等价于 [Navigator.of]（可选 [rootNavigator]）后 [Navigator.pop]。
  ///
  /// 返回值请使用命名参数：`pop(context, result: value)`（不再使用第二位位置参数）。
  void pop<T extends Object?>(
    BuildContext context, {
    T? result,
    bool rootNavigator = false,
  }) {
    Navigator.of(context, rootNavigator: rootNavigator).pop<T>(result);
  }

  /// 连续弹出直至根路由：等价于 `popUntil(context, (route) => route.isFirst)`。
  ///
  /// 与 [Navigator.popUntil] 语义一致，不向被保留的页面传递 pop 返回值。
  void popToRoot(BuildContext context, {bool rootNavigator = false}) {
    popUntil(
      context,
      (Route<dynamic> route) => route.isFirst,
      rootNavigator: rootNavigator,
    );
  }

  /// 等价于 [Navigator.of]（可选 [rootNavigator]）后 [Navigator.popUntil]。
  void popUntil(
    BuildContext context,
    RoutePredicate predicate, {
    bool rootNavigator = false,
  }) {
    Navigator.of(context, rootNavigator: rootNavigator).popUntil(predicate);
  }

  /// `MaterialApp.onGenerateRoute` 允许你在运行时根据传入的 `RouteSettings` 动态生成路由。
  Route<dynamic>? generator(RouteSettings routeSettings) =>
      matchRoute(null, routeSettings.name, routeSettings: routeSettings).route;

  /// 尝试根据提供的 [path] 匹配一个路由，并返回匹配结果。
  /// 如果找到匹配的路由，将构建相应的路由对象；如果找不到，则返回未匹配结果或调用未定义路由的处理逻辑。
  ///
  ///  - `buildContext`： 上下文对象
  ///  - `path`： 需要匹配的路由路径
  ///  - `routeSettings`： 路由的配置信息（如名称和附加参数）
  ///  - `transitionType`： 路由的过渡类型。
  ///  - `transitionDuration`： 自定义的过渡动画时长。
  ///  - `transitionsBuilder`： 自定义的过渡动画构建器。
  ///  - `maintainState`： 是否保持当前路由的状态。
  ///  - `opaque`： 路由是否为不透明（true 表示覆盖底层内容，false 表示透明）。
  ///
  /// `注意! 优先使用传入的路由配置信息，如果没有配置信息，则使用提供的路径参数。`
  FluroRouteMatch matchRoute(
    BuildContext? buildContext,
    String? path, {
    RouteSettings? routeSettings,
    TransitionType? transitionType,
    Duration? transitionDuration,
    Curve? transitionCurve,
    RouteTransitionsBuilder? transitionsBuilder,
    bool maintainState = true,
    bool? opaque,
    bool disableSwipeBack = false,
  }) {
    RouteSettings settings = settingsHandle(routeSettings, path);

    // 在路由树中尝试匹配路由。
    AppRouteMatchResult? match = _routeTree.matchRoute(path!);
    // 如果既没有匹配的路由也没有定义未匹配路由的处理器，则返回未匹配结果。
    if (match?.route == null) {
      FluroRouteMatch(
        matchType: RouteMatchType.noMatch,
        errorMessage: '未找到匹配的路由',
      );
    }

    // 获取路由数据、处理器和参数。
    FluroRouteData? routeData = match?.route;
    FluroHandler? handler = routeData?.handler ?? notFoundHandler;
    Map<String, List<String>> parameters = match?.parameters ?? {};

    // 如果既没有匹配的路由也没有 notFoundHandler，返回未匹配结果
    if (handler == null) {
      return FluroRouteMatch(
        matchType: RouteMatchType.noMatch,
        errorMessage: '未找到匹配的路由且未设置 notFoundHandler',
      );
    }

    // 如果处理器是函数类型（非页面），直接调用处理函数并返回非视觉路由匹配结果。
    if (handler.type == HandlerType.function) {
      handler.handlerFunc(buildContext, parameters);
      return FluroRouteMatch(matchType: RouteMatchType.nonVisual);
    }

    TransitionType? transition =
        transitionType ?? routeData?.transitionType ?? TransitionType.native;
    Duration? duration = transitionDuration ?? routeData?.transitionDuration;
    Curve? curve = transitionCurve ?? routeData?.transitionCurve;
    final effectiveDisableSwipeBack =
        disableSwipeBack || (routeData?.disableSwipeBack ?? false);

    // 返回匹配结果，并包含构造好的路由对象。
    final nativeRoute = creatNativeRoute(
      RouteConfiguration(
        routeSettings: settings,
        parameters: parameters,
        transition: transition,
        maintainState: maintainState,
        handler: handler,
        transitionDuration: duration,
        transitionCurve: curve,
        transitionsBuilder: transitionsBuilder,
        route: routeData,
        opaque: opaque,
        disableSwipeBack: effectiveDisableSwipeBack,
      ),
    );
    return FluroRouteMatch(
      matchType: RouteMatchType.visual,
      route: nativeRoute,
    );
  }

  ///打印路由树
  void printTree() => _routeTree.printTree();
}
