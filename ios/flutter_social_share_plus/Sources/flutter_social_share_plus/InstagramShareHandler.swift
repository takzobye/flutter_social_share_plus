import Flutter
import Photos
import UIKit

final class InstagramShareHandler {
    func isFeedAvailable() -> Bool {
        guard let url = URL(string: "instagram://") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func isStoryAvailable() -> Bool {
        guard let url = URL(string: "instagram-stories://share") else { return false }
        return UIApplication.shared.canOpenURL(url)
    }

    func shareFeed(filePath: String?, result: @escaping FlutterResult) {
        guard isFeedAvailable() else {
            result(ShareResponse.unavailable())
            return
        }
        guard let path = filePath else {
            result(ShareResponse.failed("invalid_input", "A media path is required"))
            return
        }
        let validation = ShareMedia.validatePath(
            path,
            allowed: ["image/", "video/"]
        )
        guard case let .success(fileURL) = validation else {
            if case let .failure(error) = validation {
                result(error.response)
            }
            return
        }

        requestPhotoLibraryAccess { granted in
            guard granted else {
                result(ShareResponse.failed("permission_denied", "Photo library access was denied"))
                return
            }
            self.saveAndOpen(fileURL: fileURL, result: result)
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
        guard let storyURL = URLComponents(
            string: "instagram-stories://share"
        ).flatMap({ components in
            var components = components
            components.queryItems = [URLQueryItem(name: "source_application", value: appId)]
            return components.url
        }), UIApplication.shared.canOpenURL(storyURL) else {
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
            var item = [String: Any]()
            if let attributionUrl {
                // contentURL is the Story pasteboard key used by Meta's historical examples.
                item["com.instagram.sharedSticker.contentURL"] = attributionUrl
            }
            if let backgroundImagePath {
                item["com.instagram.sharedSticker.backgroundImage"] = data[URL(fileURLWithPath: backgroundImagePath)]
            }
            if let backgroundVideoPath {
                item["com.instagram.sharedSticker.backgroundVideo"] = data[URL(fileURLWithPath: backgroundVideoPath)]
            }
            if let stickerPath {
                item["com.instagram.sharedSticker.stickerImage"] = data[URL(fileURLWithPath: stickerPath)]
            }
            if let backgroundTopColor {
                item["com.instagram.sharedSticker.backgroundTopColor"] = backgroundTopColor
            }
            if let backgroundBottomColor {
                item["com.instagram.sharedSticker.backgroundBottomColor"] = backgroundBottomColor
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
                    "Unable to open Instagram Stories"
                ))
            }
        }
    }

    private func saveAndOpen(fileURL: URL, result: @escaping FlutterResult) {
        var localIdentifier: String?
        let isVideo = ShareMedia.mimeType(for: fileURL)?.hasPrefix("video/") == true

        PHPhotoLibrary.shared().performChanges({
            let request = isVideo
                ? PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: fileURL)
                : PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: fileURL)
            localIdentifier = request?.placeholderForCreatedAsset?.localIdentifier
        }) { success, error in
            DispatchQueue.main.async {
                guard success, let localIdentifier else {
                    result(ShareResponse.failed(
                        "platform_error",
                        error?.localizedDescription ?? "Unable to save media"
                    ))
                    return
                }
                var components = URLComponents(string: "instagram://library")
                components?.queryItems = [URLQueryItem(name: "LocalIdentifier", value: localIdentifier)]
                guard let instagramURL = components?.url else {
                    result(ShareResponse.failed("platform_error", "Unable to build Instagram URL"))
                    return
                }
                UIApplication.shared.open(instagramURL) { opened in
                    result(opened ? ShareResponse.launched() : ShareResponse.failed(
                        "platform_error",
                        "Unable to open Instagram"
                    ))
                }
            }
        }
    }

    private func requestPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        switch PHPhotoLibrary.authorizationStatus(for: .addOnly) {
        case .authorized, .limited:
            completion(true)
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                DispatchQueue.main.async {
                    completion(status == .authorized || status == .limited)
                }
            }
        default:
            completion(false)
        }
    }
}
