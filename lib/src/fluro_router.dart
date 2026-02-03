import 'dart:async';
import 'package:fluro_router_generate/src/mixin_fluro_router_tools.dart';
import 'package:flutter/material.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/extension.dart';
import 'package:fluro_router_generate/src/fluro_handler.dart';
import 'package:fluro_router_generate/src/fluro_route_data.dart';
import 'package:fluro_router_generate/src/fluro_route_match.dart';
import 'package:fluro_router_generate/src/fluro_route_storager.dart';

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
  }) {
    final routeData = FluroRouteData(
      routePath,
      handler,
      transitionType: transitionType,
      transitionDuration: transitionDuration,
      transitionCurve: transitionCurve,
      transitionBuilder: transitionBuilder,
      opaque: opaque,
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
    );

    Route<dynamic>? route = routeMatch.route;

    // 创建异步操作对象,用于等待路由跳转完成。
    Completer completer = Completer();
    Future future = completer.future;

    if (routeMatch.matchType == RouteMatchType.nonVisual) {
      completer.complete("非视觉路由类型。");
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
            "No matching route was found. Procedure",
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

    return future as Future<T?>;
  }

  /// 使用 [Navigator.pop]
  void pop<T>(BuildContext context, [T? result]) =>
      Navigator.of(context).pop(result);

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
  }) {
    RouteSettings settings = settingsHandle(routeSettings, path);

    // 在路由树中尝试匹配路由。
    AppRouteMatchResult? match = _routeTree.matchRoute(path!);
    // 如果既没有匹配的路由也没有定义未匹配路由的处理器，则返回未匹配结果。
    if (match?.route == null) {
      FluroRouteMatch(
        matchType: RouteMatchType.noMatch,
        errorMessage: "未找到匹配的路由",
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
        errorMessage: "未找到匹配的路由且未设置 notFoundHandler",
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
