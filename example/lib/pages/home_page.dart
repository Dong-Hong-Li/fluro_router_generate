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
              // 路由守卫演示：未登录时访问受保护页面会被「挂起」并先去认证页
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('认证守卫：', style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    'guard1=${guard1Passed ? "OK" : "NO"}  guard2=${guard2Passed ? "OK" : "NO"}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: () => setState(() {
                      guard1Passed = false;
                      guard2Passed = false;
                    }),
                    child: const Text('重置认证'),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              /// A -> C（await 返回值）模拟测试入口
              FilledButton(
                onPressed: () async {
                  final result = await FluroConfig.push<bool>(
                    '/c',
                    context: context,
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('A 收到 C 返回：$result')));
                },
                child: const Text('A -> C（await C 返回值）'),
              ),

              FilledButton(
                onPressed: () =>
                    FluroConfig.push('/detail/99', context: context),
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
                child: const Text('去搜索页(查询参数, deferred)'),
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
