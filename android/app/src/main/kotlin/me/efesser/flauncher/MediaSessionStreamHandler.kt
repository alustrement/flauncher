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
import java.util.WeakHashMap

const val SPOTIFY_PACKAGE = "com.spotify.tv.android"

private const val ART_MAX_SIZE = 512
private const val LAST_PLAYED_PREFERENCES_NAME = "last_played"

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
    // the artworks of the media and of Spotify's, which are sent together
    private val artBytes = WeakHashMap<Bitmap, ByteArray>()
    private var lastEngagements: Map<String, Long> = emptyMap()
    private val lastPlayedPreferences = context.getSharedPreferences(LAST_PLAYED_PREFERENCES_NAME, Context.MODE_PRIVATE)
    private val lastPlayed: MutableMap<String, Long> =
        lastPlayedPreferences.all.mapNotNull { (packageName, time) -> (time as? Long)?.let { packageName to it } }
            .toMap(HashMap())
    private var playingPackages: Set<String> = emptySet()
    private var currentSession: Map<String, Any?>? = null
    private var goneSession: Map<String, Any?>? = null
    private var goneAt = 0L
    private var spotifyAside = false
    private var focusedMedia: String? = null

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

    /** [packageName] is the app of the media focused on the home screen, if any. */
    fun setFocusedMedia(packageName: String?) {
        focusedMedia = packageName
    }

    /**
     * Forwards media keys to the session shown on the home screen, as the system would otherwise send them to its
     * own pick (the last session which received one).
     *
     * Videos must not play behind the launcher though: for anything that isn't known to be audio, play keys open the
     * app instead and other keys are ignored.
     *
     * When the media of a session which is gone is shown instead, play keys open its app.
     *
     * When Spotify's paused media is shown next to a video, media keys go to the one focused, and are ignored when
     * neither is.
     */
    fun dispatchMediaKey(event: KeyEvent): Boolean {
        if (event.keyCode !in MEDIA_KEYS) {
            return false
        }
        if (spotifyAside) {
            when (focusedMedia) {
                null -> return true
                SPOTIFY_PACKAGE -> {
                    spotifyController()?.dispatchMediaButtonEvent(event)
                    return true
                }
            }
        }
        val controller = currentController
        val gone = goneSession
        if (controller == null && gone != null) {
            if (event.keyCode in PLAY_KEYS && event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0) {
                launchApp(gone["packageName"] as String)
            }
            return true
        }
        if (controller == null) {
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

    /** Resumes Spotify's paused media in Spotify, or opens Spotify when it has none. */
    fun resumeSpotify(): Boolean {
        val controller = spotifyController() ?: return launchApp(SPOTIFY_PACKAGE)
        controller.transportControls.play()
        return try {
            controller.sessionActivity?.send() != null
        } catch (e: PendingIntent.CanceledException) {
            false
        } || launchApp(SPOTIFY_PACKAGE)
    }

    private fun spotifyController() =
        controllers.firstOrNull { it.packageName == SPOTIFY_PACKAGE && it.metadata != null }

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
     * has been watched or played since it was paused.
     *
     * Some apps release their session as soon as they leave the foreground (e.g. SmartTube): the media of the session
     * shown is then kept, paused, until another media is paused or another app is watched or played.
     *
     * Next to a paused media of another app, a video which doesn't play in the background, Spotify's paused media is
     * sent too, to be resumed.
     */
    private fun selectController() {
        rememberPlayed()
        rememberGoneSession()
        val controller = controllers.firstOrNull(::isPlaying)
            ?: controllers.firstOrNull {
                isShowable(it) && !isOutdated(it) && (goneSession == null || (pausedAt(it) ?: 0) > goneAt)
            }
        if (controller != null || goneSession?.let { isOutdated(it["packageName"] as String, goneAt) } == true) {
            goneSession = null
        }
        currentController = controller
        val session = controller?.let(::buildSessionMap) ?: goneSession
        currentSession = session
        val resumable = session != null && session["playing"] != true && session["packageName"] != SPOTIFY_PACKAGE
        val spotify = if (resumable) spotifyController() else null
        spotifyAside = spotify != null
        events?.success(mapOf(
            "permissionGranted" to true,
            "session" to session,
            "spotify" to spotify?.let(::buildSessionMap),
        ))
    }

    /**
     * Some apps release their session as soon as they leave the foreground (e.g. SmartTube), which would bring back
     * an older paused session: the time each app was last seen playing is remembered, when it starts and stops, and
     * kept across restarts of the launcher.
     */
    private fun rememberPlayed() {
        val playing = controllers.filter(::isPlaying).map { it.packageName }.toSet()
        val changed = (playing - playingPackages) + (playingPackages - playing)
        playingPackages = playing
        if (changed.isEmpty()) {
            return
        }
        val now = System.currentTimeMillis()
        val editor = lastPlayedPreferences.edit()
        for (packageName in changed) {
            lastPlayed[packageName] = now
            editor.putLong(packageName, now)
        }
        editor.apply()
    }

    /** Keeps the media shown, paused, when its app has no session to show anymore. Spotify's is resumed instead. */
    private fun rememberGoneSession() {
        val session = currentSession ?: return
        val packageName = session["packageName"] as String
        if (packageName == SPOTIFY_PACKAGE || session === goneSession ||
            controllers.any { it.packageName == packageName && (isPlaying(it) || isShowable(it)) }
        ) {
            return
        }
        goneSession = session + mapOf("playing" to false, "position" to currentPosition(session))
        goneAt = System.currentTimeMillis()
    }

    private fun isPlaying(controller: MediaController) = controller.playbackState?.state in ACTIVE_STATES

    private fun isShowable(controller: MediaController) =
        controller.metadata != null && controller.playbackState?.state == PlaybackState.STATE_PAUSED

    private fun pausedAt(controller: MediaController): Long? {
        val state = controller.playbackState ?: return null
        if (state.lastPositionUpdateTime <= 0) {
            return null
        }
        return System.currentTimeMillis() - (SystemClock.elapsedRealtime() - state.lastPositionUpdateTime)
    }

    private fun isOutdated(controller: MediaController): Boolean {
        val pausedAt = pausedAt(controller) ?: return false
        return isOutdated(controller.packageName, pausedAt)
    }

    /** Whether another app has been watched or played since [pausedAt]. */
    private fun isOutdated(packageName: String, pausedAt: Long) =
        (lastEngagements.entries + lastPlayed.entries).any { (otherPackageName, lastTime) ->
            otherPackageName != packageName && lastTime > pausedAt
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

    /** Extrapolates the playback position of a session map from the last reported one. */
    private fun currentPosition(session: Map<String, Any?>): Long? {
        val position = session["position"] as Long? ?: return null
        val updatedAt = session["positionUpdatedAt"] as Long?
        if (session["playing"] != true || updatedAt == null) {
            return position
        }
        val speed = session["speed"] as Double? ?: 1.0
        val current = position + ((System.currentTimeMillis() - updatedAt) * speed).toLong()
        val duration = session["duration"] as Long?
        return if (duration != null) minOf(current, duration) else current
    }

    private fun bitmapToByteArray(bitmap: Bitmap): ByteArray = artBytes.getOrPut(bitmap) {
        val scale = ART_MAX_SIZE.toFloat() / maxOf(bitmap.width, bitmap.height)
        val scaled = if (scale < 1) {
            Bitmap.createScaledBitmap(bitmap, (bitmap.width * scale).toInt(), (bitmap.height * scale).toInt(), true)
        } else {
            bitmap
        }
        val stream = ByteArrayOutputStream()
        scaled.compress(Bitmap.CompressFormat.JPEG, 90, stream)
        stream.toByteArray()
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
