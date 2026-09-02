package dev.takzobye.flutter_social_share_plus

import java.io.File
import kotlin.test.Test
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertNull
import kotlin.test.assertTrue

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

    @Test
    fun mediaPathsMustBeAbsolute() {
        assertTrue(ShareMedia.isAbsolutePath("/tmp/photo.jpg"))
        assertFalse(ShareMedia.isAbsolutePath("photo.jpg"))
    }

    @Test
    fun videoLimitOnlyAppliesToVideos() {
        val file = File.createTempFile("share", ".mp4")
        try {
            file.writeBytes(ByteArray(11))
            assertTrue(ShareMedia.videoExceedsLimit(file, "video/mp4", 10))
            assertFalse(ShareMedia.videoExceedsLimit(file, "image/png", 10))
            assertFalse(ShareMedia.videoExceedsLimit(file, "video/mp4", null))
        } finally {
            file.delete()
        }
    }
}
