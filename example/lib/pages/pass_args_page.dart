import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router.dart';

/// 传参场景：routeSettingsArguments 且**有** defaultParams
@RouterAnnotation(
  path: '/pass-args',
  description: 'RouteSettings.arguments 传参（有 defaultParams）',
  defaultParams: {'count': 0},
  constructorParams: HandlerConstructorParams.routeSettingsArguments,
)
class PassArgsPage extends StatelessWidget {
  const PassArgsPage({super.key, required this.title, required this.count});
  final String? title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title ?? "阿达")),
      body: Center(child: Text('PassArgsPage title=$title, count=$count')),
    );
  }
}
