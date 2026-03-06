package dev.takzobye.flutter_social_share_plus

import android.app.Activity
import android.content.Intent
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.core.content.FileProvider
import com.facebook.CallbackManager
import com.facebook.FacebookCallback
import com.facebook.FacebookException
import com.facebook.FacebookSdk
import com.facebook.share.Sharer
import com.facebook.share.model.ShareHashtag
import com.facebook.share.model.SharePhoto
import com.facebook.share.model.SharePhotoContent
import com.facebook.share.widget.ShareDialog
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class FacebookShareHandler {

    companion object {
        private const val FACEBOOK_PACKAGE = "com.facebook.katana"
        private const val FACEBOOK_LITE_PACKAGE = "com.facebook.lite"
        private const val FACEBOOK_STORY_ACTION = "com.facebook.stories.ADD_TO_STORY"
    }

    private var callbackManager: CallbackManager? = null

    fun onAttachedToActivity(binding: ActivityPluginBinding) {
        FacebookSdk.fullyInitialize()
        callbackManager = CallbackManager.Factory.create()
        binding.addActivityResultListener { requestCode, resultCode, data ->
            callbackManager?.onActivityResult(requestCode, resultCode, data) ?: false
        }
    }

    fun shareFeed(
        activity: Activity,
        filePaths: List<String>,
        hashtag: String?,
        result: Result,
    ) {
        if (!isFacebookInstalled(activity)) {
            result.success("APP_NOT_INSTALLED")
            return
        }
        if (filePaths.isEmpty()) {
            result.success("ERROR:No files provided")
            return
        }

        val photos = filePaths.mapNotNull { path ->
            val file = File(path)
            if (file.exists()) {
                val bitmap = BitmapFactory.decodeFile(file.absolutePath)
                if (bitmap != null) SharePhoto.Builder().setBitmap(bitmap).build() else null
            } else {
                null
            }
        }

        if (photos.isEmpty()) {
            result.success("ERROR:No valid images found")
            return
        }

        val contentBuilder = SharePhotoContent.Builder().setPhotos(photos)

        if (!hashtag.isNullOrEmpty()) {
            contentBuilder.setShareHashtag(
                ShareHashtag.Builder().setHashtag(hashtag).build()
            )
        }

        val content = contentBuilder.build()

        val manager = callbackManager
        if (manager == null) {
            result.success("ERROR:Facebook SDK not initialized")
            return
        }

        val shareDialog = ShareDialog(activity)
        shareDialog.registerCallback(manager, object : FacebookCallback<Sharer.Result> {
            override fun onSuccess(shareResult: Sharer.Result) {
                result.success("SUCCESS")
            }

            override fun onCancel() {
                result.success("CANCELLED")
            }

            override fun onError(error: FacebookException) {
                result.success("ERROR:${error.message}")
            }
        })

        if (shareDialog.canShow(content, ShareDialog.Mode.NATIVE)) {
            shareDialog.show(content, ShareDialog.Mode.NATIVE)
        } else if (shareDialog.canShow(content)) {
            shareDialog.show(content)
        } else {
            result.success("ERROR:Cannot show Facebook share dialog")
        }
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
        if (!isFacebookInstalled(activity)) {
            result.success("APP_NOT_INSTALLED")
            return
        }

        val intent = Intent(FACEBOOK_STORY_ACTION).apply {
            putExtra("com.facebook.platform.extra.APPLICATION_ID", appId)

            backgroundImage?.let { path ->
                val file = File(path)
                if (file.exists()) {
                    val uri = getFileUri(activity, file)
                    setDataAndType(uri, getMimeType(file))
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    grantUri(activity, uri)
                }
            }

            backgroundVideo?.let { path ->
                val file = File(path)
                if (file.exists()) {
                    val uri = getFileUri(activity, file)
                    setDataAndType(uri, "video/*")
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    grantUri(activity, uri)
                }
            }

            stickerImage?.let { path ->
                val file = File(path)
                if (file.exists()) {
                    val uri = getFileUri(activity, file)
                    putExtra("interactive_asset_uri", uri)
                    addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                    grantUri(activity, uri)
                }
            }

            backgroundTopColor?.let { putExtra("top_background_color", it) }
            backgroundBottomColor?.let { putExtra("bottom_background_color", it) }
            attributionURL?.let { putExtra("content_url", it) }
        }

        activity.startActivity(intent)
        result.success("SUCCESS")
    }

    private fun isFacebookInstalled(activity: Activity): Boolean {
        return isPackageInstalled(activity, FACEBOOK_PACKAGE)
                || isPackageInstalled(activity, FACEBOOK_LITE_PACKAGE)
    }

    private fun isPackageInstalled(activity: Activity, packageName: String): Boolean {
        return try {
            activity.packageManager.getPackageInfo(packageName, 0)
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

    private fun grantUri(activity: Activity, uri: Uri) {
        activity.grantUriPermission(FACEBOOK_PACKAGE, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
        activity.grantUriPermission(FACEBOOK_LITE_PACKAGE, uri, Intent.FLAG_GRANT_READ_URI_PERMISSION)
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
            else -> "image/*"
        }
    }
}
