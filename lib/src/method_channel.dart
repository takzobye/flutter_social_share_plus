import 'package:flutter/services.dart';

import 'platform_interface.dart';
import 'types.dart';

/// Method channel implementation of [SocialSharePlusPlatform].
final class MethodChannelSocialSharePlus extends SocialSharePlusPlatform {
  static const _channel = MethodChannel('flutter_social_share_plus');

  ShareResult _parseResult(String? raw) => switch (raw) {
        'SUCCESS' => const ShareSuccess(),
        'APP_NOT_INSTALLED' => const ShareAppNotInstalled(),
        'CANCELLED' => const ShareCancelled(),
        final msg when msg != null && msg.startsWith('ERROR:') =>
          ShareError(msg.substring(6)),
        _ => ShareError(raw ?? 'Unknown error'),
      };

  @override
  Future<Map<SocialPlatform, bool>> getInstalledApps() async {
    final result = await _channel.invokeMapMethod<String, bool>('getInstalledApps');
    return {
      SocialPlatform.instagram: result?['instagram'] ?? false,
      SocialPlatform.facebook: result?['facebook'] ?? false,
    };
  }

  // === Instagram ===

  @override
  Future<ShareResult> instagramDirect({required String message}) async {
    final result = await _channel.invokeMethod<String>(
      'instagramDirect',
      {'message': message},
    );
    return _parseResult(result);
  }

  @override
  Future<ShareResult> instagramFeed({required String filePath, String? message}) async {
    final result = await _channel.invokeMethod<String>(
      'instagramFeed',
      {'filePath': filePath, 'message': message},
    );
    return _parseResult(result);
  }

  @override
  Future<ShareResult> instagramFeedMultiple({required List<String> filePaths}) async {
    final result = await _channel.invokeMethod<String>(
      'instagramFeedMultiple',
      {'filePaths': filePaths},
    );
    return _parseResult(result);
  }

  @override
  Future<ShareResult> instagramReels({required String videoPath}) async {
    final result = await _channel.invokeMethod<String>(
      'instagramReels',
      {'videoPath': videoPath},
    );
    return _parseResult(result);
  }

  @override
  Future<ShareResult> instagramStory({required StoryConfig config}) async {
    final result = await _channel.invokeMethod<String>(
      'instagramStory',
      config.toMap(),
    );
    return _parseResult(result);
  }

  // === Facebook ===

  @override
  Future<ShareResult> facebookFeed({required List<String> filePaths, String? hashtag}) async {
    final result = await _channel.invokeMethod<String>(
      'facebookFeed',
      {'filePaths': filePaths, 'hashtag': hashtag},
    );
    return _parseResult(result);
  }

  @override
  Future<ShareResult> facebookStory({required StoryConfig config}) async {
    final result = await _channel.invokeMethod<String>(
      'facebookStory',
      config.toMap(),
    );
    return _parseResult(result);
  }
}
