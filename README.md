# flutter_social_share_plus

Native Flutter sharing to Instagram and Facebook on Android and iOS.

If you are not confident installing the package yourself, you can provide this README.md to an AI assistant and ask it to guide you through the setup. The installation instructions are intentionally comprehensive and cover the configuration required for both Android and iOS.

## Supported flows

| Flow | Android | iOS |
| --- | :---: | :---: |
| Instagram Feed: one image or video | ✅ | ✅ |
| Instagram Stories | ✅ | ✅ |
| Facebook Feed: one to six images | ✅ | ✅ |
| Facebook Stories | ✅ | ✅ |

The package opens the native Instagram or Facebook composer. It does not upload media to a package-owned server and does not implement server-side publishing or authentication.

## Requirements

- Dart 3.12 or newer
- Flutter 3.44 or newer (Flutter 3.47 is recommended)
- Android API 24 or newer
- iOS 15 or newer
- Instagram and/or Facebook installed on the test device
- A Meta developer App ID and client token

## 1. Configure a Meta app

Create an app in the [Meta for Developers](https://developers.facebook.com/apps/) dashboard and collect:

- **App ID**: the numeric Meta/Facebook App ID. Use the same value in StoryConfig.appId.
- **Client token**: available in the app's Settings → Advanced page.

Configure the app platforms to match the host Flutter app:

- **Android**: add the exact applicationId from android/app/build.gradle or android/app/build.gradle.kts. Register debug and release key hashes.
- **iOS**: add the exact Runner bundle identifier from Xcode.

Use production identifiers and signing keys in release builds. The values below are placeholders.

### Android key hashes

Meta may require the signing certificate hash for the Android platform. Generate the debug hash on macOS or Linux with:

    keytool -exportcert -alias androiddebugkey -keystore ~/.android/debug.keystore -storepass android | openssl sha1 -binary | openssl base64

Generate the release hash with the release keystore and alias used by the app. Add each debug/release hash to the Android platform settings for the Meta app.

## 2. Add the package

Run this from the Flutter project root:

    flutter pub add flutter_social_share_plus
    flutter pub get

Or add it manually to pubspec.yaml:

    dependencies:
      flutter_social_share_plus: ^1.0.0

The plugin includes its native Meta SDK dependencies and Android FileProvider. Do not add another Facebook SDK dependency or another provider for this package.

## 3. Android setup

### Android requirements

- minSdk must be 24 or newer.
- Use Java/Kotlin JVM target 17.
- The plugin uses Meta Android Share SDK 18.2.3.

### 3.1 Add Meta strings

Create or edit:

android/app/src/main/res/values/strings.xml

Keep the existing resources element if the file already exists:

    <resources>
        <string name="facebook_app_id">YOUR_FACEBOOK_APP_ID</string>
        <string name="facebook_client_token">YOUR_FACEBOOK_CLIENT_TOKEN</string>
    </resources>

Use the numeric App ID without an fb prefix.

### 3.2 Add application metadata

Open:

android/app/src/main/AndroidManifest.xml

Add these entries inside the host app's application element:

    <meta-data
        android:name="com.facebook.sdk.ApplicationId"
        android:value="@string/facebook_app_id" />
    <meta-data
        android:name="com.facebook.sdk.ClientToken"
        android:value="@string/facebook_client_token" />

The plugin automatically contributes:

- a secure, non-exported FileProvider scoped to app files/cache;
- package visibility for Instagram, Facebook, and Facebook Lite;
- disabled Meta automatic app-event logging and advertising-ID collection;
- removal of the AD_ID permission by default.

Do not copy the plugin provider into the host manifest. Do not add a broad external-path provider. If the host app already has a provider with the same authority, remove the duplicate.

### 3.3 Optional Meta privacy overrides

The defaults are privacy-first. Only enable Meta analytics or advertising identifiers when the host app has the required consent and Play Console declarations:

    <manifest xmlns:android="http://schemas.android.com/apk/res/android"
        xmlns:tools="http://schemas.android.com/tools">
        <application>
            <meta-data
                android:name="com.facebook.sdk.AutoLogAppEventsEnabled"
                android:value="true"
                tools:replace="android:value" />
            <meta-data
                android:name="com.facebook.sdk.AdvertiserIDCollectionEnabled"
                android:value="true"
                tools:replace="android:value" />
        </application>
    </manifest>

The `tools:replace` attributes are required because the plugin manifest supplies explicit privacy-first defaults. Otherwise leave both values false or omit the overrides.

### 3.4 Build Android

    flutter pub get
    flutter clean
    flutter build apk --debug

Install the debug APK on a device with Instagram or Facebook installed. isAvailable returns false when the requested target cannot receive the handoff.

## 4. iOS setup

### iOS requirements

- Deployment target iOS 15.0 or newer.
- The plugin uses Facebook iOS SDK 18.1.x.
- The host app must declare the URL schemes used by the target apps.

The plugin supports Flutter's Swift Package Manager integration and CocoaPods. Use the dependency flow already used by the host project; do not add duplicate FBSDK packages manually.

### 4.1 Configure Info.plist

Open:

ios/Runner/Info.plist

Add these entries inside the top-level dict:

    <key>FacebookAppID</key>
    <string>YOUR_FACEBOOK_APP_ID</string>
    <key>FacebookClientToken</key>
    <string>YOUR_FACEBOOK_CLIENT_TOKEN</string>
    <key>FacebookDisplayName</key>
    <string>YOUR_APP_NAME</string>

    <!-- Privacy-safe defaults. Use true only with the required consent/declarations. -->
    <key>FacebookAutoLogAppEventsEnabled</key>
    <false/>
    <key>FacebookAdvertiserIDCollectionEnabled</key>
    <false/>

    <key>CFBundleURLTypes</key>
    <array>
        <dict>
            <key>CFBundleURLSchemes</key>
            <array>
                <!-- No spaces: fb + the numeric App ID. -->
                <string>fbYOUR_FACEBOOK_APP_ID</string>
            </array>
        </dict>
    </array>

    <key>LSApplicationQueriesSchemes</key>
    <array>
        <string>instagram</string>
        <string>instagram-stories</string>
        <string>fb</string>
        <string>facebook-stories</string>
        <string>fbauth2</string>
        <string>fbapi</string>
        <string>fbshareextension</string>
    </array>

Merge these schemes with existing CFBundleURLTypes or LSApplicationQueriesSchemes entries; do not remove URL schemes used by other SDKs.

Replace YOUR_FACEBOOK_APP_ID everywhere. The URL scheme is fb followed directly by the numeric App ID, for example fb1234567890.

### 4.2 Add the Photos permission

Instagram Feed saves the local file to Photos before opening Instagram. Add:

    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>Save media so it can be shared to Instagram.</string>

The plugin requests add-only Photos access. It does not request read access for this flow.

### 4.3 Swift Package Manager

For current Flutter projects, SPM is recommended:

    flutter pub get
    flutter build ios --simulator --no-codesign

Flutter generates the plugin Swift package and resolves the Facebook iOS SDK from the plugin Package.swift. You normally do not need to add a package manually in Xcode. If Xcode asks to resolve packages, use File → Packages → Resolve Package Versions.

### 4.4 CocoaPods

If the host app uses CocoaPods, keep the normal Flutter ios/Podfile, set the platform to iOS 15 or newer, and run:

    cd ios
    pod install --repo-update
    open Runner.xcworkspace

The plugin podspec brings in FBSDKCoreKit and FBSDKShareKit 18.1.x. Do not add those pods again. Open Runner.xcworkspace, not Runner.xcodeproj, after installing pods.

The plugin registers Facebook application and scene lifecycle callbacks automatically. No AppDelegate or SceneDelegate forwarding code is required.

### 4.5 Build iOS

    flutter pub get
    flutter clean
    flutter build ios --simulator --no-codesign

For a device/archive build, configure the normal Apple signing team and provisioning profile, then use Xcode or flutter build ipa.

## 5. Usage

All share methods use readable local file paths. A URL, Flutter asset path, XFile object, or Android content URI is not accepted directly. Copy media to a local file first and pass its path.

### 5.1 Import

    import 'package:flutter/material.dart';
    import 'package:flutter_social_share_plus/flutter_social_share_plus.dart';

For image_picker, add that package separately and pass the picked file path:

    flutter pub add image_picker

    import 'package:image_picker/image_picker.dart';
    final picked = await ImagePicker().pickMedia();
    if (picked == null) return;

    final result = await SocialSharePlus.instagramFeed(
      filePath: picked.path,
    );

### 5.2 Check availability

Check the exact flow before enabling a button:

    final canShare = await SocialSharePlus.isAvailable(
      ShareTarget.instagramFeed,
    );

Supported targets:

    ShareTarget.instagramFeed
    ShareTarget.instagramStory
    ShareTarget.facebookFeed
    ShareTarget.facebookStory

This check only tests whether the native target can receive the handoff. It does not validate files, App IDs, permissions, or Meta dashboard settings.

### 5.3 Instagram Feed

Shares one local image or video:

    final result = await SocialSharePlus.instagramFeed(
      filePath: '/absolute/path/photo.jpg',
    );

Common supported extensions are JPEG, PNG, GIF, WebP, HEIC/HEIF, MP4, MOV, M4V, and AVI. The target app ultimately decides whether it accepts a particular codec.

On iOS the plugin saves the file to Photos. On Android it grants Instagram a temporary read-only FileProvider URI.

### 5.4 Instagram Stories

Use StoryConfig:

    final result = await SocialSharePlus.instagramStory(
      config: StoryConfig(
        appId: 'YOUR_FACEBOOK_APP_ID',
        stickerPath: '/absolute/path/sticker.png',
        backgroundImagePath: '/absolute/path/background.jpg',
        backgroundTopColor: Colors.deepOrange,
        backgroundBottomColor: Colors.blue,
        attributionUrl: Uri.https('example.com', '/posts/123'),
      ),
    );

Rules:

- appId must be non-empty.
- Provide a sticker or a background.
- Use either backgroundImagePath or backgroundVideoPath, not both.
- Stickers and image backgrounds must be images; video backgrounds must be videos.
- Story videos must be 50 MiB or smaller.
- Colors are optional Flutter Color values.
- attributionUrl is optional and forwarded as best-effort Story metadata (`contentURL` on iOS). Meta may ignore it on some app versions.

### 5.5 Facebook Feed

Shares one to six local images:

    final result = await SocialSharePlus.facebookFeed(
      imagePaths: [
        '/absolute/path/one.jpg',
        '/absolute/path/two.png',
      ],
      hashtag: '#flutter',
    );

Rules:

- imagePaths must contain one to six readable image files.
- Videos are not accepted by Facebook Feed.
- hashtag is optional; when supplied, it must start with #.
- Await the result and prevent duplicate taps while the dialog is open.

### 5.6 Facebook Stories

Facebook Stories use the same StoryConfig:

    final result = await SocialSharePlus.facebookStory(
      config: StoryConfig(
        appId: 'YOUR_FACEBOOK_APP_ID',
        backgroundImagePath: '/absolute/path/background.jpg',
        stickerPath: '/absolute/path/sticker.png',
        attributionUrl: Uri.https('example.com', '/posts/123'),
      ),
    );

The same Story validation rules and 50 MiB video limit apply.

### 5.7 Handle every result

Use an exhaustive pattern switch:

    void showShareResult(ShareResult result) {
      final message = switch (result) {
        ShareCompleted() => 'Facebook reported that sharing completed.',
        ShareLaunched() => 'The target composer opened.',
        ShareCancelled() => 'The user cancelled sharing.',
        ShareUnavailable() => 'The target app or flow is unavailable.',
        ShareFailed(:final code, :final message) => '$code: $message',
      };

      debugPrint(message);
    }

| Result | Meaning |
| --- | --- |
| ShareCompleted | Facebook Feed's native dialog reported success. |
| ShareLaunched | A target app opened but cannot report final publishing. |
| ShareCancelled | The user cancelled a native Facebook dialog. |
| ShareUnavailable | The target app or requested capability is unavailable. |
| ShareFailed | Validation, permission, busy-state, or platform failure. |

ShareFailed.code values:

    ShareErrorCode.invalidInput
    ShareErrorCode.fileNotFound
    ShareErrorCode.unsupportedMedia
    ShareErrorCode.permissionDenied
    ShareErrorCode.busy
    ShareErrorCode.platformError

ShareCompleted is not a guarantee that Instagram or a Story was published. Deep-link flows return ShareLaunched because the target app owns the final publish action.

## Validation and media behavior

- Paths must be local, readable files.
- Relative paths, URLs, Flutter asset names, and directories are invalid.
- Android copies files outside app-private directories into a scoped cache before sharing.
- Android does not expose a broad external storage path through FileProvider.
- iOS Story media uses a local-only pasteboard entry expiring after five minutes.
- Android share cache files older than 24 hours are cleaned up.
- Await each request; do not start a second Facebook Feed dialog while one is open.

## Privacy and security

- Meta automatic app-event logging is disabled by default.
- Meta advertising-ID collection is disabled by default.
- Android AD_ID permission is removed by default.
- Android shared files use non-exported, read-only FileProvider URIs.
- iOS requests add-only Photos access for Instagram Feed.
- The host app remains responsible for Meta, Apple, Google Play, consent, and privacy declarations.

## Troubleshooting

### ShareUnavailable

Check:

1. Instagram or Facebook is installed.
2. Android package visibility and application IDs are correct.
3. iOS LSApplicationQueriesSchemes contains the schemes in this README.
4. The installed target app supports the requested flow.

### fileNotFound or unsupportedMedia

Use an absolute local path. Confirm the file exists when the call starts and its extension matches the media type. Do not pass an asset name or remote URL.

### Facebook opens nothing or returns platformError

Verify:

- Android strings and manifest metadata are inside the host application.
- iOS FacebookAppID, FacebookClientToken, FacebookDisplayName, and fb<APP_ID> scheme are present.
- Meta dashboard package/bundle IDs match the installed build.
- Android debug/release key hashes are registered.
- Native dependencies were fetched (flutter pub get; pod install for CocoaPods).

### iOS cannot find FBSDK modules

Run flutter clean and flutter pub get. For CocoaPods, run cd ios && pod install --repo-update and open Runner.xcworkspace. For SPM, use Xcode's File → Packages → Resolve Package Versions.

### permissionDenied on iOS

Add NSPhotoLibraryAddUsageDescription, then uninstall/reinstall the app so iOS can show the permission prompt again.

### busy

The Facebook Feed dialog is already active. Disable the share button until the previous Future<ShareResult> completes.

## Generic system sharing

This package focuses on Instagram and Facebook. For the general iOS/Android share sheet, use [share_plus](https://pub.dev/packages/share_plus).

## Migration from 0.x

- Replace ShareSuccess with ShareCompleted or ShareLaunched.
- Replace ShareError, ShareAppNotInstalled, and old string parsing with ShareFailed, ShareUnavailable, and ShareCancelled.
- Rename Story fields to stickerPath, backgroundImagePath, and backgroundVideoPath.
- Story colors use Flutter Color; attribution uses Uri.
- Replace facebookFeed(filePaths: ...) with facebookFeed(imagePaths: ...).
- Remove Direct, Reels, Instagram multi-file Feed, and shareSystem.
- Use share_plus for generic system sharing.

## Release checklist

Before release:

1. Replace placeholder App ID, client token, bundle ID, package ID, and URL scheme values.
2. Test each flow on physical devices with the matching Meta app installed.
3. Test debug and release signing configurations, especially Android key hashes.
4. Test cancelled, unavailable, invalid-file, permission-denied, and success cases.
5. Review Meta, Apple, and Google Play privacy declarations.
6. Run:

    flutter analyze
    flutter test
    flutter build apk --debug
    flutter build ios --simulator --no-codesign

For a full working example, see the example/ app in this repository.
