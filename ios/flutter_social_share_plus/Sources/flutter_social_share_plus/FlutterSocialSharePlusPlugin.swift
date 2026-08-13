import FBSDKCoreKit
import Flutter
import UIKit

public final class FlutterSocialSharePlusPlugin: NSObject, FlutterPlugin, FlutterSceneLifeCycleDelegate {
    private let instagramHandler = InstagramShareHandler()
    private let facebookHandler = FacebookShareHandler()
    private weak var viewController: UIViewController?

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "flutter_social_share_plus",
            binaryMessenger: registrar.messenger()
        )
        let instance = FlutterSocialSharePlusPlugin()
        instance.viewController = registrar.viewController
        registrar.addMethodCallDelegate(instance, channel: channel)
        registrar.addApplicationDelegate(instance)
        if #available(iOS 13.0, *) {
            registrar.addSceneDelegate(instance)
        }
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        let args = call.arguments as? [String: Any] ?? [:]

        switch call.method {
        case "isAvailable":
            result(["available": isAvailable(target: args["target"] as? String)])
        case "instagramFeed":
            instagramHandler.shareFeed(filePath: args["filePath"] as? String, result: result)
        case "instagramStory":
            instagramHandler.shareStory(
                appId: args["appId"] as? String,
                stickerPath: args["stickerPath"] as? String,
                backgroundImagePath: args["backgroundImagePath"] as? String,
                backgroundVideoPath: args["backgroundVideoPath"] as? String,
                backgroundTopColor: args["backgroundTopColor"] as? String,
                backgroundBottomColor: args["backgroundBottomColor"] as? String,
                attributionUrl: args["attributionUrl"] as? String,
                result: result
            )
        case "facebookFeed":
            facebookHandler.shareFeed(
                filePaths: args["imagePaths"] as? [String],
                hashtag: args["hashtag"] as? String,
                presenter: viewController,
                result: result
            )
        case "facebookStory":
            facebookHandler.shareStory(
                appId: args["appId"] as? String,
                stickerPath: args["stickerPath"] as? String,
                backgroundImagePath: args["backgroundImagePath"] as? String,
                backgroundVideoPath: args["backgroundVideoPath"] as? String,
                backgroundTopColor: args["backgroundTopColor"] as? String,
                backgroundBottomColor: args["backgroundBottomColor"] as? String,
                attributionUrl: args["attributionUrl"] as? String,
                result: result
            )
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    public func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [AnyHashable: Any] = [:]
    ) -> Bool {
        // Facebook initialization is deferred until a Facebook share is requested.
        false
    }

    public func application(
        _ application: UIApplication,
        open url: URL,
        options: [UIApplication.OpenURLOptionsKey: Any] = [:]
    ) -> Bool {
        ApplicationDelegate.shared.application(application, open: url, options: options)
    }

    public func application(
        _ application: UIApplication,
        open url: URL,
        sourceApplication: String,
        annotation: Any
    ) -> Bool {
        ApplicationDelegate.shared.application(
            application,
            open: url,
            sourceApplication: sourceApplication,
            annotation: annotation
        )
    }

    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([Any]) -> Void
    ) -> Bool {
        ApplicationDelegate.shared.application(application, continue: userActivity)
    }

    @available(iOS 13.0, *)
    public func scene(
        _ scene: UIScene,
        openURLContexts URLContexts: Set<UIOpenURLContext>
    ) -> Bool {
        URLContexts.contains { context in
            ApplicationDelegate.shared.application(
                UIApplication.shared,
                open: context.url,
                sourceApplication: context.options.sourceApplication,
                annotation: context.options.annotation
            )
        }
    }

    private func isAvailable(target: String?) -> Bool {
        switch target {
        case "instagramFeed": instagramHandler.isFeedAvailable()
        case "instagramStory": instagramHandler.isStoryAvailable()
        case "facebookFeed": facebookHandler.isFeedAvailable()
        case "facebookStory": facebookHandler.isStoryAvailable()
        default: false
        }
    }
}
