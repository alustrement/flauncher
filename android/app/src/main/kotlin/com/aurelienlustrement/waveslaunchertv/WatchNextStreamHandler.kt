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

import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.ContentObserver
import android.database.Cursor
import android.media.tv.TvContract.WatchNextPrograms
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import java.net.URISyntaxException
import java.util.concurrent.Executors

// hidden from the public SDK
const val READ_TV_LISTINGS = "android.permission.READ_TV_LISTINGS"
private const val REFRESH_DELAY_MILLIS = 500L

private val PROJECTION = arrayOf(
    WatchNextPrograms._ID,
    WatchNextPrograms.COLUMN_PACKAGE_NAME,
    WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE,
    WatchNextPrograms.COLUMN_TITLE,
    WatchNextPrograms.COLUMN_EPISODE_TITLE,
    WatchNextPrograms.COLUMN_SEASON_DISPLAY_NUMBER,
    WatchNextPrograms.COLUMN_EPISODE_DISPLAY_NUMBER,
    WatchNextPrograms.COLUMN_POSTER_ART_URI,
    WatchNextPrograms.COLUMN_THUMBNAIL_URI,
    WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS,
    WatchNextPrograms.COLUMN_DURATION_MILLIS,
    WatchNextPrograms.COLUMN_INTENT_URI,
    WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS,
    WatchNextPrograms.COLUMN_BROWSABLE,
)

/**
 * Streams the "Play Next" programs that apps publish to the TV provider (the "Continue watching" row of the stock
 * launcher), most recently engaged first.
 *
 * Other apps' programs are only readable with the [READ_TV_LISTINGS] runtime permission.
 */
class WatchNextStreamHandler(
    private val context: Context,
    /** Called with the programs each time they are read, or with null when they can't be. */
    private val onPrograms: (List<Map<String, Any?>>?) -> Unit,
) : StreamHandler {
    private val handler = Handler(Looper.getMainLooper())
    private val executor = Executors.newSingleThreadExecutor()
    private var events: EventSink? = null
    private val refreshRunnable = Runnable { refresh() }

    private val observer = object : ContentObserver(handler) {
        override fun onChange(selfChange: Boolean) {
            // apps tend to update several programs at once
            handler.removeCallbacks(refreshRunnable)
            handler.postDelayed(refreshRunnable, REFRESH_DELAY_MILLIS)
        }
    }

    override fun onListen(arguments: Any?, events: EventSink) {
        this.events = events
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            onPrograms(null)
            events.success(mapOf("permissionGranted" to true, "programs" to emptyList<Any>()))
            return
        }
        try {
            context.contentResolver.registerContentObserver(WatchNextPrograms.CONTENT_URI, true, observer)
        } catch (e: SecurityException) {
            // refreshed on resume instead
        }
        refresh()
    }

    override fun onCancel(arguments: Any?) {
        context.contentResolver.unregisterContentObserver(observer)
        handler.removeCallbacks(refreshRunnable)
        events = null
    }

    fun dispose() {
        onCancel(null)
        executor.shutdown()
    }

    fun hasPermission() = Build.VERSION.SDK_INT < Build.VERSION_CODES.M ||
        context.checkSelfPermission(READ_TV_LISTINGS) == PackageManager.PERMISSION_GRANTED

    fun refresh() {
        if (events == null || Build.VERSION.SDK_INT < Build.VERSION_CODES.O) {
            return
        }
        if (!hasPermission()) {
            onPrograms(null)
            events?.success(mapOf("permissionGranted" to false))
            return
        }
        executor.execute {
            val programs = try {
                queryPrograms()
            } catch (e: Exception) {
                null
            }
            handler.post {
                onPrograms(programs)
                events?.success(mapOf("permissionGranted" to true, "programs" to (programs ?: emptyList())))
            }
        }
    }

    /** Opens the program in its app, returns false if its intent could not be resolved. */
    fun open(intentUri: String?, packageName: String): Boolean {
        val intent = try {
            intentUri?.let { Intent.parseUri(it, Intent.URI_INTENT_SCHEME) }
        } catch (e: URISyntaxException) {
            null
        } ?: return false
        intent.selector = null
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        // web links must open in the app which published them, not in a browser
        if (intent.component == null) {
            intent.setPackage(packageName)
        }
        return try {
            context.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        } catch (e: SecurityException) {
            false
        }
    }

    private fun queryPrograms(): List<Map<String, Any?>> {
        // the TV provider rejects selections from apps which don't have full access, hence filtering here
        val programs = context.contentResolver.query(WatchNextPrograms.CONTENT_URI, PROJECTION, null, null, null)
            ?.use { cursor -> generateSequence { if (cursor.moveToNext()) buildProgramMap(cursor) else null }.toList() }
            ?: emptyList()
        return programs
            .filter { it["browsable"] != 0L }
            .sortedByDescending { it["lastEngagementTime"] as Long? ?: 0L }
            .map { it - "browsable" }
    }

    private fun buildProgramMap(cursor: Cursor): Map<String, Any?> {
        fun string(column: String) = cursor.getColumnIndex(column).takeIf { it >= 0 && !cursor.isNull(it) }
            ?.let(cursor::getString)
            ?.takeIf { it.isNotBlank() }

        fun long(column: String) = cursor.getColumnIndex(column).takeIf { it >= 0 && !cursor.isNull(it) }
            ?.let(cursor::getLong)

        val imageUri = string(WatchNextPrograms.COLUMN_POSTER_ART_URI)
            ?: string(WatchNextPrograms.COLUMN_THUMBNAIL_URI)
        return mapOf(
            "id" to long(WatchNextPrograms._ID),
            "packageName" to string(WatchNextPrograms.COLUMN_PACKAGE_NAME),
            "watchNextType" to long(WatchNextPrograms.COLUMN_WATCH_NEXT_TYPE),
            "title" to string(WatchNextPrograms.COLUMN_TITLE),
            "episodeTitle" to string(WatchNextPrograms.COLUMN_EPISODE_TITLE),
            "seasonNumber" to string(WatchNextPrograms.COLUMN_SEASON_DISPLAY_NUMBER),
            "episodeNumber" to string(WatchNextPrograms.COLUMN_EPISODE_DISPLAY_NUMBER),
            "imageUri" to imageUri?.takeIf { it.startsWith("http") },
            "image" to imageUri?.takeUnless { it.startsWith("http") }?.let(::loadLocalUri),
            "position" to long(WatchNextPrograms.COLUMN_LAST_PLAYBACK_POSITION_MILLIS)?.takeIf { it > 0 },
            "duration" to long(WatchNextPrograms.COLUMN_DURATION_MILLIS)?.takeIf { it > 0 },
            "intentUri" to string(WatchNextPrograms.COLUMN_INTENT_URI),
            "lastEngagementTime" to long(WatchNextPrograms.COLUMN_LAST_ENGAGEMENT_TIME_UTC_MILLIS),
            "browsable" to long(WatchNextPrograms.COLUMN_BROWSABLE),
        )
    }

    private fun loadLocalUri(uri: String): ByteArray? = try {
        context.contentResolver.openInputStream(Uri.parse(uri))?.use { it.readBytes() }
    } catch (e: Exception) {
        null
    }
}
