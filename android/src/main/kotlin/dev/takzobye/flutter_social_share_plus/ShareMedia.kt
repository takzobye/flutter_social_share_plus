package dev.takzobye.flutter_social_share_plus

import android.content.pm.PackageManager
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Handler
import android.os.Looper
import androidx.core.content.FileProvider
import java.io.File
import java.net.URLConnection
import java.util.UUID
import java.util.concurrent.Executors

internal data class PreparedMedia(
    val file: File,
    val uri: Uri,
    val mimeType: String,
)

internal typealias MediaPreparationCallback =
    (List<PreparedMedia>?, Map<String, String>?) -> Unit

internal fun interface MediaPreparer {
    fun prepareAsync(
        context: Context,
        paths: List<String>,
        maxVideoBytes: Long?,
        callback: MediaPreparationCallback,
    )
}

internal fun interface MediaAvailability {
    fun canHandle(context: Context, intent: Intent): Boolean
}

internal object ShareMediaPreparer : MediaPreparer {
    override fun prepareAsync(
        context: Context,
        paths: List<String>,
        maxVideoBytes: Long?,
        callback: MediaPreparationCallback,
    ) {
        ShareMedia.prepareAsync(context, paths, maxVideoBytes, callback)
    }
}

internal object ShareMediaAvailability : MediaAvailability {
    override fun canHandle(context: Context, intent: Intent): Boolean =
        ShareMedia.canHandle(context, intent)
}

internal object ShareMedia {
    private const val AUTHORITY_SUFFIX = ".flutter_social_share_plus.fileprovider"
    private const val CACHE_DIRECTORY = "flutter_social_share_plus"
    private val executor = Executors.newCachedThreadPool()
    private val main by lazy { Handler(Looper.getMainLooper()) }

    fun prepareAsync(
        context: Context,
        paths: List<String>,
        maxVideoBytes: Long? = null,
        callback: MediaPreparationCallback,
    ) {
        val applicationContext = context.applicationContext ?: context
        executor.execute {
            val preparation = try {
                prepare(applicationContext, paths, maxVideoBytes) to null
            } catch (error: PreparationException) {
                null to ShareResponse.failed(error.code, error.message)
            } catch (error: Exception) {
                null to ShareResponse.failed(
                    "platform_error",
                    error.message ?: "Unable to prepare media",
                )
            }
            main.post { callback(preparation.first, preparation.second) }
        }
    }

    fun mimeType(file: File): String? = when (file.extension.lowercase()) {
        "jpg", "jpeg" -> "image/jpeg"
        "png" -> "image/png"
        "gif" -> "image/gif"
        "webp" -> "image/webp"
        "heic", "heif" -> "image/heic"
        "mp4" -> "video/mp4"
        "mov" -> "video/quicktime"
        "m4v" -> "video/x-m4v"
        "avi" -> "video/x-msvideo"
        else -> URLConnection.guessContentTypeFromName(file.name)
    }

    fun authority(context: Context) = context.packageName + AUTHORITY_SUFFIX

    fun canHandle(context: Context, intent: Intent): Boolean =
        context.packageManager.queryIntentActivities(
            intent,
            PackageManager.MATCH_DEFAULT_ONLY,
        ).isNotEmpty()

    fun grant(context: Context, media: PreparedMedia, packageName: String) {
        context.grantUriPermission(
            packageName,
            media.uri,
            android.content.Intent.FLAG_GRANT_READ_URI_PERMISSION,
        )
    }

    fun cleanup(context: Context) {
        val directory = File(context.cacheDir, CACHE_DIRECTORY)
        directory.listFiles()?.forEach { file ->
            if (System.currentTimeMillis() - file.lastModified() > 24 * 60 * 60 * 1000) {
                file.delete()
            }
        }
    }

    internal fun isAbsolutePath(path: String) = File(path).isAbsolute

    internal fun videoExceedsLimit(file: File, mimeType: String, maxBytes: Long?) =
        maxBytes != null && mimeType.startsWith("video/") && file.length() > maxBytes

    private fun prepare(
        context: Context,
        paths: List<String>,
        maxVideoBytes: Long?,
    ): List<PreparedMedia> {
        if (paths.isEmpty()) {
            throw PreparationException("invalid_input", "No media files provided")
        }

        cleanup(context)
        return paths.map { path ->
            if (path.isBlank()) {
                throw PreparationException("invalid_input", "Media path is empty")
            }
            if (!isAbsolutePath(path)) {
                throw PreparationException("invalid_input", "Media path must be absolute: $path")
            }
            val source = File(path)
            if (!source.isFile || !source.canRead()) {
                throw PreparationException("file_not_found", "File not found: $path")
            }
            val mimeType = mimeType(source)
                ?: throw PreparationException("unsupported_media", "Unsupported media: $path")
            if (videoExceedsLimit(source, mimeType, maxVideoBytes)) {
                throw PreparationException("invalid_input", "Story video must be 50 MiB or smaller")
            }
            val file = if (isAppFile(context, source)) source else copyToCache(context, source)
            val uri = FileProvider.getUriForFile(context, authority(context), file)
            PreparedMedia(file, uri, mimeType)
        }
    }

    private fun isAppFile(context: Context, file: File): Boolean {
        val source = file.canonicalFile
        val roots = listOfNotNull(
            context.filesDir,
            File(context.cacheDir, CACHE_DIRECTORY),
            context.getExternalFilesDir(null),
            context.externalCacheDir,
        ).map { it.canonicalFile }
        return roots.any { root ->
            source.path == root.path || source.path.startsWith(root.path + File.separator)
        }
    }

    private fun copyToCache(context: Context, source: File): File {
        val directory = File(context.cacheDir, CACHE_DIRECTORY).apply { mkdirs() }
        return File(directory, "${UUID.randomUUID()}-${source.name}").also {
            source.copyTo(it, overwrite = true)
        }
    }

    private class PreparationException(
        val code: String,
        override val message: String,
    ) : Exception(message)
}
