package dev.takzobye.flutter_social_share_plus

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result

class FlutterSocialSharePlusPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private lateinit var applicationContext: Context
    private var activity: Activity? = null
    private lateinit var instagramHandler: InstagramShareHandler
    private lateinit var facebookHandler: FacebookShareHandler

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        applicationContext = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "flutter_social_share_plus")
        channel.setMethodCallHandler(this)
        instagramHandler = InstagramShareHandler()
        facebookHandler = FacebookShareHandler()
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            "isAvailable" -> result.success(
                mapOf("available" to isAvailable(call.argument<String>("target")))
            )
            "instagramFeed" -> withActivity(result) { current ->
                instagramHandler.shareFeed(
                    current,
                    call.argument<String>("filePath"),
                    result,
                )
            }
            "instagramStory" -> withActivity(result) { current ->
                instagramHandler.shareStory(
                    current,
                    call.argument<String>("appId"),
                    call.argument<String>("stickerPath"),
                    call.argument<String>("backgroundImagePath"),
                    call.argument<String>("backgroundVideoPath"),
                    call.argument<String>("backgroundTopColor"),
                    call.argument<String>("backgroundBottomColor"),
                    call.argument<String>("attributionUrl"),
                    result,
                )
            }
            "facebookFeed" -> withActivity(result) { current ->
                facebookHandler.shareFeed(
                    current,
                    call.argument<List<String>>("imagePaths"),
                    call.argument<String>("hashtag"),
                    result,
                )
            }
            "facebookStory" -> withActivity(result) { current ->
                facebookHandler.shareStory(
                    current,
                    call.argument<String>("appId"),
                    call.argument<String>("stickerPath"),
                    call.argument<String>("backgroundImagePath"),
                    call.argument<String>("backgroundVideoPath"),
                    call.argument<String>("backgroundTopColor"),
                    call.argument<String>("backgroundBottomColor"),
                    call.argument<String>("attributionUrl"),
                    result,
                )
            }
            else -> result.notImplemented()
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        instagramHandler.onDetachedFromEngine()
        facebookHandler.onDetachedFromEngine()
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        instagramHandler.onAttachedToActivity(binding)
        facebookHandler.onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        activity = null
        instagramHandler.onDetachedFromActivityForConfigChanges()
        facebookHandler.onDetachedFromActivityForConfigChanges()
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
        instagramHandler.onAttachedToActivity(binding)
        facebookHandler.onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivity() {
        activity = null
        instagramHandler.onDetachedFromActivity()
        facebookHandler.onDetachedFromActivity()
    }

    private fun withActivity(result: Result, block: (Activity) -> Unit) {
        val current = activity
        if (current == null) {
            result.success(ShareResponse.failed("platform_error", "Activity not available"))
            return
        }
        try {
            block(current)
        } catch (error: Exception) {
            result.success(
                ShareResponse.failed(
                    "platform_error",
                    error.message ?: "Unable to start share",
                )
            )
        }
    }

    private fun isAvailable(target: String?): Boolean {
        if (target == "instagramFeed") {
            return listOf("image/*", "video/*").any { type ->
                val intent = Intent(Intent.ACTION_SEND).apply {
                    this.type = type
                    setPackage(INSTAGRAM_PACKAGE)
                }
                packageManagerCanHandle(intent, INSTAGRAM_PACKAGE)
            }
        }
        val intent = when (target) {
            "instagramStory" -> Intent(INSTAGRAM_STORY_ACTION).apply {
                setPackage(INSTAGRAM_PACKAGE)
            }
            "facebookFeed" -> Intent(Intent.ACTION_SEND).apply { type = "image/*" }
            "facebookStory" -> Intent(FACEBOOK_STORY_ACTION)
            else -> return false
        }
        val packages = when (target) {
            "facebookFeed", "facebookStory" -> FACEBOOK_PACKAGES
            else -> listOf(INSTAGRAM_PACKAGE)
        }
        return packages.any { packageName ->
            packageManagerCanHandle(intent, packageName)
        }
    }

    private fun packageManagerCanHandle(intent: Intent, packageName: String): Boolean {
        val candidate = Intent(intent).setPackage(packageName)
        return applicationContext.packageManager.queryIntentActivities(
            candidate,
            PackageManager.MATCH_DEFAULT_ONLY,
        ).isNotEmpty()
    }

    private companion object {
        const val INSTAGRAM_PACKAGE = "com.instagram.android"
        const val INSTAGRAM_STORY_ACTION = "com.instagram.share.ADD_TO_STORY"
        const val FACEBOOK_STORY_ACTION = "com.facebook.stories.ADD_TO_STORY"
        val FACEBOOK_PACKAGES = listOf("com.facebook.katana", "com.facebook.lite")
    }
}
