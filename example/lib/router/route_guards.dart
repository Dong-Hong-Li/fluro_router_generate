import 'package:fluro_router_generate/fluro_router.dart';

/// 示例：登录状态（实际项目可替换为 Provider/GetIt 等）
bool isLoggedIn = false;

/// 需要登录才能访问的路径前缀
const _protectedPathPrefixes = ['/detail', '/user/', '/search'];

bool _isProtectedPath(String path) {
  final normalized = path.split('?').first;
  return _protectedPathPrefixes.any((prefix) => normalized.startsWith(prefix));
}

/// 认证守卫：未登录访问受保护路由时重定向到首页
Future<GuardResult> authGuard(RouteGuardContext ctx) async {
  if (!_isProtectedPath(ctx.path)) {
    return GuardResult.allow;
  }
  if (!isLoggedIn) {
    // 未登录则重定向到首页（可根据需要改为 /login）
    return GuardResult.redirect('/home');
  }
  return GuardResult.allow;
}

/// 可选的全局守卫示例：例如打日志、埋点等
Future<GuardResult> loggingGuard(RouteGuardContext ctx) async {
  // 这里可做导航前日志、埋点等，然后放行
  return GuardResult.allow;
}
