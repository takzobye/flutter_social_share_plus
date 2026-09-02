package dev.takzobye.flutter_social_share_plus

/**
 * Tracks asynchronous work that is only valid while an Activity is attached.
 *
 * All methods are called on the Android main thread. Media preparation callbacks
 * are marshalled to that thread by [ShareMedia].
 */
internal class ActivityRequest internal constructor(
    private val onComplete: (Map<String, String>) -> Unit,
) {
    internal fun complete(response: Map<String, String>) {
        onComplete(response)
    }
}

internal class ActivityRequestScope<T> {

    private var attachedActivity: T? = null
    private val activeRequests = LinkedHashSet<ActivityRequest>()

    fun attach(activity: T) {
        attachedActivity = activity
    }

    fun begin(onComplete: (Map<String, String>) -> Unit): ActivityRequest? {
        if (attachedActivity == null) {
            return null
        }
        return ActivityRequest(onComplete).also { activeRequests += it }
    }

    fun activityFor(request: ActivityRequest): T? {
        return attachedActivity?.takeIf { activeRequests.contains(request) }
    }

    fun complete(request: ActivityRequest, response: Map<String, String>): Boolean {
        if (!activeRequests.remove(request)) {
            return false
        }
        request.complete(response)
        return true
    }

    fun detach(response: Map<String, String>) {
        attachedActivity = null
        val requests = activeRequests.toList()
        activeRequests.clear()
        requests.forEach { request -> request.complete(response) }
    }
}
