import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router.dart';

/// 传参场景：无参数 (constructorParams: none)
@RouterAnnotation(
  path: '/home',
  description: '首页（无参数）',
  module: 'main',
  constructorParams: HandlerConstructorParams.none,
)
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('首页')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('HomePage (无参数)'),
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
    );
  }
}
