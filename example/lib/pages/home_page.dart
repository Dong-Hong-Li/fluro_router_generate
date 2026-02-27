import 'package:example/router/route_guards.dart';
import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router.dart';

/// 传参场景：无参数 (constructorParams: none)
@RouterAnnotation(
  path: '/home',
  description: '首页（无参数）',
  module: 'main',
  constructorParams: HandlerConstructorParams.none,
)
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('HomePage (无参数)'),
              const SizedBox(height: 8),
              // 路由守卫演示：未登录时访问详情/帖子/搜索会被重定向回首页
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('登录状态（守卫）：', style: Theme.of(context).textTheme.bodyMedium),
                  Switch(
                    value: isLoggedIn,
                    onChanged: (v) => setState(() => isLoggedIn = v),
                  ),
                  Text(isLoggedIn ? '已登录' : '未登录', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
              const SizedBox(height: 16),
              FilledButton(
              onPressed: () => FluroConfig.push('/detail/99', context: context),
              child: const Text('去详情页(单路径参数)'),
            ),
            FilledButton(
              onPressed: () =>
                  FluroConfig.push('/user/1/post/2', context: context),
              child: const Text('去帖子页(多路径参数)'),
            ),
            FilledButton(
              onPressed: () => FluroConfig.push(
                '/search?keyword=test&page=1',
                context: context,
              ),
              child: const Text('去搜索页(查询参数)'),
            ),
            FilledButton(
              onPressed: () => FluroConfig.push(
                '/pass-args',
                context: context,
                routeSettings: RouteSettings(
                  name: '/pass-args',
                  arguments: {'title': '传入标题', 'count': 42},
                ),
              ),
              child: const Text('去 PassArgs(routeSettings 有 defaultParams)'),
            ),
            FilledButton(
              onPressed: () => FluroConfig.push(
                '/pass-args-no-defaults',
                context: context,
                routeSettings: RouteSettings(
                  name: '/pass-args-no-defaults',
                  arguments: {'message': '你好', 'flag': 'true'},
                ),
              ),
              child: const Text(
                '去 PassArgsNoDefaults(routeSettings 无 defaultParams)',
              ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}
