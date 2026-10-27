/*
 * Waves Launcher TV
 * Copyright (C) 2026  Aurélien Lustrement
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

package com.aurelienlustrement.waveslaunchertv

import android.content.Context
import java.io.File

/**
 * Remembers the last media of the apps which play in the background, or of those which don't, paused where it was left,
 * so that it is still offered to be resumed once its session is gone (e.g. SmartTube releases it as soon as it leaves
 * the foreground, Android kills Spotify while it doesn't play), and after a restart.
 *
 * [name] tells one from the other in the storage.
 */
class LastMedia(context: Context, name: String, private val background: Boolean) {
    private val preferences = context.getSharedPreferences("last_${name}_media", Context.MODE_PRIVATE)
    private val artFile = File(context.filesDir, "last_${name}_art")
    private var savedArt: ByteArray? = null
    private var loaded = false

    /** The media as a session map of [MediaSessionStreamHandler], paused. */
    var media: Map<String, Any?>? = null
        get() {
            load()
            return field
        }
        private set

    /** The last time the media was seen playing, in milliseconds since the epoch. */
    var seenAt = 0L
        get() {
            load()
            return field
        }
        private set

    /** [session] is the session map of the media, which was at [position] when it was last seen at [seenAt]. */
    fun remember(session: Map<String, Any?>, position: Long?, seenAt: Long) {
        val art = session["art"] as ByteArray?
        val media = mediaMap(session["packageName"] as String, session["title"] as String?,
            session["artist"] as String?, session["album"] as String?, session["duration"] as Long?, position, art)
        if (media == this.media && seenAt == this.seenAt) {
            return
        }
        if (art !== savedArt) {
            try {
                if (art != null) artFile.writeBytes(art) else artFile.delete()
                savedArt = art
            } catch (e: Exception) {
                // the media is still remembered, without its artwork
            }
        }
        preferences.edit()
            .putString("packageName", media["packageName"] as String)
            .putString("title", media["title"] as String?)
            .putString("artist", media["artist"] as String?)
            .putString("album", media["album"] as String?)
            .putLong("duration", media["duration"] as Long? ?: -1)
            .putLong("position", position ?: -1)
            .putLong("seenAt", seenAt)
            .apply()
        this.media = media
        this.seenAt = seenAt
    }

    fun forget() {
        if (media == null) {
            return
        }
        preferences.edit().clear().apply()
        artFile.delete()
        savedArt = null
        media = null
        seenAt = 0
    }

    private fun load() {
        if (loaded) {
            return
        }
        loaded = true
        val packageName = preferences.getString("packageName", null) ?: return
        savedArt = try {
            artFile.takeIf { it.exists() }?.readBytes()
        } catch (e: Exception) {
            null
        }
        media = mediaMap(
            packageName,
            preferences.getString("title", null),
            preferences.getString("artist", null),
            preferences.getString("album", null),
            preferences.getLong("duration", -1).takeIf { it > 0 },
            preferences.getLong("position", -1).takeIf { it >= 0 },
            savedArt,
        )
        seenAt = preferences.getLong("seenAt", 0)
    }

    private fun mediaMap(packageName: String, title: String?, artist: String?, album: String?, duration: Long?,
                         position: Long?, art: ByteArray?) = mapOf(
        "packageName" to packageName,
        "title" to title,
        "artist" to artist,
        "album" to album,
        "duration" to duration,
        "art" to art,
        "playing" to false,
        "position" to position,
        "background" to background,
    )
}
