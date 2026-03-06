package dev.takzobye.flutter_social_share_plus

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class InstagramShareHandler {

    companion object {
        private const val INSTAGRAM_PACKAGE = "com.instagram.android"
        private const val INSTAGRAM_STORY_ACTION = "com.instagram.share.ADD_TO_STORY"
    }

    fun shareDirect(activity: Activity, message: String, result: Result) {
        if (!isInstagramInstalled(activity)) {
            result.success("APP_NOT_INSTALLED")
            return
        }
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "text/plain"
            setPackage(INSTAGRAM_PACKAGE)
            putExtra(Intent.EXTRA_TEXT, message)
        }
        activity.startActivity(intent)
        result.success("SUCCESS")
    }

    fun shareFeed(activity: Activity, filePath: String, message: String?, result: Result) {
        if (!isInstagramInstalled(activity)) {
            result.success("APP_NOT_INSTALLED")
            return
        }
        val file = File(filePath)
        if (!file.exists()) {
            result.success("ERROR:File not found: $filePath")
            return
        }
        val uri = getFileUri(activity, file)
        val mimeType = getMimeType(file)

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            setPackage(INSTAGRAM_PACKAGE)
            putExtra(Intent.EXTRA_STREAM, uri)
            if (!message.isNullOrEmpty()) {
                putExtra(Intent.EXTRA_TEXT, message)
            }
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(intent)
        result.success("SUCCESS")
    }

    fun shareFeedMultiple(activity: Activity, filePaths: List<String>, result: Result) {
        if (!isInstagramInstalled(activity)) {
            result.success("APP_NOT_INSTALLED")
            return
        }
        if (filePaths.isEmpty()) {
            result.success("ERROR:No files provided")
            return
        }
        val uris = ArrayList<Uri>()
        for (path in filePaths) {
            val file = File(path)
            if (file.exists()) {
                uris.add(getFileUri(activity, file))
            }
        }
        if (uris.isEmpty()) {
            result.success("ERROR:No valid files found")
            return
        }

        val intent = Intent(Intent.ACTION_SEND_MULTIPLE).apply {
            type = "image/*"
            setPackage(INSTAGRAM_PACKAGE)
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(intent)
        result.success("SUCCESS")
    }

    fun shareReels(activity: Activity, videoPath: String, result: Result) {
        if (!isInstagramInstalled(activity)) {
            result.success("APP_NOT_INSTALLED")
            return
        }
        val file = File(videoPath)
        if (!file.exists()) {
            result.success("ERROR:File not found: $videoPath")
            return
        }
        val uri = getFileUri(activity, file)

        val intent = Intent(Intent.ACTION_SEND).apply {
            type = "video/*"
            setPackage(INSTAGRAM_PACKAGE)
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        activity.startActivity(intent)
        result.success("SUCCESS")
    }

    fun shareStory(
        activity: Activity,
        appId: String,
        stickerImage: String?,
        backgroundImage: String?,
        backgroundVideo: String?,
        backgroundTopColor: String?,
        backgroundBottomColor: String?,
        attributionURL: String?,
        result: Result,
    ) {
        if (!isInstagramInstalled(activity)) {
            result.success("APP_NOT_INSTALLED")
            return
        }

        val intent = Intent(INSTAGRAM_STORY_ACTION).apply {
            putExtra("source_application", appId)

            backgroundImage?.let { path ->
                val file = File(path)
                if (file.exists()) {
                    val uri = getFileUri(activity, file)
                    setDataAndType(uri, getMimeType(file))
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    activity.grantUriPermission(
                        INSTAGRAM_PACKAGE, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                }
            }

            backgroundVideo?.let { path ->
                val file = File(path)
                if (file.exists()) {
                    val uri = getFileUri(activity, file)
                    setDataAndType(uri, "video/*")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    activity.grantUriPermission(
                        INSTAGRAM_PACKAGE, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                }
            }

            stickerImage?.let { path ->
                val file = File(path)
                if (file.exists()) {
                    val uri = getFileUri(activity, file)
                    putExtra("interactive_asset_uri", uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    activity.grantUriPermission(
                        INSTAGRAM_PACKAGE, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION
                    )
                }
            }

            backgroundTopColor?.let { putExtra("top_background_color", it) }
            backgroundBottomColor?.let { putExtra("bottom_background_color", it) }
            attributionURL?.let { putExtra("content_url", it) }
        }

        activity.startActivity(intent)
        result.success("SUCCESS")
    }

    private fun isInstagramInstalled(activity: Activity): Boolean {
        return try {
            activity.packageManager.getPackageInfo(INSTAGRAM_PACKAGE, 0)
            true
        } catch (_: Exception) {
            false
        }
    }

    private fun getFileUri(activity: Activity, file: File): Uri {
        return FileProvider.getUriForFile(
            activity,
            "${activity.packageName}.provider",
            file,
        )
    }

    private fun getMimeType(file: File): String {
        val extension = file.extension.lowercase()
        return when (extension) {
            "jpg", "jpeg" -> "image/jpeg"
            "png" -> "image/png"
            "gif" -> "image/gif"
            "webp" -> "image/webp"
            "mp4" -> "video/mp4"
            "mov" -> "video/quicktime"
            "avi" -> "video/x-msvideo"
            else -> "image/*"
        }
    }
}
