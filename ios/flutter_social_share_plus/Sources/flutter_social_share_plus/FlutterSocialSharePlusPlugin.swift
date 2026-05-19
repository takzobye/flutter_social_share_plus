import Flutter
import UIKit

public class FlutterSocialSharePlusPlugin: NSObject, FlutterPlugin {

    private let instagramHandler = InstagramShareHandler()
    private let facebookHandler = FacebookShareHandler()
    private let systemHandler = SystemShareHandler()

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_social_share_plus",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterSocialSharePlusPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "getInstalledApps":
            let apps: [String: Bool] = [
                "instagram": canOpenURL("instagram://"),
                "facebook": canOpenURL("fb://") || canOpenURL("facebook-stories://"),
            ]
            result(apps)

        // Instagram
        case "instagramDirect":
            let message = args["message"] as? String ?? ""
            instagramHandler.shareDirect(message: message, result: result)

        case "instagramFeed":
            let filePath = args["filePath"] as? String ?? ""
            instagramHandler.shareFeed(filePath: filePath, result: result)

        case "instagramFeedMultiple":
            let filePaths = args["filePaths"] as? [String] ?? []
            instagramHandler.shareFeed(filePath: filePaths.first ?? "", result: result)

        case "instagramReels":
            let videoPath = args["videoPath"] as? String ?? ""
            instagramHandler.shareReels(videoPath: videoPath, result: result)

        case "instagramStory":
            instagramHandler.shareStory(
                appId: args["appId"] as? String ?? "",
                stickerImage: args["stickerImage"] as? String,
                backgroundImage: args["backgroundImage"] as? String,
                backgroundVideo: args["backgroundVideo"] as? String,
                backgroundTopColor: args["backgroundTopColor"] as? String,
                backgroundBottomColor: args["backgroundBottomColor"] as? String,
                attributionURL: args["attributionURL"] as? String,
                result: result
            )

        // Facebook
        case "facebookFeed":
            let filePaths = args["filePaths"] as? [String] ?? []
            let hashtag = args["hashtag"] as? String
            facebookHandler.shareFeed(filePaths: filePaths, hashtag: hashtag, result: result)

        case "facebookStory":
            facebookHandler.shareStory(
                appId: args["appId"] as? String ?? "",
                stickerImage: args["stickerImage"] as? String,
                backgroundImage: args["backgroundImage"] as? String,
                backgroundVideo: args["backgroundVideo"] as? String,
                backgroundTopColor: args["backgroundTopColor"] as? String,
                backgroundBottomColor: args["backgroundBottomColor"] as? String,
                attributionURL: args["attributionURL"] as? String,
                result: result
            )

        // System
        case "shareSystem":
            let text = args["text"] as? String
            let filePaths = args["filePaths"] as? [String]
            let subject = args["subject"] as? String
            systemHandler.share(text: text, filePaths: filePaths, subject: subject, result: result)

        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func canOpenURL(_ urlString: String) -> Bool {
        guard let url = URL(string: urlString) else { return false }
        return UIApplication.shared.canOpenURL(url)
    }
}
