import 'package:flutter_social_share_plus/flutter_social_share_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('availability returns one value for every supported target', (
    _,
  ) async {
    for (final target in ShareTarget.values) {
      expect(await SocialSharePlus.isAvailable(target), isA<bool>());
    }
  });
}
