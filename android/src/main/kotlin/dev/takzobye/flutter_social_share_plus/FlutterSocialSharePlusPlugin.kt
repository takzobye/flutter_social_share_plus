package dev.takzobye.flutter_social_share_plus

import android.app.Activity
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterSocialSharePlusPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private lateinit var instagramHandler: InstagramShareHandler
    private lateinit var facebookHandler: FacebookShareHandler

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel = MethodChannel(binding.binaryMessenger, "flutter_social_share_plus")
        channel.setMethodCallHandler(this)
        instagramHandler = InstagramShareHandler()
        facebookHandler = FacebookShareHandler()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        val activity = this.activity
        if (activity == null) {
            result.success("ERROR:Activity not available")
            return
        }

        when (call.method) {
            "getInstalledApps" -> {
                val apps = mapOf(
                    "instagram" to isAppInstalled(activity, "com.instagram.android"),
                    "facebook" to (isAppInstalled(activity, "com.facebook.katana")
                            || isAppInstalled(activity, "com.facebook.lite")),
                )
                result.success(apps)
            }

            // Instagram
            "instagramDirect" -> {
                val message = call.argument<String>("message") ?: ""
                instagramHandler.shareDirect(activity, message, result)
            }
            "instagramFeed" -> {
                val filePath = call.argument<String>("filePath") ?: ""
                val message = call.argument<String>("message")
                instagramHandler.shareFeed(activity, filePath, message, result)
            }
            "instagramFeedMultiple" -> {
                val filePaths = call.argument<List<String>>("filePaths") ?: emptyList()
                instagramHandler.shareFeedMultiple(activity, filePaths, result)
            }
            "instagramReels" -> {
                val videoPath = call.argument<String>("videoPath") ?: ""
                instagramHandler.shareReels(activity, videoPath, result)
            }
            "instagramStory" -> {
                val appId = call.argument<String>("appId") ?: ""
                instagramHandler.shareStory(
                    activity = activity,
                    appId = appId,
                    stickerImage = call.argument("stickerImage"),
                    backgroundImage = call.argument("backgroundImage"),
                    backgroundVideo = call.argument("backgroundVideo"),
                    backgroundTopColor = call.argument("backgroundTopColor"),
                    backgroundBottomColor = call.argument("backgroundBottomColor"),
                    attributionURL = call.argument("attributionURL"),
                    result = result,
                )
            }

            // Facebook
            "facebookFeed" -> {
                val filePaths = call.argument<List<String>>("filePaths") ?: emptyList()
                val hashtag = call.argument<String>("hashtag")
                facebookHandler.shareFeed(activity, filePaths, hashtag, result)
            }
            "facebookStory" -> {
                val appId = call.argument<String>("appId") ?: ""
                facebookHandler.shareStory(
                    activity = activity,
                    appId = appId,
                    stickerImage = call.argument("stickerImage"),
                    backgroundImage = call.argument("backgroundImage"),
                    backgroundVideo = call.argument("backgroundVideo"),
                    backgroundTopColor = call.argument("backgroundTopColor"),
                    backgroundBottomColor = call.argument("backgroundBottomColor"),
                    attributionURL = call.argument("attributionURL"),
                    result = result,
                )
            }

            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    // ActivityAware

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        facebookHandler.onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        facebookHandler.onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    private fun isAppInstalled(activity: Activity, packageName: String): Boolean {
        return try {
            activity.packageManager.getPackageInfo(packageName, 0)
            true
        } catch (_: Exception) {
            false
        }
    }
}
