import 'package:flutter/material.dart';

/// A destination supported by the plugin.
enum ShareTarget { instagramFeed, instagramStory, facebookFeed, facebookStory }

/// The result of a share request.
sealed class ShareResult {
  const ShareResult();
}

/// The Facebook share dialog reported that sharing completed.
final class ShareCompleted extends ShareResult {
  const ShareCompleted();

  @override
  String toString() => 'ShareCompleted';
}

/// The target app opened, but it cannot report whether publishing completed.
final class ShareLaunched extends ShareResult {
  const ShareLaunched();

  @override
  String toString() => 'ShareLaunched';
}

/// The user cancelled the share dialog.
final class ShareCancelled extends ShareResult {
  const ShareCancelled();

  @override
  String toString() => 'ShareCancelled';
}

/// The requested target or feature is unavailable on this device.
final class ShareUnavailable extends ShareResult {
  const ShareUnavailable();

  @override
  String toString() => 'ShareUnavailable';
}

/// A share request failed before or during handoff.
final class ShareFailed extends ShareResult {
  const ShareFailed(this.code, this.message);

  final ShareErrorCode code;
  final String message;

  @override
  String toString() => 'ShareFailed($code, $message)';
}

/// Stable error categories returned by native implementations.
enum ShareErrorCode {
  invalidInput,
  fileNotFound,
  unsupportedMedia,
  permissionDenied,
  busy,
  platformError,
}

/// Configuration for sharing to Instagram or Facebook Stories.
final class StoryConfig {
  const StoryConfig({
    required this.appId,
    this.stickerPath,
    this.backgroundImagePath,
    this.backgroundVideoPath,
    this.backgroundTopColor,
    this.backgroundBottomColor,
    this.attributionUrl,
  });

  final String appId;
  final String? stickerPath;
  final String? backgroundImagePath;
  final String? backgroundVideoPath;
  final Color? backgroundTopColor;
  final Color? backgroundBottomColor;
  final Uri? attributionUrl;

  bool get hasBackground =>
      backgroundImagePath != null || backgroundVideoPath != null;

  bool get hasContent => hasBackground || stickerPath != null;
}
