import 'package:flutter/material.dart';

/// C 页面：业务处理完成后返回结果给 A。
class CPage extends StatelessWidget {
  const CPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('C - 业务页（返回结果）')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('点击按钮返回给上一页（A）'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('处理完成：返回 true'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('处理失败：返回 false'),
            ),
          ],
        ),
      ),
    );
  }
}
