import 'platform_interface.dart';
import 'types.dart';

/// Share content to Instagram and Facebook from Flutter.
///
/// All methods are static. Usage:
/// ```dart
/// final result = await SocialSharePlus.instagramFeed(filePath: '/path/to/image.jpg');
/// switch (result) {
///   case ShareSuccess():
///     print('Shared!');
///   case ShareError(:final message):
///     print('Error: $message');
///   case ShareAppNotInstalled():
///     print('Instagram is not installed');
///   case ShareCancelled():
///     print('User cancelled');
/// }
/// ```
final class SocialSharePlus {
  const SocialSharePlus._();

  static SocialSharePlusPlatform get _platform => SocialSharePlusPlatform.instance;

  /// Check which supported social platforms are installed.
  static Future<Map<SocialPlatform, bool>> getInstalledApps() =>
      _platform.getInstalledApps();

  // === Instagram ===

  /// Share a text message via Instagram Direct.
  static Future<ShareResult> instagramDirect({required String message}) =>
      _platform.instagramDirect(message: message);

  /// Share a single image or video file to Instagram Feed.
  static Future<ShareResult> instagramFeed({
    required String filePath,
    String? message,
  }) =>
      _platform.instagramFeed(filePath: filePath, message: message);

  /// Share multiple files to Instagram Feed.
  ///
  /// On iOS, only the first file is shared.
  static Future<ShareResult> instagramFeedMultiple({
    required List<String> filePaths,
  }) =>
      _platform.instagramFeedMultiple(filePaths: filePaths);

  /// Share a video to Instagram Reels.
  static Future<ShareResult> instagramReels({required String videoPath}) =>
      _platform.instagramReels(videoPath: videoPath);

  /// Share to Instagram Story with optional sticker, background, and colors.
  static Future<ShareResult> instagramStory({required StoryConfig config}) =>
      _platform.instagramStory(config: config);

  // === Facebook ===

  /// Share photos to Facebook Feed with an optional hashtag.
  static Future<ShareResult> facebookFeed({
    required List<String> filePaths,
    String? hashtag,
  }) =>
      _platform.facebookFeed(filePaths: filePaths, hashtag: hashtag);

  /// Share to Facebook Story with optional sticker, background, and colors.
  static Future<ShareResult> facebookStory({required StoryConfig config}) =>
      _platform.facebookStory(config: config);
}
