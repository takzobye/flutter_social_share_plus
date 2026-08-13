import FBSDKCoreKit
import FBSDKShareKit
import Flutter
import UIKit

final class FacebookShareHandler {
    func isFeedAvailable() -> Bool {
        guard let url = URL(string: "fb://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func isStoryAvailable() -> Bool {
        guard let url = URL(string: "facebook-stories://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func shareFeed(
        filePaths: [String]?,
        hashtag: String?,
        presenter: UIViewController?,
        result: @escaping FlutterResult
    ) {
        let paths = filePaths ?? []
        guard (1...6).contains(paths.count) else {
            result(ShareResponse.failed("invalid_input", "Facebook Feed accepts one to six images"))
            return
        }
        if let hashtag, !hashtag.isEmpty, !hashtag.hasPrefix("#") {
            result(ShareResponse.failed("invalid_input", "Hashtags must start with #"))
            return
        }
        guard let presenter = topViewController(from: presenter) else {
            result(ShareResponse.failed("platform_error", "No view controller available"))
            return
        }
        guard isFeedAvailable() else {
            result(ShareResponse.unavailable())
            return
        }

        var urls = [URL]()
        for path in paths {
            let validation = ShareMedia.validatePath(path, allowed: ["image/"])
            guard case let .success(url) = validation else {
                if case let .failure(error) = validation {
                    result(error.response)
                }
                return
            }
            urls.append(url)
        }

        configurePrivacyDefaults()
        ApplicationDelegate.shared.initializeSDK()
        let content = SharePhotoContent()
        content.photos = urls.map { SharePhoto(imageURL: $0, isUserGenerated: true) }
        if let hashtag, !hashtag.isEmpty {
            content.hashtag = Hashtag(hashtag)
        }

        let delegate = ShareDelegateHandler(result: result)
        let dialog = ShareDialog(viewController: presenter, content: content, delegate: delegate)
        objc_setAssociatedObject(dialog, &associatedDelegateKey, delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        guard dialog.canShow else {
            result(ShareResponse.unavailable())
            return
        }
        if !dialog.show() {
            result(ShareResponse.failed("platform_error", "Unable to open Facebook"))
        }
    }

    func shareStory(
        appId: String?,
        stickerPath: String?,
        backgroundImagePath: String?,
        backgroundVideoPath: String?,
        backgroundTopColor: String?,
        backgroundBottomColor: String?,
        attributionUrl: String?,
        result: @escaping FlutterResult
    ) {
        guard let appId, !appId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            result(ShareResponse.failed("invalid_input", "A Facebook App ID is required"))
            return
        }
        guard backgroundImagePath == nil || backgroundVideoPath == nil else {
            result(ShareResponse.failed("invalid_input", "A Story cannot contain both backgrounds"))
            return
        }
        let paths = [stickerPath, backgroundImagePath, backgroundVideoPath].compactMap { $0 }
        guard !paths.isEmpty else {
            result(ShareResponse.failed("invalid_input", "Story content is required"))
            return
        }
        guard let storyURL = URL(string: "facebook-stories://share"),
              UIApplication.shared.canOpenURL(storyURL) else {
            result(ShareResponse.unavailable())
            return
        }

        for path in paths {
            let allowed: Set<String> = path == backgroundVideoPath ? ["video/"] : ["image/"]
            let validation = ShareMedia.validatePath(path, allowed: allowed)
            guard case .success = validation else {
                if case let .failure(error) = validation {
                    result(error.response)
                }
                return
            }
        }

        ShareMedia.load(paths: paths, maxVideoBytes: 50 * 1024 * 1024) { loaded in
            guard case let .success(data) = loaded else {
                if case let .failure(error) = loaded { result(error.response) }
                return
            }
            var item = [String: Any](minimumCapacity: 5)
            item["com.facebook.sharedSticker.appID"] = appId
            if let attributionUrl {
                // Keep the same Story metadata key across Meta targets.
                item["com.facebook.sharedSticker.contentURL"] = attributionUrl
            }
            if let backgroundImagePath {
                item["com.facebook.sharedSticker.backgroundImage"] = data[URL(fileURLWithPath: backgroundImagePath)]
            }
            if let backgroundVideoPath {
                item["com.facebook.sharedSticker.backgroundVideo"] = data[URL(fileURLWithPath: backgroundVideoPath)]
            }
            if let stickerPath {
                item["com.facebook.sharedSticker.stickerImage"] = data[URL(fileURLWithPath: stickerPath)]
            }
            if let backgroundTopColor {
                item["com.facebook.sharedSticker.backgroundTopColor"] = backgroundTopColor
            }
            if let backgroundBottomColor {
                item["com.facebook.sharedSticker.backgroundBottomColor"] = backgroundBottomColor
            }

            UIPasteboard.general.setItems(
                [item],
                options: [
                    .expirationDate: Date().addingTimeInterval(300),
                    .localOnly: true,
                ]
            )
            UIApplication.shared.open(storyURL) { opened in
                result(opened ? ShareResponse.launched() : ShareResponse.failed(
                    "platform_error",
                    "Unable to open Facebook Stories"
                ))
            }
        }
    }

    private func topViewController(from root: UIViewController?) -> UIViewController? {
        guard let root else { return nil }
        if let presented = root.presentedViewController {
            return topViewController(from: presented)
        }
        if let navigation = root as? UINavigationController {
            return topViewController(from: navigation.visibleViewController)
        }
        if let tab = root as? UITabBarController {
            return topViewController(from: tab.selectedViewController)
        }
        return root
    }

    private func configurePrivacyDefaults() {
        if Bundle.main.object(forInfoDictionaryKey: "FacebookAutoLogAppEventsEnabled") == nil {
            Settings.shared.isAutoLogAppEventsEnabled = false
        }
        if Bundle.main.object(forInfoDictionaryKey: "FacebookAdvertiserIDCollectionEnabled") == nil {
            Settings.shared.isAdvertiserIDCollectionEnabled = false
        }
    }
}

private var associatedDelegateKey: UInt8 = 0

private final class ShareDelegateHandler: NSObject, SharingDelegate {
    private let result: FlutterResult
    private var responded = false

    init(result: @escaping FlutterResult) {
        self.result = result
    }

    func sharer(_ sharer: any Sharing, didCompleteWithResults results: [String: Any]) {
        respond(ShareResponse.completed())
    }

    func sharer(_ sharer: any Sharing, didFailWithError error: any Error) {
        respond(ShareResponse.failed("platform_error", error.localizedDescription))
    }

    func sharerDidCancel(_ sharer: any Sharing) {
        respond(ShareResponse.cancelled())
    }

    private func respond(_ value: [String: String]) {
        guard !responded else { return }
        responded = true
        result(value)
    }
}
