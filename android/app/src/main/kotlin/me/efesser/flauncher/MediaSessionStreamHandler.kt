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
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.media.MediaMetadata
import android.media.session.MediaController
import android.media.session.MediaSessionManager
import android.media.session.PlaybackState
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.KeyEvent
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import java.io.ByteArrayOutputStream
import java.util.WeakHashMap

private const val ART_MAX_SIZE = 512

/** How long after the launcher came back in front of an app it is checked whether that app still plays. */
private const val OBSERVATION_DELAY_MS = 3000L

/** Apps may pause as they leave the foreground, just before the launcher is resumed. */
private const val OBSERVATION_MARGIN_MS = 2000L

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

/**
 * Streams the media to show on the home screen to Flutter and forwards media keys to them.
 *
 * Reading other apps' media sessions requires notification access to be granted to [MediaNotificationListener]:
 * `adb shell cmd notification allow_listener me.efesser.flauncher/me.efesser.flauncher.MediaNotificationListener`
 */
class MediaSessionStreamHandler(
    private val context: Context,
    private val launchApp: (String) -> Boolean,
    /** Opens a "Continue watching" program of [WatchNextStreamHandler], returns false if it could not. */
    private val openProgram: (Map<String, Any?>) -> Boolean,
) : StreamHandler {
    private val mediaSessionManager = context.getSystemService(Context.MEDIA_SESSION_SERVICE) as MediaSessionManager
    private val listenerComponent = ComponentName(context, MediaNotificationListener::class.java)
    private val handler = Handler(Looper.getMainLooper())
    private var events: EventSink? = null
    private var sessionsListenerRegistered = false
    private var controllers: List<MediaController> = emptyList()
    // the artworks of the media shown, which are sent together
    private val artBytes = WeakHashMap<Bitmap, ByteArray>()
    // the "Continue watching" programs, null when they can't be read
    private var programs: List<Map<String, Any?>>? = null
    private var programsRead = false
    private var lastEngagements: Map<String, Long> = emptyMap()
    private val backgroundPlayback = BackgroundPlayback(context)
    private val foreground = Slot("foreground", background = false)
    private val background = Slot("background", background = true)
    private var playingPackages: Set<String> = emptySet()
    // when each app was last seen stopping to play, in SystemClock.elapsedRealtime()
    private val stoppedAt = HashMap<String, Long>()
    private var resumedAt: Long? = null
    private var mediaKeyAt = Long.MIN_VALUE
    private var playingPackage: String? = null
    private var shownPackages: List<String> = emptyList()
    private var focusedMedia: String? = null

    private val sessionsChangedListener = MediaSessionManager.OnActiveSessionsChangedListener {
        updateControllers(it ?: emptyList())
    }

    private val controllerCallback = object : MediaController.Callback() {
        override fun onPlaybackStateChanged(state: PlaybackState?) = selectController()
        override fun onMetadataChanged(metadata: MediaMetadata?) = selectController()
        override fun onSessionDestroyed() = selectController()
    }

    private val observeBackgroundPlayback = Runnable {
        val since = (resumedAt ?: return@Runnable) - OBSERVATION_MARGIN_MS
        // a media key may have paused the media meanwhile
        if (mediaKeyAt >= since) {
            return@Runnable
        }
        playingPackages.forEach { backgroundPlayback.observe(it, true) }
        stoppedAt.forEach { (packageName, at) ->
            if (at >= since && packageName !in playingPackages) {
                backgroundPlayback.observe(packageName, false)
            }
        }
        selectController()
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
     * The app which was in front stops playing, or releases its session, as the launcher comes back in front of it when
     * it doesn't play in the background, and keeps playing otherwise: it is checked a moment later.
     */
    fun onLauncherResumed() {
        resumedAt = SystemClock.elapsedRealtime()
        handler.removeCallbacks(observeBackgroundPlayback)
        handler.postDelayed(observeBackgroundPlayback, OBSERVATION_DELAY_MS)
    }

    /**
     * An app opened from the launcher before the check takes the audio focus from the one playing in the background,
     * which must not be taken for an app stopping as it leaves the foreground.
     */
    fun onLauncherPaused() {
        handler.removeCallbacks(observeBackgroundPlayback)
        resumedAt = null
    }

    /**
     * The "Continue watching" programs tell which video can still be opened once its session is gone, as the intent of
     * its session doesn't survive a restart of the device. Some apps don't publish a media session while they play
     * (e.g. arte) either, which would leave an older paused video offered while another app has been watched since: the
     * last time a program of each app was watched tells it.
     */
    fun updateWatchNextPrograms(programs: List<Map<String, Any?>>?) {
        this.programs = programs
        programsRead = true
        lastEngagements = (programs ?: emptyList())
            .groupBy { it["packageName"] as String? }
            .mapNotNull { (packageName, programs) ->
                val lastEngagement = programs.mapNotNull { it["lastEngagementTime"] as Long? }.maxOrNull()
                if (packageName != null && lastEngagement != null) packageName to lastEngagement else null
            }
            .toMap()
        selectController()
    }

    /** [packageName] is the app of the media focused on the home screen, if any. */
    fun setFocusedMedia(packageName: String?) {
        focusedMedia = packageName
    }

    /**
     * Forwards media keys to the media focused on the home screen, otherwise to the media playing or to the only one
     * offered, as the system would otherwise send them to its own pick (the last session which received one). They are
     * ignored when several media are offered and none is focused.
     *
     * Videos must not play behind the launcher though: for an app which doesn't play in the background, or whose session
     * is gone, play keys open the app instead and other keys are ignored.
     */
    fun dispatchMediaKey(event: KeyEvent): Boolean {
        if (event.keyCode !in MEDIA_KEYS) {
            return false
        }
        mediaKeyAt = SystemClock.elapsedRealtime()
        val packageName = focusedMedia ?: playingPackage ?: shownPackages.singleOrNull()
            ?: return shownPackages.isNotEmpty()
        val controller = liveController(packageName)
        if (controller != null && backgroundPlayback.canPlayInBackground(packageName)) {
            return controller.dispatchMediaButtonEvent(event)
        }
        if (isPlayPress(event)) {
            openPlayer(packageName)
        }
        return true
    }

    private fun isPlayPress(event: KeyEvent) =
        event.keyCode in PLAY_KEYS && event.action == KeyEvent.ACTION_DOWN && event.repeatCount == 0

    /**
     * Opens the player of the session of [packageName]. Once it is gone, the video opens its "Continue watching"
     * program, otherwise the app is opened.
     */
    fun openPlayer(packageName: String): Boolean {
        if (liveController(packageName) == null && foreground.program(packageName)?.let(openProgram) == true) {
            return true
        }
        val controller = controllers.firstOrNull { it.packageName == packageName }
        return try {
            controller?.sessionActivity?.send() != null
        } catch (e: PendingIntent.CanceledException) {
            false
        } || launchApp(packageName)
    }

    /** Resumes the paused media of [packageName] without leaving the launcher, or opens the app if its session is gone. */
    fun playMedia(packageName: String): Boolean {
        val controller = liveController(packageName) ?: return launchApp(packageName)
        controller.transportControls.play()
        return true
    }

    /** A destroyed session still gives its metadata until it is removed, but no playback state. */
    private fun liveController(packageName: String) = controllers.firstOrNull {
        it.packageName == packageName && it.metadata != null && it.playbackState != null
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
        handler.removeCallbacks(observeBackgroundPlayback)
        if (sessionsListenerRegistered) {
            mediaSessionManager.removeOnActiveSessionsChangedListener(sessionsChangedListener)
            sessionsListenerRegistered = false
        }
        controllers.forEach { it.unregisterCallback(controllerCallback) }
        controllers = emptyList()
    }

    private fun updateControllers(newControllers: List<MediaController>) {
        controllers.forEach { it.unregisterCallback(controllerCallback) }
        controllers = newControllers
        controllers.forEach { it.registerCallback(controllerCallback, handler) }
        selectController()
    }

    /**
     * Sends the media playing alone. Otherwise, the last media of an app which doesn't play in the background, a video,
     * is offered to be resumed next to the last one of an app which does.
     */
    private fun selectController() {
        val stopped = trackPlaying()
        val foregroundMedia = foreground.select(stopped)
        val backgroundMedia = background.select(stopped)
        val playing = controllers.firstOrNull(::isPlaying)
        val medias = if (playing != null) {
            listOf(buildSessionMap(playing))
        } else {
            listOfNotNull(foregroundMedia, backgroundMedia)
        }
        playingPackage = playing?.packageName
        shownPackages = medias.map { it["packageName"] as String }
        events?.success(mapOf(
            "permissionGranted" to true,
            "medias" to medias,
        ))
    }

    /** Remembers when each app stopped playing, and returns the ones which just did. */
    private fun trackPlaying(): Set<String> {
        val playing = controllers.filter(::isPlaying).map { it.packageName }.toSet()
        val stopped = playingPackages - playing
        val now = SystemClock.elapsedRealtime()
        stopped.forEach { stoppedAt[it] = now }
        playingPackages = playing
        return stopped
    }

    /**
     * The last media of the apps which play in the background, or of those which don't, is the last one seen playing, or
     * a paused one until then. Once its session is gone, it is kept where it was left. A video is given up once another
     * app is watched without session, and once its session is gone unless a "Continue watching" program opens it: a
     * live stream, without duration, is never resumed.
     */
    private inner class Slot(name: String, private val background: Boolean) {
        private val lastMedia = LastMedia(context, name, background)
        // the media of its session, while it is there
        private var session: Map<String, Any?>? = null

        fun select(stopped: Set<String>): Map<String, Any?>? {
            val rememberedPackage = lastMedia.media?.get("packageName") as String?
            if (rememberedPackage != null && (backgroundPlayback.canPlayInBackground(rememberedPackage) != background ||
                    !background && (isOutdated(rememberedPackage, lastMedia.seenAt) || !isReplayable(lastMedia.media!!)))
            ) {
                lastMedia.forget()
                session = null
            }
            val remembered = lastMedia.media?.get("packageName") as String?
            val candidates = controllers.filter { backgroundPlayback.canPlayInBackground(it.packageName) == background }
            val controller = candidates.firstOrNull(::isPlaying)
                ?: candidates.firstOrNull { isShowable(it) && it.packageName == remembered }
                ?: candidates.takeIf { remembered == null }
                    ?.firstOrNull { isShowable(it) && (background || !isOutdated(it)) }
            val session = controller?.let(::buildSessionMap)
            val media = session ?: this.session ?: return lastMedia.media?.takeIf { background || programsRead }
            val packageName = media["packageName"] as String
            val seenAt = when {
                packageName in playingPackages || packageName in stopped -> System.currentTimeMillis()
                packageName == remembered -> lastMedia.seenAt
                else -> controller?.let(::pausedAt) ?: System.currentTimeMillis()
            }
            // once its session is gone, the media is remembered where it was left
            lastMedia.remember(media, currentPosition(media), seenAt)
            this.session = session
            // a video without session waits for its program rather than showing up and going right away
            return session ?: lastMedia.media?.takeIf { background || programsRead }
        }

        /** The "Continue watching" program of the media of [packageName], if it is the one remembered. */
        fun program(packageName: String) =
            lastMedia.media?.takeIf { it["packageName"] == packageName }?.let(::programOf)

        /** Whether the session of the video is there, or it still can be opened from its program, as far as is known. */
        private fun isReplayable(media: Map<String, Any?>) = liveController(media["packageName"] as String) != null ||
            !programsRead || programs == null || media["duration"] != null && programOf(media) != null
    }

    /** The "Continue watching" program of [media]: the session of some apps gives its title as subtitle. */
    private fun programOf(media: Map<String, Any?>): Map<String, Any?>? {
        val titles = listOfNotNull(media["title"] as String?, media["artist"] as String?).map(::normalizeTitle)
            .filter { it.isNotEmpty() }
        return programs?.firstOrNull { program ->
            program["packageName"] == media["packageName"] && program["intentUri"] != null &&
                listOfNotNull(program["title"] as String?, program["episodeTitle"] as String?)
                    .any { normalizeTitle(it) in titles }
        }
    }

    private fun normalizeTitle(title: String) =
        title.replace("’", "'").replace(Regex("\\s+"), " ").trim().lowercase()

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

    /** Whether another app which doesn't play in the background has been watched since [seenAt]. */
    private fun isOutdated(packageName: String, seenAt: Long) = lastEngagements.any { (otherPackageName, lastTime) ->
        otherPackageName != packageName && lastTime > seenAt &&
            !backgroundPlayback.canPlayInBackground(otherPackageName)
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
            "background" to backgroundPlayback.canPlayInBackground(controller.packageName),
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
