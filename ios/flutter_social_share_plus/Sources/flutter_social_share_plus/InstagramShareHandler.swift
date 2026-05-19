import Flutter
import UIKit
import Photos

class InstagramShareHandler {

    func shareDirect(message: String, result: @escaping FlutterResult) {
        guard let encoded = message.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
              let url = URL(string: "instagram://sharesheet?text=\(encoded)") else {
            result("ERROR:Failed to encode message")
            return
        }
        guard UIApplication.shared.canOpenURL(url) else {
            result("APP_NOT_INSTALLED")
            return
        }
        UIApplication.shared.open(url) { success in
            result(success ? "SUCCESS" : "ERROR:Failed to open Instagram")
        }
    }

    func shareFeed(filePath: String, result: @escaping FlutterResult) {
        guard UIApplication.shared.canOpenURL(URL(string: "instagram://")!) else {
            result("APP_NOT_INSTALLED")
            return
        }
        let fileURL = URL(fileURLWithPath: filePath)
        let isVideo = isVideoFile(fileURL)

        requestPhotoLibraryAccess { granted in
            guard granted else {
                result("ERROR:Photo library access denied")
                return
            }
            self.saveAndOpenInInstagram(fileURL: fileURL, isVideo: isVideo, result: result)
        }
    }

    func shareReels(videoPath: String, result: @escaping FlutterResult) {
        guard UIApplication.shared.canOpenURL(URL(string: "instagram://")!) else {
            result("APP_NOT_INSTALLED")
            return
        }
        let fileURL = URL(fileURLWithPath: videoPath)

        requestPhotoLibraryAccess { granted in
            guard granted else {
                result("ERROR:Photo library access denied")
                return
            }
            self.saveAndOpenInInstagram(fileURL: fileURL, isVideo: true, result: result)
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
        guard let url = URL(string: "instagram-stories://share?source_application=\(appId)"),
              UIApplication.shared.canOpenURL(url) else {
            result("APP_NOT_INSTALLED")
            return
        }

        var items: [[String: Any]] = [[:]]

        if let attributionURL {
            items[0]["com.instagram.sharedSticker.attributionURL"] = attributionURL
        }

        // Background image → UIImage (matches reference approach)
        if let backgroundImage, let image = UIImage(contentsOfFile: backgroundImage) {
            items[0]["com.instagram.sharedSticker.backgroundImage"] = image
        }

        // Background video → raw Data
        if let backgroundVideo {
            let videoURL = URL(fileURLWithPath: backgroundVideo)
            if let data = try? Data(contentsOf: videoURL) {
                items[0]["com.instagram.sharedSticker.backgroundVideo"] = data
            }
        }

        // Sticker: GIF → raw Data (preserves animation), static → UIImage
        if let stickerImage, let content = stickerContent(from: stickerImage) {
            items[0]["com.instagram.sharedSticker.stickerImage"] = content
        }

        if let backgroundTopColor {
            items[0]["com.instagram.sharedSticker.backgroundTopColor"] = backgroundTopColor
        }
        if let backgroundBottomColor {
            items[0]["com.instagram.sharedSticker.backgroundBottomColor"] = backgroundBottomColor
        }

        let options: [UIPasteboard.OptionsKey: Any] = [
            .expirationDate: Date().addingTimeInterval(300),
        ]
        UIPasteboard.general.setItems(items, options: options)

        UIApplication.shared.open(url) { success in
            result(success ? "SUCCESS" : "ERROR:Failed to open Instagram Stories")
        }
    }

    // MARK: - Private

    private func saveAndOpenInInstagram(
        fileURL: URL,
        isVideo: Bool,
        result: @escaping FlutterResult
    ) {
        var localIdentifier: String?

        PHPhotoLibrary.shared().performChanges({
            let request: PHAssetChangeRequest
            if isVideo {
                request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)!
            } else {
                let image = UIImage(contentsOfFile: fileURL.path)!
                request = PHAssetChangeRequest.creationRequestForAsset(from: image)
            }
            localIdentifier = request.placeholderForCreatedAsset?.localIdentifier
        }) { success, error in
            DispatchQueue.main.async {
                guard success, let identifier = localIdentifier else {
                    result("ERROR:\(error?.localizedDescription ?? "Failed to save to library")")
                    return
                }
                let instagramURL = URL(string: "instagram://library?LocalIdentifier=\(identifier)")!
                UIApplication.shared.open(instagramURL) { opened in
                    result(opened ? "SUCCESS" : "ERROR:Failed to open Instagram")
                }
            }
        }
    }

    private func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        switch status {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    completion(newStatus == .authorized || newStatus == .limited)
                }
            }
        default:
            completion(false)
        }
    }

    private func isVideoFile(_ url: URL) -> Bool {
        let ext = url.pathExtension.lowercased()
        return ["mp4", "mov", "avi", "m4v", "mkv"].contains(ext)
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
