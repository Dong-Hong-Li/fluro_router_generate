import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router.dart';

/// 传参场景：routeSettingsArguments 且**不写** defaultParams，参数名从构造函数推断
@RouterAnnotation(
  path: '/pass-args-no-defaults',
  description: 'RouteSettings.arguments 传参（无 defaultParams，从构造函数推断）',
  module: 'demo',
  constructorParams: HandlerConstructorParams.routeSettingsArguments,
)
class PassArgsNoDefaultsPage extends StatelessWidget {
  const PassArgsNoDefaultsPage({super.key, required this.message, required this.flag});
  final String message;
  final String flag;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(message)),
      body: Center(
        child: Text('PassArgsNoDefaultsPage message=$message, flag=$flag'),
      ),
    );
  }
}
