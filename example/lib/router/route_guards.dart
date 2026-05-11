import 'package:fluro_router_generate/fluro_router.dart';

/// 你的业务模型：多个认证守卫依次执行。
///
/// - guard1 通过后仍会继续执行 guard2
/// - 每个守卫都可能 suspend（挂起同一次跳转的 Future）→ 去认证页 B → 成功后 resume
bool guard1Passed = true;
bool guard2Passed = true;

/// 需要登录才能访问的路径前缀（示例里把 C 页也保护起来）
const _protectedPathPrefixes = ['/detail', '/user/', '/search', '/c'];

bool _isProtectedPath(String path) {
  final normalized = path.split('?').first;
  return _protectedPathPrefixes.any((prefix) => normalized.startsWith(prefix));
}

bool _isAuthRoute(String path) => path.split('?').first == '/auth';

/// 认证守卫1是否正在进行
bool _guard1UiInProgress = false;

/// 认证守卫2是否正在进行
bool _guard2UiInProgress = false;

/// 认证守卫1：未通过则挂起并去 B（认证通过后 resume）
Future<GuardResult> authGuard1(RouteGuardContext ctx) async {
  if (_isAuthRoute(ctx.path)) return GuardResult.allow;
  if (!_isProtectedPath(ctx.path)) return GuardResult.allow;
  if (guard1Passed) return GuardResult.allow;

  if (!_guard1UiInProgress) {
    _guard1UiInProgress = true;
    Future.microtask(() async {
      final context = ctx.context;
      try {
        if (!context.mounted) return;
        final ok = await FluroConfig.push<bool>(
          '/auth?guard=1',
          context: context,
        );
        if (ok == true) {
          guard1Passed = true;
          if (!context.mounted) return;
          await Future.delayed(const Duration(seconds: 1));
          // ignore: use_build_context_synchronously
          await FluroConfig.resumePendingRoute<bool>(context);
        } else {
          FluroConfig.clearPendingRoute();
        }
      } finally {
        _guard1UiInProgress = false;
      }
    });
  }

  return GuardResult.suspend;
}

/// 认证守卫2：guard1 通过后仍会执行到这里；未通过则再次挂起并去 B（认证通过后 resume）
Future<GuardResult> authGuard2(RouteGuardContext ctx) async {
  if (_isAuthRoute(ctx.path)) return GuardResult.allow;
  if (!_isProtectedPath(ctx.path)) return GuardResult.allow;
  if (guard2Passed) return GuardResult.allow;

  if (!_guard2UiInProgress) {
    _guard2UiInProgress = true;
    Future.microtask(() async {
      final context = ctx.context;
      try {
        if (!context.mounted) return;
        final ok = await FluroConfig.push<bool>(
          '/auth?guard=2',
          context: context,
        );
        if (ok == true) {
          guard2Passed = true;
          if (!context.mounted) return;
          await Future.delayed(const Duration(seconds: 1));
          // ignore: use_build_context_synchronously
          await FluroConfig.resumePendingRoute<bool>(context);
        } else {
          FluroConfig.clearPendingRoute();
        }
      } finally {
        _guard2UiInProgress = false;
      }
    });
  }

  return GuardResult.suspend;
}

/// 可选的全局守卫示例：例如打日志、埋点等
Future<GuardResult> loggingGuard1(RouteGuardContext ctx) async {
  return GuardResult.allow;
}

/// 额外守卫（模拟 N 个守卫）
Future<GuardResult> loggingGuard2(RouteGuardContext ctx) async {
  return GuardResult.allow;
}
