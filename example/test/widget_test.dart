import 'package:example/main.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app boots with generated routes and deferred entry button', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.text('HomePage (无参数)'), findsOneWidget);
    expect(find.text('去搜索页(查询参数, deferred)'), findsOneWidget);
  });
}
