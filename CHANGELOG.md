# Changelog

All notable changes to this package are documented here.

## 1.0.0

### Breaking changes

- Focused the public API on four supported flows: Instagram Feed, Instagram Stories, Facebook Feed, and Facebook Stories.
- Removed Instagram Direct, Reels, multi-file Instagram Feed, and system share APIs. Use share_plus for the generic system share sheet.
- Replaced the previous result/error types with typed ShareResult values: ShareCompleted, ShareLaunched, ShareCancelled, ShareUnavailable, and ShareFailed.
- Added stable ShareErrorCode values for invalid input, missing files, unsupported media, denied permissions, busy requests, and platform failures.
- Renamed the Facebook Feed parameter from filePaths to imagePaths and updated StoryConfig to use typed Color and Uri values.
- Raised the minimum supported environment to Dart 3.12, Flutter 3.44, Android API 24, and iOS 15.

### Added

- Added exact per-flow availability checks through ShareTarget and SocialSharePlus.isAvailable.
- Added validation for local file paths, media types, image counts, Story backgrounds, hashtags, App IDs, and Story video size.
- Added support for Instagram Feed images and videos.
- Added support for Facebook Feed sharing with one to six images and an optional hashtag.
- Added typed StoryConfig support for stickers, image/video backgrounds, gradient colors, and best-effort Story attribution metadata.
- Added exhaustive result handling suitable for Dart pattern matching.
- Added Android unit tests, Dart platform-channel tests, example widget tests, and an integration test covering availability for all supported targets.

### Android

- Upgraded the Facebook Android Share SDK to 18.2.3.
- Added a bundled, non-exported FileProvider with scoped app file/cache paths.
- Removed broad external storage sharing paths and copied external media into a private temporary cache before sharing.
- Moved media validation and file preparation off the main thread.
- Replaced bitmap decoding for Facebook Feed with URI-based SharePhoto sharing to reduce memory usage.
- Added temporary URI grants, ClipData, exact package checks, and cleanup of cached share files older than 24 hours.
- Fixed Facebook activity-result listener lifecycle handling and concurrent-request reporting.
- Added Android 11+ package visibility declarations for Instagram and Facebook targets.

### iOS

- Updated Facebook iOS SDK integration to 18.1.x with Swift Package Manager and CocoaPods support.
- Removed force-unwrap paths and improved native validation/error responses.
- Switched Instagram Feed Photos access to add-only permission.
- Moved media loading off the main thread.
- Added exact Instagram Feed, Instagram Stories, Facebook Feed, and Facebook Stories availability checks.
- Added local-only, expiring pasteboard data for Stories.
- Registered Facebook application and scene lifecycle callbacks through the plugin automatically.

### Privacy and security

- Disabled Meta automatic app-event logging by default.
- Disabled Meta advertising-ID collection by default.
- Removed the Android AD_ID permission by default.
- Added the plugin privacy manifest for iOS.
- Restricted Android shared files to read-only, non-exported FileProvider URIs.

### Tooling and documentation

- Updated Android build tooling to Kotlin 2.3.20, AGP 8.13.2, Java/Kotlin JVM 17, and compile SDK 36.
- Updated the example application for the v1 API and current Flutter tooling.
- Added CI coverage for Flutter 3.44.9 and 3.47.0, Android builds, iOS simulator builds, tests, analysis, formatting, and publish checks.
- Rewrote the README with complete Android/iOS installation, Meta configuration, usage, migration, troubleshooting, and release instructions.

## 0.2.0

- Added Swift Package Manager support for iOS while keeping CocoaPods compatibility.

## 0.1.0

- Updated README and tests.

## 0.0.4

- Added system sharing.

## 0.0.3

- Fixed a missing Flutter import in Swift.

## 0.0.2

- Refactored image handling for Facebook and Instagram.

## 0.0.1

- Initial Android and iOS release.
