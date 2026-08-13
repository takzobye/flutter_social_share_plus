import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_social_share_plus/flutter_social_share_plus.dart';
import 'package:flutter_social_share_plus/src/method_channel.dart';
import 'package:flutter_social_share_plus/src/platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockSocialSharePlusPlatform
    with MockPlatformInterfaceMixin
    implements SocialSharePlusPlatform {
  @override
  Future<bool> isAvailable(ShareTarget target) async =>
      target == ShareTarget.instagramFeed;

  @override
  Future<ShareResult> instagramFeed({required String filePath}) async =>
      const ShareLaunched();

  @override
  Future<ShareResult> instagramStory({required StoryConfig config}) async =>
      const ShareLaunched();

  @override
  Future<ShareResult> facebookFeed({
    required List<String> imagePaths,
    String? hashtag,
  }) async => const ShareCompleted();

  @override
  Future<ShareResult> facebookStory({required StoryConfig config}) async =>
      const ShareLaunched();
}

class ExtendsSocialSharePlusPlatform extends SocialSharePlusPlatform {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('flutter_social_share_plus');

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('SocialSharePlus', () {
    late SocialSharePlusPlatform originalPlatform;

    setUp(() {
      originalPlatform = SocialSharePlusPlatform.instance;
      SocialSharePlusPlatform.instance = MockSocialSharePlusPlatform();
    });

    tearDown(() => SocialSharePlusPlatform.instance = originalPlatform);

    test('delegates availability and share calls', () async {
      expect(
        await SocialSharePlus.isAvailable(ShareTarget.instagramFeed),
        isTrue,
      );
      expect(
        await SocialSharePlus.instagramFeed(filePath: 'image.jpg'),
        isA<ShareLaunched>(),
      );
      expect(
        await SocialSharePlus.facebookFeed(imagePaths: ['image.jpg']),
        isA<ShareCompleted>(),
      );
    });
  });

  group('MethodChannelSocialSharePlus', () {
    late MethodChannelSocialSharePlus platform;

    setUp(() => platform = MethodChannelSocialSharePlus());

    test('checks an exact target', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'isAvailable');
            expect(call.arguments, {'target': 'facebookStory'});
            return {'available': true};
          });

      expect(await platform.isAvailable(ShareTarget.facebookStory), isTrue);
    });

    for (final status in <(String, Matcher)>[
      ('completed', isA<ShareCompleted>()),
      ('launched', isA<ShareLaunched>()),
      ('cancelled', isA<ShareCancelled>()),
      ('unavailable', isA<ShareUnavailable>()),
    ]) {
      test('parses ${status.$1}', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (_) async {
              return {'status': status.$1};
            });

        expect(await platform.instagramFeed(filePath: 'image.jpg'), status.$2);
      });
    }

    test('parses a typed failure', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async {
            return {
              'status': 'failed',
              'code': 'file_not_found',
              'message': 'Missing image',
            };
          });

      final result = await platform.instagramFeed(filePath: 'image.jpg');
      expect(result, isA<ShareFailed>());
      expect((result as ShareFailed).code, ShareErrorCode.fileNotFound);
      expect(result.message, 'Missing image');
    });

    test('maps malformed responses to platform errors', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (_) async => 'SUCCESS');

      final result = await platform.instagramFeed(filePath: 'image.jpg');
      expect(result, isA<ShareFailed>());
      expect((result as ShareFailed).code, ShareErrorCode.platformError);
    });

    test('sends the v1 feed arguments', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'facebookFeed');
            expect(call.arguments, {
              'imagePaths': ['one.jpg', 'two.png'],
              'hashtag': '#flutter',
            });
            return {'status': 'completed'};
          });

      final result = await platform.facebookFeed(
        imagePaths: ['one.jpg', 'two.png'],
        hashtag: '#flutter',
      );
      expect(result, isA<ShareCompleted>());
    });

    test('serializes StoryConfig internally', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
            expect(call.method, 'instagramStory');
            expect(call.arguments, {
              'appId': '123',
              'stickerPath': '/sticker.png',
              'backgroundImagePath': '/background.jpg',
              'backgroundVideoPath': null,
              'backgroundTopColor': '#F44336',
              'backgroundBottomColor': null,
              'attributionUrl': 'https://example.com/story',
            });
            return {'status': 'launched'};
          });

      final result = await platform.instagramStory(
        config: StoryConfig(
          appId: '123',
          stickerPath: '/sticker.png',
          backgroundImagePath: '/background.jpg',
          backgroundTopColor: Colors.red,
          attributionUrl: Uri.parse('https://example.com/story'),
        ),
      );
      expect(result, isA<ShareLaunched>());
    });
  });

  test('base platform methods remain unimplemented', () {
    final platform = ExtendsSocialSharePlusPlatform();
    expect(
      () => platform.isAvailable(ShareTarget.instagramFeed),
      throwsUnimplementedError,
    );
    expect(
      () => platform.instagramFeed(filePath: ''),
      throwsUnimplementedError,
    );
    expect(
      () => platform.instagramStory(config: const StoryConfig(appId: '1')),
      throwsUnimplementedError,
    );
    expect(
      () => platform.facebookFeed(imagePaths: []),
      throwsUnimplementedError,
    );
    expect(
      () => platform.facebookStory(config: const StoryConfig(appId: '1')),
      throwsUnimplementedError,
    );
  });

  group('ShareConfig and results', () {
    test('StoryConfig exposes typed values', () {
      final config = StoryConfig(
        appId: '123',
        backgroundTopColor: Colors.red,
        attributionUrl: Uri.parse('https://example.com'),
      );
      expect(config.hasContent, isFalse);
      expect(config.backgroundTopColor, Colors.red);
      expect(config.attributionUrl, Uri.parse('https://example.com'));
    });

    test('result strings are stable', () {
      expect(const ShareCompleted().toString(), 'ShareCompleted');
      expect(const ShareLaunched().toString(), 'ShareLaunched');
      expect(const ShareUnavailable().toString(), 'ShareUnavailable');
      expect(const ShareCancelled().toString(), 'ShareCancelled');
      expect(
        const ShareFailed(ShareErrorCode.busy, 'Busy').toString(),
        'ShareFailed(ShareErrorCode.busy, Busy)',
      );
    });
  });
}
