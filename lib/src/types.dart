/// Result of a social share operation.
sealed class ShareResult {
  const ShareResult();

  /// Whether the share completed successfully.
  bool get isSuccess => this is ShareSuccess;
}

/// The share completed successfully.
final class ShareSuccess extends ShareResult {
  const ShareSuccess();

  @override
  String toString() => 'ShareSuccess';
}

/// The share failed with an error.
final class ShareError extends ShareResult {
  const ShareError(this.message);

  /// A description of what went wrong.
  final String message;

  @override
  String toString() => 'ShareError($message)';
}

/// The target app is not installed on the device.
final class ShareAppNotInstalled extends ShareResult {
  const ShareAppNotInstalled();

  @override
  String toString() => 'ShareAppNotInstalled';
}

/// The user cancelled the share.
final class ShareCancelled extends ShareResult {
  const ShareCancelled();

  @override
  String toString() => 'ShareCancelled';
}

/// Social platforms supported by this package.
enum SocialPlatform {
  instagram,
  facebook;
}

/// Configuration for sharing to Instagram or Facebook Stories.
final class StoryConfig {
  const StoryConfig({
    required this.appId,
    this.stickerImage,
    this.backgroundImage,
    this.backgroundVideo,
    this.backgroundTopColor,
    this.backgroundBottomColor,
    this.attributionURL,
  });

  /// Your Facebook App ID (required by both Instagram and Facebook).
  final String appId;

  /// Absolute file path to a sticker image overlay.
  final String? stickerImage;

  /// Absolute file path to a background image.
  final String? backgroundImage;

  /// Absolute file path to a background video.
  final String? backgroundVideo;

  /// Hex color string for the top gradient (e.g. "#FF0000").
  final String? backgroundTopColor;

  /// Hex color string for the bottom gradient (e.g. "#0000FF").
  final String? backgroundBottomColor;

  /// URL attributed to the story content.
  final String? attributionURL;

  Map<String, String?> toMap() => {
        'appId': appId,
        'stickerImage': stickerImage,
        'backgroundImage': backgroundImage,
        'backgroundVideo': backgroundVideo,
        'backgroundTopColor': backgroundTopColor,
        'backgroundBottomColor': backgroundBottomColor,
        'attributionURL': attributionURL,
      };
}
