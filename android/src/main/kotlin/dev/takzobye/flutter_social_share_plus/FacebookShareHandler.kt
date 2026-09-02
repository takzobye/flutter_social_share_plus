package dev.takzobye.flutter_social_share_plus

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import com.facebook.CallbackManager
import com.facebook.FacebookCallback
import com.facebook.FacebookException
import com.facebook.share.Sharer
import com.facebook.share.model.ShareHashtag
import com.facebook.share.model.SharePhoto
import com.facebook.share.model.SharePhotoContent
import com.facebook.share.widget.ShareDialog
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry

class FacebookShareHandler internal constructor(
    private val mediaPreparer: MediaPreparer = ShareMediaPreparer,
    private val activityRequests: ActivityRequestScope<Activity> = ActivityRequestScope(),
    private val mediaAvailability: MediaAvailability = ShareMediaAvailability,
) {
    private var callbackManager: CallbackManager? = null
    private var activityBinding: ActivityPluginBinding? = null
    private var activityResultListener: PluginRegistry.ActivityResultListener? = null
    private var feedRequest: ActivityRequest? = null

    fun onAttachedToActivity(binding: ActivityPluginBinding) {
        removeActivityResultListener()
        activityBinding = binding
        activityRequests.attach(binding.activity)
        callbackManager = callbackManager ?: CallbackManager.Factory.create()
        val listener = PluginRegistry.ActivityResultListener { requestCode, resultCode, data ->
            callbackManager?.onActivityResult(requestCode, resultCode, data) == true
        }
        activityResultListener = listener
        binding.addActivityResultListener(listener)
    }

    fun onDetachedFromActivityForConfigChanges() {
        removeActivityResultListener()
        activityBinding = null
        feedRequest = null
        activityRequests.detach(ShareResponse.activityRecreated())
        callbackManager = null
    }

    fun onDetachedFromActivity() {
        removeActivityResultListener()
        activityBinding = null
        feedRequest = null
        activityRequests.detach(ShareResponse.activityDetached())
        callbackManager = null
    }

    fun onDetachedFromEngine() {
        onDetachedFromActivity()
    }

    fun shareFeed(
        activity: Activity,
        imagePaths: List<String>?,
        hashtag: String?,
        result: Result,
    ) {
        val paths = imagePaths.orEmpty()
        if (paths.isEmpty() || paths.size > 6) {
            result.success(
                ShareResponse.failed("invalid_input", "Facebook Feed accepts one to six images")
            )
            return
        }
        if (hashtag != null && hashtag.isNotBlank() && !hashtag.startsWith("#")) {
            result.success(ShareResponse.failed("invalid_input", "Hashtags must start with #"))
            return
        }
        if (feedRequest != null) {
            result.success(ShareResponse.failed("busy", "A Facebook share is already open"))
            return
        }
        if (!isFacebookFeedAvailable(activity)) {
            result.success(ShareResponse.unavailable())
            return
        }

        val request = activityRequests.begin { response -> result.success(response) }
        if (request == null) {
            result.success(ShareResponse.failed("platform_error", "Activity not available"))
            return
        }
        feedRequest = request

        try {
            mediaPreparer.prepareAsync(
                context = activity.applicationContext,
                paths = paths,
                maxVideoBytes = null,
            ) { media, error ->
                val currentActivity = activityRequests.activityFor(request)
                    ?: return@prepareAsync
                if (error != null) {
                    completeFeed(request, error)
                    return@prepareAsync
                }
                val prepared = media.orEmpty()
                if (prepared.size != paths.size) {
                    completeFeed(
                        request,
                        ShareResponse.failed("platform_error", "Unable to prepare images"),
                    )
                    return@prepareAsync
                }
                if (prepared.any { !it.mimeType.startsWith("image/") }) {
                    completeFeed(
                        request,
                        ShareResponse.failed(
                            "unsupported_media",
                            "Facebook Feed accepts images only",
                        ),
                    )
                    return@prepareAsync
                }

                try {
                    val photos = prepared.map { mediaFile ->
                        SharePhoto.Builder()
                            .setImageUrl(mediaFile.uri)
                            .setUserGenerated(true)
                            .build()
                    }
                    val contentBuilder = SharePhotoContent.Builder().setPhotos(photos)
                    if (!hashtag.isNullOrBlank()) {
                        contentBuilder.setShareHashtag(
                            ShareHashtag.Builder().setHashtag(hashtag).build()
                        )
                    }
                    val content = contentBuilder.build()
                    val manager = callbackManager
                    if (manager == null) {
                        completeFeed(
                            request,
                            ShareResponse.failed("platform_error", "Facebook SDK is unavailable"),
                        )
                        return@prepareAsync
                    }

                    val dialog = ShareDialog(currentActivity)
                    dialog.registerCallback(manager, object : FacebookCallback<Sharer.Result> {
                        override fun onSuccess(result: Sharer.Result) {
                            completeFeed(request, ShareResponse.completed())
                        }

                        override fun onCancel() {
                            completeFeed(request, ShareResponse.cancelled())
                        }

                        override fun onError(error: FacebookException) {
                            completeFeed(
                                request,
                                ShareResponse.failed(
                                    "platform_error",
                                    error.message ?: "Facebook share failed",
                                ),
                            )
                        }
                    })

                    if (dialog.canShow(content, ShareDialog.Mode.NATIVE)) {
                        dialog.show(content, ShareDialog.Mode.NATIVE)
                    } else if (dialog.canShow(content)) {
                        dialog.show(content)
                    } else {
                        completeFeed(request, ShareResponse.unavailable())
                    }
                } catch (error: Exception) {
                    completeFeed(
                        request,
                        ShareResponse.failed(
                            "platform_error",
                            error.message ?: "Unable to open Facebook",
                        ),
                    )
                }
            }
        } catch (error: Exception) {
            completeFeed(
                request,
                ShareResponse.failed(
                    "platform_error",
                    error.message ?: "Unable to prepare images",
                ),
            )
        }
    }

    fun shareStory(
        activity: Activity,
        appId: String?,
        stickerPath: String?,
        backgroundImagePath: String?,
        backgroundVideoPath: String?,
        backgroundTopColor: String?,
        backgroundBottomColor: String?,
        attributionUrl: String?,
        result: Result,
    ) {
        if (appId.isNullOrBlank()) {
            result.success(ShareResponse.failed("invalid_input", "A Facebook App ID is required"))
            return
        }
        if (backgroundImagePath != null && backgroundVideoPath != null) {
            result.success(
                ShareResponse.failed(
                    "invalid_input",
                    "A Story cannot contain both an image and a video background",
                )
            )
            return
        }
        val paths = listOfNotNull(stickerPath, backgroundImagePath, backgroundVideoPath)
        if (paths.isEmpty()) {
            result.success(ShareResponse.failed("invalid_input", "Story content is required"))
            return
        }
        val packageName = FACEBOOK_PACKAGES.firstOrNull { packageName ->
            mediaAvailability.canHandle(
                activity,
                Intent(FACEBOOK_STORY_ACTION).apply { setPackage(packageName) },
            )
        }
        if (packageName == null) {
            result.success(ShareResponse.unavailable())
            return
        }

        val request = activityRequests.begin { response -> result.success(response) }
        if (request == null) {
            result.success(ShareResponse.failed("platform_error", "Activity not available"))
            return
        }

        try {
            mediaPreparer.prepareAsync(
                context = activity.applicationContext,
                paths = paths,
                maxVideoBytes = MAX_STORY_VIDEO_BYTES,
            ) { media, error ->
                val currentActivity = activityRequests.activityFor(request)
                    ?: return@prepareAsync
                if (error != null) {
                    activityRequests.complete(request, error)
                    return@prepareAsync
                }
                val prepared = media ?: run {
                    activityRequests.complete(
                        request,
                        ShareResponse.failed("platform_error", "Unable to prepare Story"),
                    )
                    return@prepareAsync
                }

                try {
                    val sticker = stickerPath?.let { prepared[paths.indexOf(it)] }
                    val backgroundImage = backgroundImagePath?.let { prepared[paths.indexOf(it)] }
                    val backgroundVideo = backgroundVideoPath?.let { prepared[paths.indexOf(it)] }
                    if (sticker != null && !sticker.mimeType.startsWith("image/")) {
                        activityRequests.complete(
                            request,
                            ShareResponse.failed("unsupported_media", "Sticker must be an image"),
                        )
                        return@prepareAsync
                    }
                    if (backgroundImage != null && !backgroundImage.mimeType.startsWith("image/")) {
                        activityRequests.complete(
                            request,
                            ShareResponse.failed(
                                "unsupported_media",
                                "Background must be an image",
                            ),
                        )
                        return@prepareAsync
                    }
                    if (backgroundVideo != null && !backgroundVideo.mimeType.startsWith("video/")) {
                        activityRequests.complete(
                            request,
                            ShareResponse.failed(
                                "unsupported_media",
                                "Background must be a video",
                            ),
                        )
                        return@prepareAsync
                    }
                    val shareIntent = Intent(FACEBOOK_STORY_ACTION).apply {
                        setPackage(packageName)
                        putExtra("com.facebook.platform.extra.APPLICATION_ID", appId)
                        backgroundImage?.let { mediaFile ->
                            data = mediaFile.uri
                            type = mediaFile.mimeType
                            clipData = ClipData.newRawUri("background", mediaFile.uri)
                        }
                        backgroundVideo?.let { mediaFile ->
                            data = mediaFile.uri
                            type = mediaFile.mimeType
                            clipData = ClipData.newRawUri("background", mediaFile.uri)
                        }
                        sticker?.let { mediaFile ->
                            putExtra("interactive_asset_uri", mediaFile.uri)
                        }
                        backgroundTopColor?.let { putExtra("top_background_color", it) }
                        backgroundBottomColor?.let { putExtra("bottom_background_color", it) }
                        attributionUrl?.let { putExtra("content_url", it) }
                        addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    }
                    backgroundImage?.let { ShareMedia.grant(currentActivity, it, packageName) }
                    backgroundVideo?.let { ShareMedia.grant(currentActivity, it, packageName) }
                    sticker?.let { ShareMedia.grant(currentActivity, it, packageName) }
                    currentActivity.startActivity(shareIntent)
                    activityRequests.complete(request, ShareResponse.launched())
                } catch (error: Exception) {
                    activityRequests.complete(
                        request,
                        ShareResponse.failed(
                            "platform_error",
                            error.message ?: "Unable to open Facebook Stories",
                        ),
                    )
                }
            }
        } catch (error: Exception) {
            activityRequests.complete(
                request,
                ShareResponse.failed(
                    "platform_error",
                    error.message ?: "Unable to prepare Story",
                ),
            )
        }
    }

    private fun isFacebookFeedAvailable(activity: Activity): Boolean {
        val intent = Intent(Intent.ACTION_SEND).apply { type = "image/*" }
        return FACEBOOK_PACKAGES.any { packageName ->
            mediaAvailability.canHandle(
                activity,
                Intent(intent).apply { setPackage(packageName) },
            )
        }
    }

    private fun completeFeed(request: ActivityRequest, response: Map<String, String>) {
        if (feedRequest !== request) {
            return
        }
        feedRequest = null
        activityRequests.complete(request, response)
    }

    private fun removeActivityResultListener() {
        val binding = activityBinding
        val listener = activityResultListener
        if (binding != null && listener != null) {
            binding.removeActivityResultListener(listener)
        }
        activityResultListener = null
    }

    private companion object {
        const val FACEBOOK_STORY_ACTION = "com.facebook.stories.ADD_TO_STORY"
        const val MAX_STORY_VIDEO_BYTES = 50L * 1024 * 1024
        val FACEBOOK_PACKAGES = listOf("com.facebook.katana", "com.facebook.lite")
    }
}
