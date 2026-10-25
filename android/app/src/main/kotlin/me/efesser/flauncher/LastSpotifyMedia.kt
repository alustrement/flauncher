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

import android.content.Context
import java.io.File

const val SPOTIFY_PACKAGE = "com.spotify.tv.android"

private const val PREFERENCES_NAME = "last_spotify_media"
private const val ART_FILE_NAME = "last_spotify_art"

/**
 * Remembers the last media played on Spotify, so that the home screen can offer to resume it once nothing plays,
 * even after Spotify's session is gone (e.g. its app has been killed).
 */
class LastSpotifyMedia(context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    private val artFile = File(context.filesDir, ART_FILE_NAME)
    private var savedArt: ByteArray? = null
    private var loaded = false

    /** The media as a session map of [MediaSessionStreamHandler], paused where it was left. */
    var media: Map<String, Any?>? = null
        get() {
            if (!loaded) {
                field = load()
                loaded = true
            }
            return field
        }
        private set

    /** The Spotify URI of the media, e.g. "spotify:episode:2m17SbmBsSviQ23OztlWNW", when Spotify gave one. */
    val mediaId: String?
        get() = preferences.getString("mediaId", null)

    /** [session] is the session map of Spotify's playing or paused media. */
    fun remember(session: Map<String, Any?>, mediaId: String?) {
        val position = currentPosition(session)
        val art = session["art"] as ByteArray?
        if (art !== savedArt) {
            try {
                if (art != null) artFile.writeBytes(art) else artFile.delete()
                savedArt = art
            } catch (e: Exception) {
                // the media is still remembered, without its artwork
            }
        }
        preferences.edit()
            .putString("title", session["title"] as String?)
            .putString("artist", session["artist"] as String?)
            .putString("album", session["album"] as String?)
            .putLong("duration", session["duration"] as Long? ?: -1)
            .putLong("position", position ?: -1)
            .putString("mediaId", mediaId)
            .apply()
        media = mediaMap(session["title"] as String?, session["artist"] as String?, session["album"] as String?,
            session["duration"] as Long?, position, art)
        loaded = true
    }

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

    private fun load(): Map<String, Any?>? {
        if (!preferences.contains("title")) {
            return null
        }
        savedArt = try {
            artFile.takeIf { it.exists() }?.readBytes()
        } catch (e: Exception) {
            null
        }
        return mediaMap(
            preferences.getString("title", null),
            preferences.getString("artist", null),
            preferences.getString("album", null),
            preferences.getLong("duration", -1).takeIf { it > 0 },
            preferences.getLong("position", -1).takeIf { it >= 0 },
            savedArt,
        )
    }

    private fun mediaMap(title: String?, artist: String?, album: String?, duration: Long?, position: Long?,
                         art: ByteArray?) = mapOf(
        "packageName" to SPOTIFY_PACKAGE,
        "title" to title,
        "artist" to artist,
        "album" to album,
        "duration" to duration,
        "art" to art,
        "playing" to false,
        "position" to position,
    )
}
