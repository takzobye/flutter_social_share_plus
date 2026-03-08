import 'package:flutter/services.dart';
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
  Future<ShareResult> instagramFeed({
    required String filePath,
    String? message,
  }) async => const ShareSuccess();

  @override
  Future<ShareResult> instagramFeedMultiple({
    required List<String> filePaths,
  }) async => const ShareSuccess();

  @override
  Future<ShareResult> instagramReels({required String videoPath}) async =>
      const ShareSuccess();

  @override
  Future<ShareResult> instagramStory({required StoryConfig config}) async =>
      const ShareSuccess();

  @override
  Future<ShareResult> facebookFeed({
    required List<String> filePaths,
    String? hashtag,
  }) async => const ShareAppNotInstalled();

  @override
  Future<ShareResult> facebookStory({required StoryConfig config}) async =>
      const ShareAppNotInstalled();

  @override
  Future<ShareResult> shareSystem({
    String? text,
    List<String>? filePaths,
    String? subject,
  }) async => const ShareSuccess();
}

class ExtendsSocialSharePlusPlatform extends SocialSharePlusPlatform {}

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
    });

    test('instagramFeed returns ShareSuccess', () async {
      final result = await SocialSharePlus.instagramFeed(filePath: '/test.jpg');
      expect(result, isA<ShareSuccess>());
    });

    test('instagramFeedMultiple returns ShareSuccess', () async {
      final result = await SocialSharePlus.instagramFeedMultiple(
        filePaths: ['/test.jpg'],
      );
      expect(result, isA<ShareSuccess>());
    });

    test('instagramReels returns ShareSuccess', () async {
      final result = await SocialSharePlus.instagramReels(
        videoPath: '/test.mp4',
      );
      expect(result, isA<ShareSuccess>());
    });

    test('instagramStory returns ShareSuccess', () async {
      final result = await SocialSharePlus.instagramStory(
        config: const StoryConfig(appId: '123'),
      );
      expect(result, isA<ShareSuccess>());
    });

    test('facebookFeed returns ShareAppNotInstalled', () async {
      final result = await SocialSharePlus.facebookFeed(
        filePaths: ['/test.jpg'],
      );
      expect(result, isA<ShareAppNotInstalled>());
    });

    test('facebookStory returns ShareAppNotInstalled', () async {
      final result = await SocialSharePlus.facebookStory(
        config: const StoryConfig(appId: '123'),
      );
      expect(result, isA<ShareAppNotInstalled>());
    });

    test('shareSystem returns ShareSuccess', () async {
      final result = await SocialSharePlus.shareSystem(text: 'test');
      expect(result, isA<ShareSuccess>());
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

  group('MethodChannelSocialSharePlus', () {
    const channel = MethodChannel('flutter_social_share_plus');
    late MethodChannelSocialSharePlus platform;

    setUp(() {
      platform = MethodChannelSocialSharePlus();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('getInstalledApps decodes successfully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            expect(methodCall.method, 'getInstalledApps');
            return <String, bool>{'instagram': true, 'facebook': false};
          });

      final apps = await platform.getInstalledApps();
      expect(apps[SocialPlatform.instagram], true);
      expect(apps[SocialPlatform.facebook], false);
    });

    test('getInstalledApps decodes null result gracefully', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
            return null;
          });

      final apps = await platform.getInstalledApps();
      expect(apps[SocialPlatform.instagram], false);
      expect(apps[SocialPlatform.facebook], false);
    });

    group('Responses parsing', () {
      void mockResponse(String? response) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              return response;
            });
      }

      test('SUCCESS -> ShareSuccess', () async {
        mockResponse('SUCCESS');
        expect(
          await platform.instagramDirect(message: ''),
          isA<ShareSuccess>(),
        );
      });

      test('APP_NOT_INSTALLED -> ShareAppNotInstalled', () async {
        mockResponse('APP_NOT_INSTALLED');
        expect(
          await platform.instagramDirect(message: ''),
          isA<ShareAppNotInstalled>(),
        );
      });

      test('CANCELLED -> ShareCancelled', () async {
        mockResponse('CANCELLED');
        expect(
          await platform.instagramDirect(message: ''),
          isA<ShareCancelled>(),
        );
      });

      test('ERROR: raw message -> ShareError', () async {
        mockResponse('ERROR: invalid payload');
        final result = await platform.instagramDirect(message: '');
        expect(result, isA<ShareError>());
        expect((result as ShareError).message, ' invalid payload');
      });

      test('Unknown string -> ShareError', () async {
        mockResponse('WEIRD_STRING');
        final result = await platform.instagramDirect(message: '');
        expect(result, isA<ShareError>());
        expect((result as ShareError).message, 'WEIRD_STRING');
      });

      test('Null string -> ShareError', () async {
        mockResponse(null);
        final result = await platform.instagramDirect(message: '');
        expect(result, isA<ShareError>());
        expect((result as ShareError).message, 'Unknown error');
      });
    });

    group('Method invocation parameters', () {
      Future<void> testMethod(
        String expectedMethod,
        Map<String, dynamic> expectedArgs,
        Future<void> Function() invoker,
      ) async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
              expect(methodCall.method, expectedMethod);
              expect(methodCall.arguments, expectedArgs);
              return 'SUCCESS';
            });
        await invoker();
      }

      test(
        'instagramDirect',
        () => testMethod('instagramDirect', {
          'message': 'hi',
        }, () => platform.instagramDirect(message: 'hi')),
      );

      test(
        'instagramFeed',
        () => testMethod(
          'instagramFeed',
          {'filePath': 'file.jpg', 'message': 'hi'},
          () => platform.instagramFeed(filePath: 'file.jpg', message: 'hi'),
        ),
      );

      test(
        'instagramFeed with null message',
        () => testMethod(
          'instagramFeed',
          {'filePath': 'file.jpg', 'message': null},
          () => platform.instagramFeed(filePath: 'file.jpg', message: null),
        ),
      );

      test(
        'instagramFeedMultiple',
        () => testMethod(
          'instagramFeedMultiple',
          {
            'filePaths': ['file.jpg'],
          },
          () => platform.instagramFeedMultiple(filePaths: ['file.jpg']),
        ),
      );

      test(
        'instagramReels',
        () => testMethod('instagramReels', {
          'videoPath': 'video.mp4',
        }, () => platform.instagramReels(videoPath: 'video.mp4')),
      );

      test('instagramStory', () {
        const config = StoryConfig(appId: '123', backgroundTopColor: '#000');
        return testMethod(
          'instagramStory',
          config.toMap(),
          () => platform.instagramStory(config: config),
        );
      });

      test(
        'facebookFeed',
        () => testMethod(
          'facebookFeed',
          {
            'filePaths': ['file.jpg'],
            'hashtag': '#test',
          },
          () =>
              platform.facebookFeed(filePaths: ['file.jpg'], hashtag: '#test'),
        ),
      );

      test('facebookStory', () {
        const config = StoryConfig(appId: '123', backgroundTopColor: '#000');
        return testMethod(
          'facebookStory',
          config.toMap(),
          () => platform.facebookStory(config: config),
        );
      });

      test(
        'shareSystem',
        () => testMethod('shareSystem', {
          'text': 'hi',
          'filePaths': null,
          'subject': null,
        }, () => platform.shareSystem(text: 'hi')),
      );
    });
  });

  group('SocialSharePlusPlatform base class', () {
    test('Throws UnimplementedError', () async {
      final base = ExtendsSocialSharePlusPlatform();
      expect(() => base.getInstalledApps(), throwsUnimplementedError);
      expect(() => base.instagramDirect(message: ''), throwsUnimplementedError);
      expect(() => base.instagramFeed(filePath: ''), throwsUnimplementedError);
      expect(
        () => base.instagramFeedMultiple(filePaths: []),
        throwsUnimplementedError,
      );
      expect(
        () => base.instagramReels(videoPath: ''),
        throwsUnimplementedError,
      );
      expect(
        () => base.instagramStory(config: const StoryConfig(appId: '1')),
        throwsUnimplementedError,
      );
      expect(() => base.facebookFeed(filePaths: []), throwsUnimplementedError);
      expect(
        () => base.facebookStory(config: const StoryConfig(appId: '1')),
        throwsUnimplementedError,
      );
      expect(() => base.shareSystem(), throwsUnimplementedError);
    });
  });

  group('StoryConfig', () {
    test('toMap includes all fields', () {
      const config = StoryConfig(
        appId: '123',
        stickerImage: '/sticker.png',
        backgroundTopColor: '#FF0000',
        backgroundImage: '/bg.png',
        backgroundVideo: '/bg.mp4',
        backgroundBottomColor: '#000000',
        attributionURL: 'http://example.com',
      );
      final map = config.toMap();
      expect(map['appId'], '123');
      expect(map['stickerImage'], '/sticker.png');
      expect(map['backgroundImage'], '/bg.png');
      expect(map['backgroundVideo'], '/bg.mp4');
      expect(map['backgroundTopColor'], '#FF0000');
      expect(map['backgroundBottomColor'], '#000000');
      expect(map['attributionURL'], 'http://example.com');
    });

    test('toMap with missing fields has nulls', () {
      const config = StoryConfig(appId: '123');
      final map = config.toMap();
      expect(map['stickerImage'], isNull);
    });
  });

  group('ShareResult', () {
    test('ShareSuccess', () {
      expect(const ShareSuccess().toString(), 'ShareSuccess');
    });

    test('ShareAppNotInstalled', () {
      expect(const ShareAppNotInstalled().toString(), 'ShareAppNotInstalled');
    });

    test('ShareCancelled', () {
      expect(const ShareCancelled().toString(), 'ShareCancelled');
    });

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
