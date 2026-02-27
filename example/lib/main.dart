import 'package:example/router/route_guards.dart';
import 'package:example/router/router_config.dart';
import 'package:fluro_router_generate/fluro_router.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 注册路由守卫（在 initAllHandlers 前后均可，守卫在每次跳转前执行）
    FluroConfig.addGuard(authGuard);
    FluroConfig.addGuard(loggingGuard);

    // 注册生成的路由
    RouteConfig.instance.initAllHandlers();

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
