package dev.takzobye.flutter_social_share_plus

import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

class ActivityRequestScopeTest {
    @Test
    fun staleRequestCannotCompleteANewRequest() {
        val scope = ActivityRequestScope<String>()
        val oldResponses = mutableListOf<Map<String, String>>()
        val newResponses = mutableListOf<Map<String, String>>()

        scope.attach("old activity")
        val oldRequest = checkNotNull(scope.begin { response -> oldResponses += response })

        scope.detach(ShareResponse.activityRecreated())

        scope.attach("new activity")
        val newRequest = checkNotNull(scope.begin { response -> newResponses += response })

        assertEquals(listOf(ShareResponse.activityRecreated()), oldResponses)
        assertNull(scope.activityFor(oldRequest))
        assertEquals("new activity", scope.activityFor(newRequest))

        assertFalse(scope.complete(oldRequest, ShareResponse.completed()))
        assertTrue(scope.complete(newRequest, ShareResponse.completed()))

        assertEquals(listOf(ShareResponse.completed()), newResponses)
    }

    @Test
    fun detachCompletesEveryRequestOnlyOnce() {
        val scope = ActivityRequestScope<String>()
        val firstResponses = mutableListOf<Map<String, String>>()
        val secondResponses = mutableListOf<Map<String, String>>()

        scope.attach("activity")
        val firstRequest = checkNotNull(scope.begin { response -> firstResponses += response })
        val secondRequest = checkNotNull(scope.begin { response -> secondResponses += response })

        scope.detach(ShareResponse.activityDetached())
        scope.detach(ShareResponse.activityRecreated())

        assertEquals(listOf(ShareResponse.activityDetached()), firstResponses)
        assertEquals(listOf(ShareResponse.activityDetached()), secondResponses)
        assertFalse(scope.complete(firstRequest, ShareResponse.completed()))
        assertFalse(scope.complete(secondRequest, ShareResponse.completed()))
    }

    @Test
    fun completedRequestNoLongerProvidesAnActivity() {
        val scope = ActivityRequestScope<String>()
        val responses = mutableListOf<Map<String, String>>()

        scope.attach("activity")
        val request = checkNotNull(scope.begin { response -> responses += response })

        assertTrue(scope.complete(request, ShareResponse.launched()))
        assertNull(scope.activityFor(request))
        assertFalse(scope.complete(request, ShareResponse.completed()))
        assertEquals(listOf(ShareResponse.launched()), responses)
    }
}
