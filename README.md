# flutter_social_share_plus

A Flutter plugin for sharing content to Instagram and Facebook on Android and iOS.

## Features

- **Instagram**: Direct, Feed (single/multiple), Reels, Stories
- **Facebook**: Feed (photos with hashtag), Stories
- Modern Dart 3.11+ API with sealed class results and exhaustive pattern matching

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_social_share_plus: ^latest
```

### Android Setup

Add a FileProvider to your `AndroidManifest.xml`:

```xml
<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="${applicationId}.provider"
    android:exported="false"
    android:grantUriPermissions="true">
    <meta-data
        android:name="android.support.FILE_PROVIDER_PATHS"
        android:resource="@xml/file_paths" />
</provider>
```

Create `android/app/src/main/res/xml/file_paths.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<paths>
    <cache-path name="cache" path="." />
    <external-path name="external" path="." />
</paths>
```

For Facebook Feed sharing, add your Facebook App ID to `AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id" />
```

### iOS Setup

Add URL schemes to your `Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram</string>
    <string>instagram-stories</string>
    <string>fb</string>
    <string>facebook-stories</string>
</array>
```

For Facebook, also add:

```xml
<key>FacebookAppID</key>
<string>YOUR_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_CLIENT_TOKEN</string>
```

Add photo library usage description:

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Required to share media to Instagram</string>
```

## Usage

```dart
import 'package:flutter_social_share_plus/flutter_social_share_plus.dart';

// Check installed apps
final apps = await SocialSharePlus.getInstalledApps();

// Share to Instagram Feed
final result = await SocialSharePlus.instagramFeed(filePath: '/path/to/image.jpg');

// Handle result with pattern matching
switch (result) {
  case ShareSuccess():
    print('Shared!');
  case ShareError(:final message):
    print('Error: $message');
  case ShareAppNotInstalled():
    print('App not installed');
  case ShareCancelled():
    print('Cancelled');
}

// Share to Instagram Story
await SocialSharePlus.instagramStory(
  config: StoryConfig(
    appId: 'YOUR_FACEBOOK_APP_ID',
    backgroundTopColor: '#FF5733',
    backgroundBottomColor: '#3366FF',
  ),
);

// Share to Facebook Feed
await SocialSharePlus.facebookFeed(
  filePaths: ['/path/to/photo.jpg'],
  hashtag: '#flutter',
);
```

## Additional Information

- Requires Facebook App ID for story sharing and Facebook feed sharing
- Instagram feed sharing on iOS saves media to Photo Library first
- Android requires FileProvider configuration for file URI sharing
