import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_social_share_plus/flutter_social_share_plus.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('getInstalledApps returns map', (WidgetTester tester) async {
    final apps = await SocialSharePlus.getInstalledApps();
    expect(apps, isA<Map<SocialPlatform, bool>>());
  });
}
