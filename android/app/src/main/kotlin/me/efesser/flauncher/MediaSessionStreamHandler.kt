/*
 * FLauncher
 * Copyright (C) 2021  Étienne Fesser
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

package me.efesser.flauncher

import android.app.PendingIntent
import android.content.ComponentName
import android.content.Context
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.AudioAttributes
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.KeyEvent
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import java.io.ByteArrayOutputStream

private const val ART_MAX_SIZE = 512

private val ACTIVE_STATES = setOf(
    PlaybackState.STATE_PLAYING,
    PlaybackState.STATE_BUFFERING,
    PlaybackState.STATE_CONNECTING,
    PlaybackState.STATE_FAST_FORWARDING,
    PlaybackState.STATE_REWINDING,
    PlaybackState.STATE_SKIPPING_TO_NEXT,
    PlaybackState.STATE_SKIPPING_TO_PREVIOUS,
    PlaybackState.STATE_SKIPPING_TO_QUEUE_ITEM,
)

private val MEDIA_KEYS = setOf(
    KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE,
    KeyEvent.KEYCODE_MEDIA_PLAY,
    KeyEvent.KEYCODE_MEDIA_PAUSE,
    KeyEvent.KEYCODE_MEDIA_NEXT,
    KeyEvent.KEYCODE_MEDIA_PREVIOUS,
)

private val PLAY_KEYS = setOf(KeyEvent.KEYCODE_MEDIA_PLAY_PAUSE, KeyEvent.KEYCODE_MEDIA_PLAY)

private val AUDIO_CONTENT_TYPES = setOf(AudioAttributes.CONTENT_TYPE_MUSIC, AudioAttributes.CONTENT_TYPE_SPEECH)

/**
 * Streams the "now playing" media session to Flutter and forwards media keys to it.
 *
 * Reading other apps' media sessions requires notification access to be granted to [MediaNotificationListener]:
 * `adb shell cmd notification allow_listener me.efesser.flauncher/me.efesser.flauncher.MediaNotificationListener`
 */
