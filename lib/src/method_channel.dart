import 'package:flutter/services.dart';

import 'platform_interface.dart';
import 'types.dart';

/// Method-channel implementation of [SocialSharePlusPlatform].
final class MethodChannelSocialSharePlus extends SocialSharePlusPlatform {
  static const _channel = MethodChannel('flutter_social_share_plus');

  @override
  Future<bool> isAvailable(ShareTarget target) async {
    final response = await _invoke('isAvailable', {'target': target.name});
    return response is Map && response['available'] == true;
  }

  @override
  Future<ShareResult> instagramFeed({required String filePath}) =>
      _share('instagramFeed', {'filePath': filePath});

  @override
  Future<ShareResult> instagramStory({required StoryConfig config}) =>
      _share('instagramStory', _storyArguments(config));

  @override
  Future<ShareResult> facebookFeed({
    required List<String> imagePaths,
    String? hashtag,
  }) => _share('facebookFeed', {'imagePaths': imagePaths, 'hashtag': hashtag});

  @override
  Future<ShareResult> facebookStory({required StoryConfig config}) =>
      _share('facebookStory', _storyArguments(config));

  Future<ShareResult> _share(
    String method,
    Map<String, dynamic> arguments,
  ) async {
    try {
      return _parse(await _channel.invokeMethod<Object?>(method, arguments));
    } on PlatformException catch (error) {
      return ShareFailed(
        ShareErrorCode.platformError,
        error.message ?? error.code,
      );
    } on MissingPluginException catch (error) {
      return ShareFailed(
        ShareErrorCode.platformError,
        error.message ?? 'Plugin is not available',
      );
    }
  }

  Future<Object?> _invoke(String method, Map<String, dynamic> arguments) async {
    try {
      return await _channel.invokeMethod<Object?>(method, arguments);
    } on PlatformException {
      return null;
    } on MissingPluginException {
      return null;
    }
  }

  ShareResult _parse(Object? raw) {
    if (raw is! Map) {
      return ShareFailed(
        ShareErrorCode.platformError,
        'Malformed native response',
      );
    }

    final status = raw['status'];
    return switch (status) {
      'completed' => const ShareCompleted(),
      'launched' => const ShareLaunched(),
      'cancelled' => const ShareCancelled(),
      'unavailable' => const ShareUnavailable(),
      'failed' => ShareFailed(
        _parseErrorCode(raw['code']),
        raw['message']?.toString() ?? 'Share failed',
      ),
      _ => ShareFailed(
        ShareErrorCode.platformError,
        'Malformed native response',
      ),
    };
  }

  ShareErrorCode _parseErrorCode(Object? value) => switch (value) {
    'invalid_input' => ShareErrorCode.invalidInput,
    'file_not_found' => ShareErrorCode.fileNotFound,
    'unsupported_media' => ShareErrorCode.unsupportedMedia,
    'permission_denied' => ShareErrorCode.permissionDenied,
    'busy' => ShareErrorCode.busy,
    _ => ShareErrorCode.platformError,
  };
}

Map<String, dynamic> _storyArguments(StoryConfig config) => {
  'appId': config.appId,
  'stickerPath': config.stickerPath,
  'backgroundImagePath': config.backgroundImagePath,
  'backgroundVideoPath': config.backgroundVideoPath,
  'backgroundTopColor': _colorValue(config.backgroundTopColor),
  'backgroundBottomColor': _colorValue(config.backgroundBottomColor),
  'attributionUrl': config.attributionUrl?.toString(),
};

String? _colorValue(Color? color) {
  if (color == null) return null;
  final rgb = color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
