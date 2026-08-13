import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'method_channel.dart';
import 'types.dart';

/// Platform interface for [SocialSharePlus].
abstract class SocialSharePlusPlatform extends PlatformInterface {
  SocialSharePlusPlatform() : super(token: _token);

  static final Object _token = Object();
  static SocialSharePlusPlatform _instance = MethodChannelSocialSharePlus();

  static SocialSharePlusPlatform get instance => _instance;

  static set instance(SocialSharePlusPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<bool> isAvailable(ShareTarget target) {
    throw UnimplementedError('isAvailable() has not been implemented.');
  }

  Future<ShareResult> instagramFeed({required String filePath}) {
    throw UnimplementedError('instagramFeed() has not been implemented.');
  }

  Future<ShareResult> instagramStory({required StoryConfig config}) {
    throw UnimplementedError('instagramStory() has not been implemented.');
  }

  Future<ShareResult> facebookFeed({
    required List<String> imagePaths,
    String? hashtag,
  }) {
    throw UnimplementedError('facebookFeed() has not been implemented.');
  }

  Future<ShareResult> facebookStory({required StoryConfig config}) {
    throw UnimplementedError('facebookStory() has not been implemented.');
  }
}
