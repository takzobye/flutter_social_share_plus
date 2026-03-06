import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_social_share_plus/flutter_social_share_plus.dart';
import 'package:flutter_social_share_plus/src/platform_interface.dart';
import 'package:flutter_social_share_plus/src/method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSocialSharePlusPlatform
    with MockPlatformInterfaceMixin
    implements SocialSharePlusPlatform {
  @override
  Future<Map<SocialPlatform, bool>> getInstalledApps() async => {
        SocialPlatform.instagram: true,
        SocialPlatform.facebook: false,
      };

  @override
  Future<ShareResult> instagramDirect({required String message}) async =>
      const ShareSuccess();

  @override
  Future<ShareResult> instagramFeed({required String filePath, String? message}) async =>
      const ShareSuccess();

  @override
  Future<ShareResult> instagramFeedMultiple({required List<String> filePaths}) async =>
      const ShareSuccess();

  @override
  Future<ShareResult> instagramReels({required String videoPath}) async =>
      const ShareSuccess();

  @override
  Future<ShareResult> instagramStory({required StoryConfig config}) async =>
      const ShareSuccess();

  @override
  Future<ShareResult> facebookFeed({required List<String> filePaths, String? hashtag}) async =>
      const ShareAppNotInstalled();

  @override
  Future<ShareResult> facebookStory({required StoryConfig config}) async =>
      const ShareAppNotInstalled();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SocialSharePlus', () {
    late SocialSharePlusPlatform originalPlatform;

    setUp(() {
      originalPlatform = SocialSharePlusPlatform.instance;
      SocialSharePlusPlatform.instance = MockSocialSharePlusPlatform();
    });

    tearDown(() {
      SocialSharePlusPlatform.instance = originalPlatform;
    });

    test('getInstalledApps returns platform results', () async {
      final apps = await SocialSharePlus.getInstalledApps();
      expect(apps[SocialPlatform.instagram], true);
      expect(apps[SocialPlatform.facebook], false);
    });

    test('instagramDirect returns ShareSuccess', () async {
      final result = await SocialSharePlus.instagramDirect(message: 'test');
      expect(result, isA<ShareSuccess>());
      expect(result.isSuccess, true);
    });

    test('facebookFeed returns ShareAppNotInstalled', () async {
      final result = await SocialSharePlus.facebookFeed(filePaths: ['/test.jpg']);
      expect(result, isA<ShareAppNotInstalled>());
      expect(result.isSuccess, false);
    });

    test('ShareResult pattern matching works', () async {
      final result = await SocialSharePlus.instagramDirect(message: 'test');
      final message = switch (result) {
        ShareSuccess() => 'success',
        ShareError(:final message) => 'error: $message',
        ShareAppNotInstalled() => 'not installed',
        ShareCancelled() => 'cancelled',
      };
      expect(message, 'success');
    });

    test('default platform is MethodChannel', () {
      expect(originalPlatform, isA<MethodChannelSocialSharePlus>());
    });
  });

  group('StoryConfig', () {
    test('toMap includes all fields', () {
      const config = StoryConfig(
        appId: '123',
        stickerImage: '/sticker.png',
        backgroundTopColor: '#FF0000',
      );
      final map = config.toMap();
      expect(map['appId'], '123');
      expect(map['stickerImage'], '/sticker.png');
      expect(map['backgroundTopColor'], '#FF0000');
      expect(map['backgroundImage'], isNull);
    });
  });

  group('ShareResult', () {
    test('ShareError has message', () {
      const error = ShareError('something failed');
      expect(error.message, 'something failed');
      expect(error.toString(), 'ShareError(something failed)');
    });

    test('isSuccess returns correctly', () {
      expect(const ShareSuccess().isSuccess, true);
      expect(const ShareError('x').isSuccess, false);
      expect(const ShareAppNotInstalled().isSuccess, false);
      expect(const ShareCancelled().isSuccess, false);
    });
  });
}
