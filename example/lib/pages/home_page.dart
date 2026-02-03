import 'package:flutter/material.dart';
import 'package:fluro_router_generate/fluro_router.dart';

@RouterAnnotation(
  path: '/home/:id',
  description: '首页',
  defaultParams: {'id': '-'},
  constructorParams: HandlerConstructorParams.pathParams,
)
class HomePage extends StatelessWidget {
  const HomePage({super.key, required this.id});
  final String id;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('首页 id=$id')),
      body: Center(
        child: Column( 
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('HomePage id: $id'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => FluroConfig.push('/detail/99', context: context),
              child: const Text('去详情页'),
            ),
          ],
        ),
      ),
    );
  }
}
