import UIKit
import FBSDKCoreKit
import FBSDKShareKit

class FacebookShareHandler {

    func shareFeed(
        filePaths: [String],
        hashtag: String?,
        result: @escaping FlutterResult
    ) {
        guard canOpenFacebook() else {
            result("APP_NOT_INSTALLED")
            return
        }
        guard !filePaths.isEmpty else {
            result("ERROR:No files provided")
            return
        }

        let photos: [SharePhoto] = filePaths.compactMap { path in
            guard let image = UIImage(contentsOfFile: path) else { return nil }
            let photo = SharePhoto(image: image, isUserGenerated: true)
            return photo
        }

        guard !photos.isEmpty else {
            result("ERROR:No valid images found")
            return
        }

        let content = SharePhotoContent()
        content.photos = photos
        if let hashtag, !hashtag.isEmpty {
            content.hashtag = Hashtag(hashtag)
        }

        guard let viewController = topViewController() else {
            result("ERROR:No view controller available")
            return
        }

        let delegate = ShareDelegateHandler(result: result)
        let dialog = ShareDialog(viewController: viewController, content: content, delegate: delegate)

        // Keep delegate alive until callback
        objc_setAssociatedObject(dialog, "delegate", delegate, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        if dialog.canShow {
            dialog.show()
        } else {
            result("ERROR:Cannot show Facebook share dialog")
        }
    }

    func shareStory(
        appId: String,
        stickerImage: String?,
        backgroundImage: String?,
        backgroundVideo: String?,
        backgroundTopColor: String?,
        backgroundBottomColor: String?,
        attributionURL: String?,
        result: @escaping FlutterResult
    ) {
        guard let url = URL(string: "facebook-stories://share"),
              UIApplication.shared.canOpenURL(url) else {
            result("APP_NOT_INSTALLED")
            return
        }

        var items: [[String: Any]] = [[:]]

        items[0]["com.facebook.sharedSticker.appID"] = appId

        if let attributionURL {
            items[0]["com.facebook.sharedSticker.attributionURL"] = attributionURL
        }

        // Background image → UIImage (matches reference approach)
        if let backgroundImage, let image = UIImage(contentsOfFile: backgroundImage) {
            items[0]["com.facebook.sharedSticker.backgroundImage"] = image
        }

        // Background video → raw Data
        if let backgroundVideo {
            let videoURL = URL(fileURLWithPath: backgroundVideo)
            if let data = try? Data(contentsOf: videoURL) {
                items[0]["com.facebook.sharedSticker.backgroundVideo"] = data
            }
        }

        // Sticker: GIF → raw Data (preserves animation), static → UIImage
        if let stickerImage, let content = stickerContent(from: stickerImage) {
            items[0]["com.facebook.sharedSticker.stickerImage"] = content
        }

        if let backgroundTopColor {
            items[0]["com.facebook.sharedSticker.backgroundTopColor"] = backgroundTopColor
        }
        if let backgroundBottomColor {
            items[0]["com.facebook.sharedSticker.backgroundBottomColor"] = backgroundBottomColor
        }

        let options: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(300),
        ]
        UIPasteboard.general.setItems(items, options: options)

        UIApplication.shared.open(url) { success in
            result(success ? "SUCCESS" : "ERROR:Failed to open Facebook Stories")
        }
    }

    // MARK: - Private

    private func canOpenFacebook() -> Bool {
        let schemes = ["fb://", "facebook-stories://"]
        return schemes.contains { scheme in
            guard let url = URL(string: scheme) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    private func topViewController() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first,
              let window = scene.windows.first(where: { $0.isKeyWindow }) else {
            return nil
        }
        var vc = window.rootViewController
        while let presented = vc?.presentedViewController {
            vc = presented
        }
        return vc
    }

    /// GIF → raw Data (preserves animation frames).
    /// All other image formats → UIImage (matches reference behaviour).
    private func stickerContent(from path: String) -> Any? {
        let url = URL(fileURLWithPath: path)
        if url.pathExtension.lowercased() == "gif" {
            return try? Data(contentsOf: url)
        }
        return UIImage(contentsOfFile: path)
    }
}

// MARK: - ShareDelegateHandler

private class ShareDelegateHandler: NSObject, SharingDelegate {
    private let result: FlutterResult
    private var hasResponded = false

    init(result: @escaping FlutterResult) {
        self.result = result
    }

    func sharer(_ sharer: any Sharing, didCompleteWithResults results: [String: Any]) {
        guard !hasResponded else { return }
        hasResponded = true
        result("SUCCESS")
    }

    func sharer(_ sharer: any Sharing, didFailWithError error: any Error) {
        guard !hasResponded else { return }
        hasResponded = true
        result("ERROR:\(error.localizedDescription)")
    }

    func sharerDidCancel(_ sharer: any Sharing) {
        guard !hasResponded else { return }
        hasResponded = true
        result("CANCELLED")
    }
}
