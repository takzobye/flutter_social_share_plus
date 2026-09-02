import 'platform_interface.dart';
import 'types.dart';

/// Share local media to Instagram and Facebook.
final class SocialSharePlus {
  const SocialSharePlus._();

  static SocialSharePlusPlatform get _platform =>
      SocialSharePlusPlatform.instance;

  /// Returns whether [target] can receive the requested share operation.
  static Future<bool> isAvailable(ShareTarget target) =>
      _platform.isAvailable(target);

  /// Opens Instagram's media composer for one local image or video.
  static Future<ShareResult> instagramFeed({required String filePath}) =>
      _platform.instagramFeed(filePath: filePath);

  /// Opens Instagram Stories with [config].
  static Future<ShareResult> instagramStory({required StoryConfig config}) =>
      _platform.instagramStory(config: config);

  /// Opens Facebook's native share dialog for one to six local images.
  static Future<ShareResult> facebookFeed({
    required List<String> imagePaths,
    String? hashtag,
  }) => _platform.facebookFeed(imagePaths: imagePaths, hashtag: hashtag);

  /// Opens Facebook Stories with [config].
  static Future<ShareResult> facebookStory({required StoryConfig config}) =>
      _platform.facebookStory(config: config);
}
