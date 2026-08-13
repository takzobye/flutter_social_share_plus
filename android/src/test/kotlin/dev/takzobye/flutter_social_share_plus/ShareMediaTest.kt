package dev.takzobye.flutter_social_share_plus

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertNull

class ShareMediaTest {
    @Test
    fun mimeTypesAreStable() {
        assertEquals("image/jpeg", ShareMedia.mimeType(File("photo.JPG")))
        assertEquals("image/png", ShareMedia.mimeType(File("sticker.png")))
        assertEquals("video/mp4", ShareMedia.mimeType(File("clip.mp4")))
        assertNull(ShareMedia.mimeType(File("unknown.zzz")))
    }

    @Test
    fun responseUsesThePublicProtocol() {
        assertEquals(mapOf("status" to "completed"), ShareResponse.completed())
        assertEquals(
            mapOf("status" to "failed", "code" to "busy", "message" to "Busy"),
            ShareResponse.failed("busy", "Busy"),
        )
    }
}
