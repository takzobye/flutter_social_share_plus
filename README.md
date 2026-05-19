# flutter_social_share_plus

A Flutter plugin for sharing content to Instagram and Facebook on Android and iOS.

## Features

| Feature | Android | iOS |
|:--------|:-------:|:---:|
| Instagram Direct (text) | ✅ | ✅ |
| Instagram Feed (image/video) | ✅ | ✅ |
| Instagram Feed (multiple files) | ✅ | ✅ |
| Instagram Reels (video) | ✅ | ✅ |
| Instagram Stories | ✅ | ✅ |
| Facebook Feed (photos + hashtag) | ✅ | ✅ |
| Facebook Stories | ✅ | ✅ |
| System Share Sheet | ✅ | ✅ |
| Check installed apps | ✅ | ✅ |

## Installation

```yaml
dependencies:
  flutter_social_share_plus: ^0.1.0
```

---

## Android Setup

### 1. Add Facebook SDK dependency

In your app's `android/app/build.gradle`:

```gradle
dependencies {
    implementation 'com.facebook.android:facebook-android-sdk:latest.release'
}
```

### 2. Add FileProvider

In `android/app/src/main/AndroidManifest.xml`, add inside `<application>`:

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

### 3. Register Facebook App (required for Facebook features)

Create `android/app/src/main/res/values/strings.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
    <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
</resources>
```

> Get your **App ID** and **Client Token** from [Meta for Developers](https://developers.facebook.com) → Your App → Settings → Basic / Advanced → Security.

Add inside `<application>` in `AndroidManifest.xml`:

```xml
<meta-data
    android:name="com.facebook.sdk.ApplicationId"
    android:value="@string/facebook_app_id" />
<meta-data
    android:name="com.facebook.sdk.ClientToken"
    android:value="@string/facebook_client_token" />
<activity
    android:name="com.facebook.FacebookActivity"
    android:configChanges="keyboard|keyboardHidden|screenLayout|screenSize|orientation"
    android:label="@string/app_name" />
<provider
    android:name="com.facebook.FacebookContentProvider"
    android:authorities="com.facebook.app.FacebookContentProvider${facebook_app_id}"
    android:exported="true" />
```

---

## iOS Setup

**Minimum Flutter version: 3.41.0**
**Minimum deployment target: iOS 15.0**

The Facebook SDK (`FBSDKCoreKit` and `FBSDKShareKit`) is included automatically through Swift Package Manager on Flutter projects with SPM enabled, and CocoaPods remains supported for projects that have not migrated yet.

### 1. Add URL schemes to `Info.plist`

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>fbYOUR_FACEBOOK_APP_ID</string>
        </array>
    </dict>
</array>

<key>LSApplicationQueriesSchemes</key>
<array>
    <string>instagram</string>
    <string>instagram-stories</string>
    <string>fb</string>
    <string>fb-messenger</string>
    <string>facebook-stories</string>
    <string>fbauth2</string>
    <string>fbapi</string>
    <string>fbshareextension</string>
</array>
```

### 2. Add Facebook credentials to `Info.plist`

```xml
<key>FacebookAppID</key>
<string>YOUR_FACEBOOK_APP_ID</string>
<key>FacebookClientToken</key>
<string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
<key>FacebookDisplayName</key>
<string>YOUR_APP_NAME</string>
```

### 3. Add photo library usage description to `Info.plist`

Required for Instagram Feed sharing (media is saved to the photo library first):

```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>Required to share media to Instagram</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>Required to save media for sharing</string>
```

### 4. Initialize Facebook SDK in `AppDelegate.swift`

```swift
import UIKit
import Flutter
import FBSDKCoreKit

@main
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(
        _ app: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(app, open: url, options: options)
    }
}
```

---

## Usage

```dart
import 'package:flutter_social_share_plus/flutter_social_share_plus.dart';

// Check which apps are installed
final apps = await SocialSharePlus.getInstalledApps();
// apps = {SocialPlatform.instagram: true, SocialPlatform.facebook: false}

// Share to Instagram Feed
final result = await SocialSharePlus.instagramFeed(filePath: '/path/to/image.jpg');

// Share to Instagram Story
await SocialSharePlus.instagramStory(
  config: StoryConfig(
    appId: 'YOUR_FACEBOOK_APP_ID',
    backgroundTopColor: '#FF5733',
    backgroundBottomColor: '#3366FF',
    stickerImage: '/path/to/sticker.png', // optional
  ),
);

// Share to Facebook Feed
await SocialSharePlus.facebookFeed(
  filePaths: ['/path/to/photo.jpg'],
  hashtag: '#flutter',
);

// System share sheet
await SocialSharePlus.shareSystem(
  text: 'Check this out!',
  filePaths: ['/path/to/file.jpg'],
);

// Handle results
switch (result) {
  case ShareSuccess():
    print('Shared successfully');
  case ShareError(:final message):
    print('Error: $message');
  case ShareAppNotInstalled():
    print('App not installed');
  case ShareCancelled():
    print('User cancelled');
}
```

---

## Notes

- **Facebook Feed on Android** uses the Facebook Android SDK's native share dialog. The app must be registered on [Meta for Developers](https://developers.facebook.com).
- **Instagram Feed on iOS** saves media to the photo library before sharing — `NSPhotoLibraryUsageDescription` is required.
- **Instagram Feed multiple files** on iOS: only the first file is shared (iOS limitation).
- **Facebook/Instagram Stories** share via deep-link intent — no SDK callback is returned, so the result is always `ShareSuccess` if the app is installed.
