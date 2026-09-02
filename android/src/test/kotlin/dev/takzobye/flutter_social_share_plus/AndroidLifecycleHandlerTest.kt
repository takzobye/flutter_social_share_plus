package dev.takzobye.flutter_social_share_plus

import android.app.Activity
import android.content.Context
import android.content.Intent
import android.net.Uri
import io.flutter.plugin.common.MethodChannel
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class AndroidLifecycleHandlerTest {
    @Test
    fun facebookFeedIgnoresStalePreparationAfterRecreation() {
        assertStalePreparationIsIgnored { preparer, scope ->
            val handler = FacebookShareHandler(
                mediaPreparer = preparer,
                activityRequests = scope,
                mediaAvailability = AlwaysAvailableMedia,
            )
            LifecycleShare(
                share = { activity, result ->
                    handler.shareFeed(activity, listOf("/tmp/image.jpg"), null, result)
                },
                onDetachForConfigChanges = handler::onDetachedFromActivityForConfigChanges,
            )
        }
    }

    @Test
    fun facebookStoryIgnoresStalePreparationAfterRecreation() {
        assertStalePreparationIsIgnored { preparer, scope ->
            val handler = FacebookShareHandler(
                mediaPreparer = preparer,
                activityRequests = scope,
                mediaAvailability = AlwaysAvailableMedia,
            )
            LifecycleShare(
                share = { activity, result ->
                    handler.shareStory(
                        activity,
                        "facebook-app",
                        "/tmp/sticker.jpg",
                        null,
                        null,
                        null,
                        null,
                        null,
                        result,
                    )
                },
                onDetachForConfigChanges = handler::onDetachedFromActivityForConfigChanges,
            )
        }
    }

    @Test
    fun instagramFeedIgnoresStalePreparationAfterRecreation() {
        assertStalePreparationIsIgnored { preparer, scope ->
            val handler = InstagramShareHandler(
                mediaPreparer = preparer,
                activityRequests = scope,
                mediaAvailability = AlwaysAvailableMedia,
            )
            LifecycleShare(
                share = { activity, result ->
                    handler.shareFeed(activity, "/tmp/image.jpg", result)
                },
                onDetachForConfigChanges = handler::onDetachedFromActivityForConfigChanges,
            )
        }
    }

    @Test
    fun instagramStoryIgnoresStalePreparationAfterRecreation() {
        assertStalePreparationIsIgnored { preparer, scope ->
            val handler = InstagramShareHandler(
                mediaPreparer = preparer,
                activityRequests = scope,
                mediaAvailability = AlwaysAvailableMedia,
            )
            LifecycleShare(
                share = { activity, result ->
                    handler.shareStory(
                        activity,
                        "instagram-app",
                        "/tmp/sticker.jpg",
                        null,
                        null,
                        null,
                        null,
                        null,
                        result,
                    )
                },
                onDetachForConfigChanges = handler::onDetachedFromActivityForConfigChanges,
            )
        }
    }

    @Test
    fun facebookFeedKeepsBusyResponseWhileTheRequestIsActive() {
        val preparer = DeferredMediaPreparer()
        val scope = ActivityRequestScope<Activity>()
        val handler = FacebookShareHandler(
            mediaPreparer = preparer,
            activityRequests = scope,
            mediaAvailability = AlwaysAvailableMedia,
        )
        val activity = TestActivity()
        val firstResult = RecordingResult()
        val secondResult = RecordingResult()

        scope.attach(activity)
        handler.shareFeed(activity, listOf("/tmp/first.jpg"), null, firstResult)
        handler.shareFeed(activity, listOf("/tmp/second.jpg"), null, secondResult)

        assertTrue(firstResult.responses.isEmpty())
        assertEquals(
            listOf<Any?>(ShareResponse.failed("busy", "A Facebook share is already open")),
            secondResult.responses,
        )
    }

    private fun assertStalePreparationIsIgnored(
        factory: (MediaPreparer, ActivityRequestScope<Activity>) -> LifecycleShare,
    ) {
        val preparer = DeferredMediaPreparer()
        val scope = ActivityRequestScope<Activity>()
        val share = factory(preparer, scope)
        val oldActivity = TestActivity()
        val newActivity = TestActivity()
        val oldResult = RecordingResult()
        val newResult = RecordingResult()

        scope.attach(oldActivity)
        share(oldActivity, oldResult)
        share.detachForConfigChanges()

        scope.attach(newActivity)
        share(newActivity, newResult)

        assertEquals(2, preparer.callbacks.size)
        preparer.callbacks.first().invoke(emptyList(), null)

        assertEquals(listOf<Any?>(ShareResponse.activityRecreated()), oldResult.responses)
        assertTrue(newResult.responses.isEmpty())
        assertTrue(oldActivity.startedIntents.isEmpty())
        assertTrue(newActivity.startedIntents.isEmpty())
    }

    private class TestActivity : Activity() {
        val startedIntents = mutableListOf<Intent>()

        override fun getApplicationContext(): Context = this

        override fun grantUriPermission(packageName: String?, uri: Uri?, modeFlags: Int) = Unit

        override fun startActivity(intent: Intent) {
            startedIntents += intent
        }
    }

    private class LifecycleShare(
        private val share: (Activity, MethodChannel.Result) -> Unit,
        private val onDetachForConfigChanges: () -> Unit,
    ) {
        operator fun invoke(activity: Activity, result: MethodChannel.Result) {
            share(activity, result)
        }

        fun detachForConfigChanges() {
            onDetachForConfigChanges.invoke()
        }
    }

    private class DeferredMediaPreparer : MediaPreparer {
        val callbacks = mutableListOf<MediaPreparationCallback>()

        override fun prepareAsync(
            context: Context,
            paths: List<String>,
            maxVideoBytes: Long?,
            callback: MediaPreparationCallback,
        ) {
            callbacks += callback
        }
    }

    private object AlwaysAvailableMedia : MediaAvailability {
        override fun canHandle(context: Context, intent: Intent): Boolean = true
    }

    private class RecordingResult : MethodChannel.Result {
        val responses = mutableListOf<Any?>()

        override fun success(result: Any?) {
            responses += result
        }

        override fun error(errorCode: String, errorMessage: String?, errorDetails: Any?) = Unit

        override fun notImplemented() = Unit
    }
}
