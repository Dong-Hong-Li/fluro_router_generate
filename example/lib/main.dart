import 'package:example/router/route_guards.dart';
import 'package:example/router/router_config.dart';
import 'package:example/pages/auth_page.dart';
import 'package:example/pages/c_page.dart';
import 'package:example/pages/no_swipe_back_demo_page.dart';
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

      // 为 search 这条 Deferred 路由单独设置加载中/失败界面（path 必须与 SearchPage 注解里的 path 一致）
      FluroConfig.setDeferredBuildersForPath(
        '/search?keyword=&page=1',
        loading: (context, _) => const Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('搜索模块加载中…'),
              ],
            ),
          ),
        ),
        error: (context, error, _) => Scaffold(
          appBar: AppBar(title: const Text('加载失败')),
          body: Center(child: Text('$error')),
        ),
      );

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
        handler: FluroHandler(handlerFunc: (_, __) => const CPage()),
      );

      // disableSwipeBack 示例：路由 define 上关闭侧滑返回（与 SwipeBackWrapper + iOS 系统左缘返回）
      FluroConfig.router.define(
        '/demo/no-swipe-back',
        handler: FluroHandler(
          handlerFunc: (_, __) => const NoSwipeBackDemoPage(
            title: '路由级 disableSwipeBack',
            hint:
                '本页通过 router.define(..., disableSwipeBack: true) 注册，'
                '转场为 inFromLeft。',
          ),
        ),
        transitionType: TransitionType.inFromLeft,
        disableSwipeBack: true,
      );
      // 路由本身不禁用；由 push 时传入 disableSwipeBack（需库内 matchRoute 传入该参数）
      FluroConfig.router.define(
        '/demo/swipe-push-override',
        handler: FluroHandler(
          handlerFunc: (_, __) => const NoSwipeBackDemoPage(
            title: 'push 级 disableSwipeBack',
            hint:
                '路由未设置 disableSwipeBack；通过 '
                'FluroConfig.push(..., disableSwipeBack: true) 单次跳转关闭侧滑返回。',
          ),
        ),
        transitionType: TransitionType.inFromLeft,
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
