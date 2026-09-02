package dev.takzobye.flutter_social_share_plus

internal object ShareResponse {
    fun completed() = mapOf("status" to "completed")

    fun launched() = mapOf("status" to "launched")

    fun cancelled() = mapOf("status" to "cancelled")

    fun unavailable() = mapOf("status" to "unavailable")

    fun failed(code: String, message: String) = mapOf(
        "status" to "failed",
        "code" to code,
        "message" to message,
    )

    fun activityRecreated() = failed("platform_error", "Activity recreated")

    fun activityDetached() = failed("platform_error", "Activity detached")
}
