import 'package:flutter/material.dart';

/// B 页面：模拟身份认证页（例如三方登录）。
///
/// - 认证成功：`Navigator.pop(context, true)`
/// - 认证失败：`Navigator.pop(context, false)`
class AuthPage extends StatelessWidget {
  const AuthPage({
    super.key,
    required this.title,
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('这里模拟三方登录/认证流程'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('认证通过（pop true）'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('认证失败（pop false）'),
            ),
          ],
        ),
      ),
    );
  }
}

