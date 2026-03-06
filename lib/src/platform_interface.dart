import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel.dart';
import 'types.dart';

/// Platform interface for [SocialSharePlus].
///
/// Platform-specific implementations should extend this class rather than
/// implement it, to ensure forward-compatibility.
abstract class SocialSharePlusPlatform extends PlatformInterface {
  SocialSharePlusPlatform() : super(token: _token);

  static final Object _token = Object();

  static SocialSharePlusPlatform _instance = MethodChannelSocialSharePlus();

  /// The default instance of [SocialSharePlusPlatform] to use.
  static SocialSharePlusPlatform get instance => _instance;

  /// Platform-specific implementations should set this to their own
  /// platform-specific class that extends [SocialSharePlusPlatform].
  static set instance(SocialSharePlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Returns which social platforms are installed on the device.
  Future<Map<SocialPlatform, bool>> getInstalledApps() {
    throw UnimplementedError('getInstalledApps() has not been implemented.');
  }

  // === Instagram ===

  /// Share a text message via Instagram Direct.
  Future<ShareResult> instagramDirect({required String message}) {
    throw UnimplementedError('instagramDirect() has not been implemented.');
  }

  /// Share a single file to Instagram Feed.
  Future<ShareResult> instagramFeed({required String filePath, String? message}) {
    throw UnimplementedError('instagramFeed() has not been implemented.');
  }

  /// Share multiple files to Instagram Feed.
  Future<ShareResult> instagramFeedMultiple({required List<String> filePaths}) {
    throw UnimplementedError('instagramFeedMultiple() has not been implemented.');
  }

  /// Share a video to Instagram Reels.
  Future<ShareResult> instagramReels({required String videoPath}) {
    throw UnimplementedError('instagramReels() has not been implemented.');
  }

  /// Share to Instagram Story.
  Future<ShareResult> instagramStory({required StoryConfig config}) {
    throw UnimplementedError('instagramStory() has not been implemented.');
  }

  // === Facebook ===

  /// Share photos to Facebook Feed.
  Future<ShareResult> facebookFeed({required List<String> filePaths, String? hashtag}) {
    throw UnimplementedError('facebookFeed() has not been implemented.');
  }

  /// Share to Facebook Story.
  Future<ShareResult> facebookStory({required StoryConfig config}) {
    throw UnimplementedError('facebookStory() has not been implemented.');
  }
}
