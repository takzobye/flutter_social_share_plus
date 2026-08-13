package dev.takzobye.flutter_social_share_plus

import android.app.Activity
import android.content.ClipData
import android.content.Intent
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class InstagramShareHandler {
    fun shareFeed(activity: Activity, filePath: String?, result: Result) {
        val path = filePath?.takeIf { it.isNotBlank() }
        if (path == null) {
            result.success(ShareResponse.failed("invalid_input", "A media path is required"))
            return
        }

        val intent = Intent(Intent.ACTION_SEND).setPackage(INSTAGRAM_PACKAGE)
        if (!listOf("image/*", "video/*").any { type ->
                ShareMedia.canHandle(activity, Intent(intent).setType(type))
            }) {
            result.success(ShareResponse.unavailable())
            return
        }

        ShareMedia.prepareAsync(activity, listOf(path)) { media, error ->
            if (error != null) {
                result.success(error)
                return@prepareAsync
            }
            val prepared = media?.singleOrNull()
            if (prepared == null) {
                result.success(ShareResponse.failed("platform_error", "Unable to prepare media"))
                return@prepareAsync
            }
            if (!prepared.mimeType.startsWith("image/") && !prepared.mimeType.startsWith("video/")) {
                result.success(ShareResponse.failed("unsupported_media", "Instagram requires an image or video"))
                return@prepareAsync
            }

            val shareIntent = Intent(intent).apply {
                type = prepared.mimeType
                putExtra(Intent.EXTRA_STREAM, prepared.uri)
                clipData = ClipData.newRawUri("shared media", prepared.uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            try {
                ShareMedia.grant(activity, prepared, INSTAGRAM_PACKAGE)
                activity.startActivity(shareIntent)
                result.success(ShareResponse.launched())
            } catch (error: Exception) {
                result.success(
                    ShareResponse.failed(
                        "platform_error",
                        error.message ?: "Unable to open Instagram",
                    )
                )
            }
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

        val intent = Intent(INSTAGRAM_STORY_ACTION).apply {
            setPackage(INSTAGRAM_PACKAGE)
        }
        if (!ShareMedia.canHandle(activity, intent)) {
            result.success(ShareResponse.unavailable())
            return
        }

        ShareMedia.prepareAsync(
            activity,
            paths,
            maxVideoBytes = MAX_STORY_VIDEO_BYTES,
        ) { media, error ->
            if (error != null) {
                result.success(error)
                return@prepareAsync
            }
            val prepared = media ?: run {
                result.success(ShareResponse.failed("platform_error", "Unable to prepare Story"))
                return@prepareAsync
            }
            val sticker = stickerPath?.let { prepared[paths.indexOf(it)] }
            val backgroundImage = backgroundImagePath?.let { prepared[paths.indexOf(it)] }
            val backgroundVideo = backgroundVideoPath?.let { prepared[paths.indexOf(it)] }
            if (sticker != null && !sticker.mimeType.startsWith("image/")) {
                result.success(ShareResponse.failed("unsupported_media", "Sticker must be an image"))
                return@prepareAsync
            }
            if (backgroundImage != null && !backgroundImage.mimeType.startsWith("image/")) {
                result.success(ShareResponse.failed("unsupported_media", "Background must be an image"))
                return@prepareAsync
            }
            if (backgroundVideo != null && !backgroundVideo.mimeType.startsWith("video/")) {
                result.success(ShareResponse.failed("unsupported_media", "Background must be a video"))
                return@prepareAsync
            }
            val shareIntent = Intent(intent).apply {
                putExtra("source_application", appId)
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
                sticker?.let { mediaFile -> putExtra("interactive_asset_uri", mediaFile.uri) }
                backgroundTopColor?.let { putExtra("top_background_color", it) }
                backgroundBottomColor?.let { putExtra("bottom_background_color", it) }
                attributionUrl?.let { putExtra("content_url", it) }
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            }
            try {
                backgroundImage?.let { ShareMedia.grant(activity, it, INSTAGRAM_PACKAGE) }
                backgroundVideo?.let { ShareMedia.grant(activity, it, INSTAGRAM_PACKAGE) }
                sticker?.let { ShareMedia.grant(activity, it, INSTAGRAM_PACKAGE) }
                activity.startActivity(shareIntent)
                result.success(ShareResponse.launched())
            } catch (error: Exception) {
                result.success(
                    ShareResponse.failed(
                        "platform_error",
                        error.message ?: "Unable to open Instagram Stories",
                    )
                )
            }
        }
    }

    private companion object {
        const val INSTAGRAM_PACKAGE = "com.instagram.android"
        const val INSTAGRAM_STORY_ACTION = "com.instagram.share.ADD_TO_STORY"
        const val MAX_STORY_VIDEO_BYTES = 50L * 1024 * 1024
    }
}
