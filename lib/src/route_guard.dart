import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluro_router_generate/src/enum.dart';
import 'package:fluro_router_generate/src/fluro_route_match.dart';

/// 允许跳转、重定向、取消、或挂起（常用于前置条件校验）。
///
/// 与 [NavigatorObserver] 不同，守卫在 **跳转前** 执行，因此可以拦截或改写本次跳转。
///
/// - [allow]：继续跳转。
/// - [redirect]：用新路径再跳（替换 path）。
/// - [cancel]：取消跳转，当前页不变。
/// - [suspend]：挂起跳转并保存意图；由调用方在外部流程完成后通过 [FluroConfig.resumePendingRoute] 恢复，或用 [FluroConfig.clearPendingRoute] 结束本次挂起。
sealed class GuardResult {
  const GuardResult();

  /// 允许本次跳转，继续执行 [Navigator.push]。
  static const GuardResult allow = GuardAllow();

  /// 取消本次跳转，[navigateTo] 将 resolve 为 null（不抛错）。
  static const GuardResult cancel = GuardCancel();

  /// 重定向到新路径；框架会用 [newPath] 重新执行一次 [navigateTo]（会再次经过守卫）。
  static GuardResult redirect(String newPath) => GuardRedirect(newPath);

  /// 挂起本次跳转：不执行跳转，将本次导航意图保存为「待恢复」。
  /// 由调用方在外部流程完成后调用 [FluroConfig.resumePendingRoute] 恢复，或调用
  /// [FluroConfig.clearPendingRoute] 结束挂起（Future 以 `null` 完成）。
  static const GuardResult suspend = GuardSuspend();
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

/// 一次被挂起的导航意图 + 对应的 Future（用于把 `push/navigateTo` 挂起到 resume/clear）。
class PendingNavigation {
  PendingNavigation._({
    required this.path,
    required this.replace,
    required this.clearStack,
    required this.maintainState,
    required this.rootNavigator,
    this.transition,
    this.transitionDuration,
    this.transitionCurve,
    this.transitionBuilder,
    this.routeSettings,
    this.opaque,
    this.disableSwipeBack = false,
    required Completer<Object?> completer,
  }) : _completer = completer;

  final String path;
  final bool replace;
  final bool clearStack;
  final bool maintainState;
  final bool rootNavigator;
  final TransitionType? transition;
  final Duration? transitionDuration;
  final Curve? transitionCurve;
  final RouteTransitionsBuilder? transitionBuilder;
  final RouteSettings? routeSettings;
  final bool? opaque;
  final bool disableSwipeBack;

  final Completer<Object?> _completer;

  /// 原始调用方 await 的就是这个 Future。
  Future<Object?> get future => _completer.future;

  void complete(Object? value) {
    if (!_completer.isCompleted) _completer.complete(value);
  }

  void completeError(Object error, StackTrace st) {
    if (!_completer.isCompleted) _completer.completeError(error, st);
  }
}

/// 挂起本次跳转：不执行跳转，并用 [Completer] 将本次 `navigateTo/push` 的 Future 挂起，
/// 直到调用方显式恢复（resume）或结束挂起（clear）才会完成。
class GuardSuspend extends GuardResult {
  const GuardSuspend();

  static PendingNavigation? _pending;

  static bool get hasPending => _pending != null;

  /// 保存一次挂起并返回 [PendingNavigation]（router 会把其 [PendingNavigation.future] 作为返回值）。
  /// 若已有挂起未处理，会先将旧挂起以 `null` 完成并覆盖（避免 Future 永不结束）。
  static PendingNavigation setPending({
    required String path,
    required bool replace,
    required bool clearStack,
    required bool maintainState,
    required bool rootNavigator,
    TransitionType? transition,
    Duration? transitionDuration,
    Curve? transitionCurve,
    RouteTransitionsBuilder? transitionBuilder,
    RouteSettings? routeSettings,
    bool? opaque,
    bool disableSwipeBack = false,
  }) {
    final old = _pending;
    if (old != null) {
      old.complete(null);
    }

    final completer = Completer<Object?>();
    _pending = PendingNavigation._(
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
      completer: completer,
    );
    return _pending!;
  }

  /// 取出并清除挂起（resume 时用）。
  static PendingNavigation? takePending() {
    final v = _pending;
    _pending = null;
    return v;
  }

  /// 结束挂起：让挂起的 Future 以 `null` 结束，当前页不变。
  static void clearPending() {
    final v = _pending;
    _pending = null;
    v?.complete(null);
  }
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
/// 返回 [GuardResult.allow] 继续跳转；[GuardResult.redirect] 用新路径再走一遍导航；
/// [GuardResult.cancel] 取消本次跳转；[GuardResult.suspend] 挂起本次跳转并保存意图，稍后由调用方通过
/// [FluroConfig.resumePendingRoute] 恢复或用 [FluroConfig.clearPendingRoute] 结束。
///
/// 可注册多个守卫，按注册顺序依次执行；任一返回 redirect 则用新路径重跑，任一返回 cancel 或 suspend 则终止本次跳转。
typedef RouteGuard =
    Future<GuardResult> Function(RouteGuardContext guardContext);
