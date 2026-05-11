import 'package:flutter/material.dart';

/// 演示 [disableSwipeBack]：在 iOS 上可对比左缘返回是否被关闭。
class NoSwipeBackDemoPage extends StatelessWidget {
  const NoSwipeBackDemoPage({
    super.key,
    required this.title,
    required this.hint,
  });

  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                hint,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              Text(
                '请从屏幕左缘向右滑：若侧滑返回已禁用，页面不应被手势关闭；'
                '仍可使用下方按钮或 AppBar 返回。',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const Spacer(),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Navigator.pop 关闭'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
