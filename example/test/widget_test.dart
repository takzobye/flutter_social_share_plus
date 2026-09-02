import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_social_share_plus_example/main.dart';

void main() {
  testWidgets('App renders share page', (WidgetTester tester) async {
    await tester.pumpWidget(const ExampleApp());
    expect(find.text('Social Share Plus'), findsOneWidget);
    expect(find.text('Instagram'), findsOneWidget);
    expect(find.text('Facebook'), findsOneWidget);
    expect(find.text('Pick image or video'), findsOneWidget);
  });
}
