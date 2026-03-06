package dev.takzobye.flutter_social_share_plus

import android.app.Activity
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel.Result
import java.io.File

class SystemShareHandler {

    fun share(
        activity: Activity,
        text: String?,
        filePaths: List<String>?,
        subject: String?,
        result: Result,
    ) {
        val files = filePaths?.mapNotNull { path ->
            val file = File(path)
            if (file.exists()) file else null
        } ?: emptyList()

        if (text.isNullOrEmpty() && files.isEmpty()) {
            result.success("ERROR:Nothing to share – provide text or files")
            return
        }

        val intent = if (files.size > 1) {
            buildMultipleFileIntent(activity, text, files, subject)
        } else {
            buildSingleIntent(activity, text, files.firstOrNull(), subject)
        }

        val chooser = Intent.createChooser(intent, null)
        activity.startActivity(chooser)
        result.success("SUCCESS")
    }

    private fun buildSingleIntent(
        activity: Activity,
        text: String?,
        file: File?,
        subject: String?,
    ): Intent {
        return Intent(Intent.ACTION_SEND).apply {
            if (file != null) {
                val uri = getFileUri(activity, file)
                type = getMimeType(file)
                putExtra(Intent.EXTRA_STREAM, uri)
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            } else {
                type = "text/plain"
            }
            text?.let { putExtra(Intent.EXTRA_TEXT, it) }
            subject?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
        }
    }

    private fun buildMultipleFileIntent(
        activity: Activity,
        text: String?,
        files: List<File>,
        subject: String?,
    ): Intent {
        val uris = ArrayList<Uri>()
        for (file in files) {
            uris.add(getFileUri(activity, file))
        }
        return Intent(Intent.ACTION_SEND_MULTIPLE).apply {
            type = "*/*"
            putParcelableArrayListExtra(Intent.EXTRA_STREAM, uris)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            text?.let { putExtra(Intent.EXTRA_TEXT, it) }
            subject?.let { putExtra(Intent.EXTRA_SUBJECT, it) }
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
            "pdf" -> "application/pdf"
            "txt" -> "text/plain"
            else -> "*/*"
        }
    }
}
