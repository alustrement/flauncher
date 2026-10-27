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
import android.content.Intent

private const val PREFERENCES_NAME = "background_playback"

/** The services an app declares to be controlled without its activity, e.g. by Android Auto or a Media3 controller. */
private val MEDIA_SERVICE_ACTIONS = listOf(
    "android.media.browse.MediaBrowserService",
    "androidx.media3.session.MediaSessionService",
    "androidx.media3.session.MediaLibraryService",
)

/**
 * Tells whether an app keeps playing once it leaves the foreground, which Android doesn't say: what has been seen when
 * the launcher came back in front of it comes first, as it can be an option of the app (e.g. SmartTube), then whether
 * it declares a media service.
 */
class BackgroundPlayback(private val context: Context) {
    private val preferences = context.getSharedPreferences(PREFERENCES_NAME, Context.MODE_PRIVATE)
    private val declared = HashMap<String, Boolean>()

    fun canPlayInBackground(packageName: String): Boolean =
        if (preferences.contains(packageName)) {
            preferences.getBoolean(packageName, false)
        } else {
            declared.getOrPut(packageName) { declaresMediaService(packageName) }
        }

    /** [packageName] has been seen playing, or stopping, as it left the foreground. */
    fun observe(packageName: String, playsInBackground: Boolean) {
        if (!preferences.contains(packageName) || preferences.getBoolean(packageName, false) != playsInBackground) {
            preferences.edit().putBoolean(packageName, playsInBackground).apply()
        }
    }

    private fun declaresMediaService(packageName: String) = MEDIA_SERVICE_ACTIONS.any {
        context.packageManager.queryIntentServices(Intent(it).setPackage(packageName), 0).isNotEmpty()
    }
}
