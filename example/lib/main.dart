import 'package:example/router/route_guards.dart';
import 'package:example/router/router_config.dart';
import 'package:example/pages/auth_page.dart';
import 'package:example/pages/c_page.dart';
import 'package:fluro_router_generate/fluro_router.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _initialized = true;

      // 注册路由守卫（在 initAllHandlers 前后均可，守卫在每次跳转前执行）
      // A -> C 时未登录：挂起 A 的跳转 Future，转去 B(/auth) 认证，成功后 resume 再去 C。
      FluroConfig.addGuard(loggingGuard1);
      FluroConfig.addGuard(authGuard1);
      FluroConfig.addGuard(authGuard2);
      FluroConfig.addGuard(loggingGuard2);

      // 注册生成的路由（注解生成的路由）
      RouteConfig.instance.initAllHandlers();

      // 手动补充示例路由（不依赖重新生成 g.dart）
      FluroConfig.router.define(
        '/auth',
        handler: FluroHandler(
          handlerFunc: (_, params) {
            final guard = params['guard']?.first ?? '?';
            return AuthPage(title: 'B - 认证（守卫 $guard）');
          },
        ),
      );
      FluroConfig.router.define(
        '/c',
        handler: FluroHandler(
          handlerFunc: (_, __) => const CPage(),
        ),
      );
    }

    return MaterialApp(
      title: 'Fluro Router Example',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      onGenerateRoute: FluroConfig.router.generator,
      initialRoute: '/home',
    );
  }
}
