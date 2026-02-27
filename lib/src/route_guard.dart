import 'package:flutter/material.dart';
import 'package:fluro_router_generate/src/fluro_route_match.dart';

/// 允许跳转、重定向到新路径、或取消跳转。
///
/// 与 [NavigatorObserver] 不同，守卫在 **跳转前** 执行，因此可以拦截或重定向。
/// [NavigatorObserver] 的 didPush/didPop 等是事后回调，无法阻止或改写本次跳转。
///
/// 用法示例：
/// ```dart
/// FluroConfig.addGuard((ctx) async {
///   if (ctx.path.startsWith('/admin') && !isLoggedIn()) {
///     return GuardResult.redirect('/login');
///   }
///   return GuardResult.allow;
/// });
/// ```
sealed class GuardResult {
  const GuardResult();

  /// 允许本次跳转，继续执行 [Navigator.push]。
  static const GuardResult allow = GuardAllow();

  /// 取消本次跳转，[navigateTo] 将 resolve 为 null（不抛错）。
  static const GuardResult cancel = GuardCancel();

  /// 重定向到新路径；框架会用 [newPath] 重新执行一次 [navigateTo]（会再次经过守卫）。
  static GuardResult redirect(String newPath) => GuardRedirect(newPath);
}

class GuardAllow extends GuardResult {
  const GuardAllow();
}

class GuardCancel extends GuardResult {
  const GuardCancel();
}

class GuardRedirect extends GuardResult {
  GuardRedirect(this.newPath);
  final String newPath;
}

/// 守卫被调用时收到的上下文：当前要跳转的路径、[BuildContext]、以及本次导航参数。
///
/// 守卫可根据 [path]、[replace]、[clearStack] 等决定 [GuardResult.allow] / [redirect] / [cancel]。
class RouteGuardContext {
  RouteGuardContext({
    required this.context,
    required this.path,
    required this.replace,
    required this.clearStack,
    required this.maintainState,
    required this.rootNavigator,
    this.routeMatch,
    this.routeSettings,
  });

  final BuildContext context;
  final String path;
  final bool replace;
  final bool clearStack;
  final bool maintainState;
  final bool rootNavigator;
  final FluroRouteMatch? routeMatch;
  final RouteSettings? routeSettings;
}

/// 路由守卫函数。
///
/// 在 [FluroRouter.navigateTo] 内部、**真正执行 [Navigator.push] 之前** 被调用。
/// 返回 [GuardResult.allow] 继续跳转，[GuardResult.redirect] 用新路径重新走一遍导航（会再次经过守卫），
/// [GuardResult.cancel] 取消本次跳转（不 push，Future 以 null 结束）。
///
/// 可注册多个守卫，按注册顺序依次执行；任一返回 redirect 则立即用新路径重跑，任一返回 cancel 则终止。
typedef RouteGuard =
    Future<GuardResult> Function(RouteGuardContext guardContext);