class MediaSessionStreamHandler(
    private val context: Context,
    private val launchApp: (String) -> Boolean,
) : StreamHandler {
    private val mediaSessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    private val listenerComponent = ComponentName(context, MediaNotificationListener::class.java)
    private val handler = Handler(Looper.getMainLooper())
    private var events: EventSink? = null
    private var sessionsListenerRegistered = false
    private var controllers: List<MediaController> = emptyList()
    private var currentController: MediaController? = null
    private var lastArtBitmap: Bitmap? = null
    private var lastArtBytes: ByteArray? = null
    private var lastEngagements: Map<String, Long> = emptyMap()

    private val sessionsChangedListener = MediaSessionManager.OnActiveSessionsChangedListener {
        updateControllers(it ?: emptyList())
    }

    private val controllerCallback = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(state: PlaybackState?) = selectController()
        override fun onMetadataChanged(metadata: MediaMetadata?) = selectController()
        override fun onSessionDestroyed() = selectController()
    }

    override fun onListen(arguments: Any?, events: EventSink) {
        this.events = events
        start()
    }

    override fun onCancel(arguments: Any?) {
        stop()
        events = null
    }

    /** Subscribes again if it previously failed, e.g. because notification access has been granted since. */
    fun refresh() {
        if (events != null && !sessionsListenerRegistered) {
            start()
        }
    }

    fun dispose() = stop()

    /**
     * Some apps don't publish a media session while they play (e.g. arte), which would leave an older paused session
     * shown while another app has been watched since: the "Continue watching" programs these apps publish tell it.
     *
     * [engagements] is the last time a program of each app was watched, in milliseconds since the epoch.
     */
    fun updateLastEngagements(engagements: Map<String, Long>) {
        lastEngagements = engagements
        selectController()
    }

    /**
     * Forwards media keys to the session shown on the home screen, as the system would otherwise send them to its
     * own pick (the last session which received one).
     *
     * Videos must not play behind the launcher though: for anything that isn't known to be audio, play keys open the
     * app instead and other keys are ignored.
     */
    fun dispatchMediaKey(event: KeyEvent): Boolean {
        val controller = currentController
        if (event.keyCode !in MEDIA_KEYS || controller == null) {
            return false
        }
        if (isAudio(controller)) {
            return controller.dispatchMediaButtonEvent(event)
        }
        if (event.keyCode in PLAY_KEYS && event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
            openPlayer()
        }
        return true
    }

    /** Opens the player of the current session, or its app if it doesn't provide one. */
    fun openPlayer(): Boolean {
        val controller = currentController ?: return false
        return try {
            controller.sessionActivity?.send() != null
        } catch (e: PendingIntent.CanceledException) {
            false
        } || launchApp(controller.packageName)
    }

    /** Audio attributes are often left unknown by video apps, so only an explicit audio declaration is trusted. */
    private fun isAudio(controller: MediaController): Boolean {
        if (controller.playbackInfo?.audioAttributes?.contentType in AUDIO_CONTENT_TYPES) {
            return true
        }
        return Build.VERSION.SDK_INT >= Build.VERSION_CODES.O && try {
            context.packageManager.getApplicationInfo(controller.packageName, 0).category ==
                ApplicationInfo.CATEGORY_AUDIO
        } catch (e: PackageManager.NameNotFoundException) {
            false
        }
    }

    private fun start() {
        try {
            mediaSessionManager.addOnActiveSessionsChangedListener(sessionsChangedListener, listenerComponent, handler)
            sessionsListenerRegistered = true
            updateControllers(mediaSessionManager.getActiveSessions(listenerComponent))
        } catch (e: SecurityException) {
            events?.success(mapOf("permissionGranted" to false))
        }
    }

    private fun stop() {
        if (sessionsListenerRegistered) {
            mediaSessionManager.removeOnActiveSessionsChangedListener(sessionsChangedListener)
            sessionsListenerRegistered = false
        }
        controllers.forEach { it.unregisterCallback(controllerCallback) }
        controllers = emptyList()
        currentController = null
    }

    private fun updateControllers(newControllers: List<MediaController>) {
        controllers.forEach { it.unregisterCallback(controllerCallback) }
        controllers = newControllers
        controllers.forEach { it.registerCallback(controllerCallback, handler) }
        selectController()
    }

    /**
     * Picks the playing session first, otherwise a paused one which still has something to show, unless another app
     * has been watched since it was paused.
     */
    private fun selectController() {
        currentController = controllers.firstOrNull { it.playbackState?.state in ACTIVE_STATES }
            ?: controllers.firstOrNull {
                it.metadata != null && it.playbackState?.state == PlaybackState.STATE_PAUSED && !isOutdated(it)
            }
        events?.success(mapOf("permissionGranted" to true, "session" to currentController?.let(::buildSessionMap)))
    }

    private fun isOutdated(controller: MediaController): Boolean {
        val state = controller.playbackState ?: return false
        if (state.lastPositionUpdateTime <= 0) {
            return false
        }
        val pausedAt = System.currentTimeMillis() - (SystemClock.elapsedRealtime() - state.lastPositionUpdateTime)
        return lastEngagements.any { (packageName, lastEngagement) ->
            packageName != controller.packageName && lastEngagement > pausedAt
        }
    }

    private fun buildSessionMap(controller: MediaController): Map<String, Any?> {
        val metadata = controller.metadata
        val state = controller.playbackState
        val artBitmap = metadata?.let {
            it.getBitmap(MediaMetadata.METADATA_KEY_ALBUM_ART)
                ?: it.getBitmap(MediaMetadata.METADATA_KEY_ART)
                ?: it.getBitmap(MediaMetadata.METADATA_KEY_DISPLAY_ICON)
        }
        val artUri = metadata?.let {
            it.getString(MediaMetadata.METADATA_KEY_ALBUM_ART_URI)
                ?: it.getString(MediaMetadata.METADATA_KEY_ART_URI)
                ?: it.getString(MediaMetadata.METADATA_KEY_DISPLAY_ICON_URI)
        }
        return mapOf(
            "packageName" to controller.packageName,
            "title" to (metadata?.getText(MediaMetadata.METADATA_KEY_TITLE)
                ?: metadata?.description?.title)?.toString(),
            "artist" to (metadata?.getText(MediaMetadata.METADATA_KEY_ARTIST)
                ?: metadata?.getText(MediaMetadata.METADATA_KEY_ALBUM_ARTIST)
                ?: metadata?.description?.subtitle)?.toString(),
            "album" to metadata?.getText(MediaMetadata.METADATA_KEY_ALBUM)?.toString(),
            "duration" to metadata?.getLong(MediaMetadata.METADATA_KEY_DURATION)?.takeIf { it > 0 },
            "art" to (artBitmap?.let(::bitmapToByteArray) ?: artUri?.let(::loadContentUri)),
            "artUri" to artUri?.takeIf { it.startsWith("http") },
            "playing" to (state?.state in ACTIVE_STATES),
            "position" to state?.position?.takeIf { it != PlaybackState.PLAYBACK_POSITION_UNKNOWN },
            "positionUpdatedAt" to state?.let {
                System.currentTimeMillis() - (SystemClock.elapsedRealtime() - it.lastPositionUpdateTime)
            },
            "speed" to state?.playbackSpeed?.toDouble(),
        )
    }

    private fun bitmapToByteArray(bitmap: Bitmap): ByteArray {
        if (bitmap !== lastArtBitmap) {
            val scale = ART_MAX_SIZE.toFloat() / maxOf(bitmap.width, bitmap.height)
            val scaled = if (scale < 1) {
                Bitmap.createScaledBitmap(bitmap, (bitmap.width * scale).toInt(), (bitmap.height * scale).toInt(), true)
            } else {
                bitmap
            }
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, 90, stream)
            lastArtBitmap = bitmap
            lastArtBytes = stream.toByteArray()
        }
        return lastArtBytes!!
    }

    private fun loadContentUri(uri: String): ByteArray? = try {
        Uri.parse(uri).takeIf { it.scheme == "content" || it.scheme == "android.resource" }
            ?.let(context.contentResolver::openInputStream)
            ?.use(BitmapFactory::decodeStream)
            ?.let(::bitmapToByteArray)
    } catch (e: Exception) {
        null
    }
}
