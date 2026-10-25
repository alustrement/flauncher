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

import android.content.Intent
import android.content.Intent.*
import android.content.pm.*
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.drawable.Drawable
import android.net.Uri
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.os.UserHandle
import android.provider.Settings
import android.view.KeyEvent
import androidx.annotation.NonNull
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.EventChannel.EventSink
import io.flutter.plugin.common.EventChannel.StreamHandler
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.Serializable

private const val METHOD_CHANNEL = "me.efesser.flauncher/method"
private const val EVENT_CHANNEL = "me.efesser.flauncher/event"
private const val MEDIA_EVENT_CHANNEL = "me.efesser.flauncher/media"
private const val WATCH_NEXT_EVENT_CHANNEL = "me.efesser.flauncher/watch_next"
private const val WATCH_NEXT_PERMISSION_REQUEST_CODE = 1
private const val DOUBLE_HOME_PRESS_TIMEOUT_MS = 400L

class MainActivity : FlutterActivity() {
    val launcherAppsCallbacks = ArrayList<LauncherApps.Callback>()
    private lateinit var mediaSessionStreamHandler: MediaSessionStreamHandler
    private lateinit var watchNextStreamHandler: WatchNextStreamHandler
    private lateinit var methodChannel: MethodChannel
    private var lastHomePressTime = 0L
    private val handler = Handler(Looper.getMainLooper())
    private val backToTopInLauncher = Runnable { backToTop(animated = true) }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                "getApplications" -> result.success(getApplications())
                "applicationExists" -> result.success(applicationExists(call.arguments as String))
                "launchApp" -> result.success(launchApp(call.arguments as String))
                "openSettings" -> result.success(openSettings())
                "openAppInfo" -> result.success(openAppInfo(call.arguments as String))
                "uninstallApp" -> result.success(uninstallApp(call.arguments as String))
                "isDefaultLauncher" -> result.success(isDefaultLauncher())
                "startAmbientMode" -> result.success(startAmbientMode())
                "openMediaSession" -> result.success(
                    mediaSessionStreamHandler.openPlayer() || launchApp(call.arguments as String))
                "resumeSpotify" -> result.success(mediaSessionStreamHandler.resumeSpotify())
                "requestWatchNextPermission" -> result.success(requestWatchNextPermission())
                "openWatchNextProgram" -> {
                    val packageName = call.argument<String>("packageName")!!
                    result.success(
                        watchNextStreamHandler.open(call.argument("intentUri"), packageName) || launchApp(packageName))
                }
                else -> throw IllegalArgumentException()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : StreamHandler {
            lateinit var launcherAppsCallback: LauncherApps.Callback
            val launcherApps = getSystemService(LAUNCHER_APPS_SERVICE) as LauncherApps
            override fun onListen(arguments: Any?, events: EventSink) {
                launcherAppsCallback = object : LauncherApps.Callback() {
                    override fun onPackageRemoved(packageName: String, user: UserHandle) {
                        events.success(mapOf("action" to "PACKAGE_REMOVED", "packageName" to packageName))
                    }

                    override fun onPackageAdded(packageName: String, user: UserHandle) {
                        getApplication(packageName)
                            ?.let { events.success(mapOf("action" to "PACKAGE_ADDED", "activitiyInfo" to it)) }
                    }

                    override fun onPackageChanged(packageName: String, user: UserHandle) {
                        getApplication(packageName)
                            ?.let { events.success(mapOf("action" to "PACKAGE_CHANGED", "activitiyInfo" to it)) }
                    }

                    override fun onPackagesAvailable(packageNames: Array<out String>, user: UserHandle, replacing: Boolean) {
                        val applications = packageNames.map(::getApplication)
                        if (applications.isNotEmpty()) {
                            events.success(mapOf("action" to "PACKAGES_AVAILABLE", "activitiesInfo" to applications))
                        }
                    }

                    override fun onPackagesUnavailable(packageNames: Array<out String>, user: UserHandle, replacing: Boolean) {}
                }

                launcherAppsCallbacks.add(launcherAppsCallback)
                launcherApps.registerCallback(launcherAppsCallback)
            }

            override fun onCancel(arguments: Any?) {
                launcherApps.unregisterCallback(launcherAppsCallback)
                launcherAppsCallbacks.remove(launcherAppsCallback)
            }
        })

        mediaSessionStreamHandler = MediaSessionStreamHandler(this, ::launchApp)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, MEDIA_EVENT_CHANNEL)
            .setStreamHandler(mediaSessionStreamHandler)

        watchNextStreamHandler = WatchNextStreamHandler(this, mediaSessionStreamHandler::updateLastEngagements)
        EventChannel(flutterEngine.dartExecutor.binaryMessenger, WATCH_NEXT_EVENT_CHANNEL)
            .setStreamHandler(watchNextStreamHandler)
    }

    override fun dispatchKeyEvent(event: KeyEvent): Boolean {
        if (::mediaSessionStreamHandler.isInitialized && mediaSessionStreamHandler.dispatchMediaKey(event)) {
            return true
        }
        return super.dispatchKeyEvent(event)
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        // every press on Home brings the launcher back with a new intent, wherever it is pressed; the launcher
        // already displayed has the window focus, unlike when it comes back from another app
        if (intent.action == ACTION_MAIN && intent.hasCategory(CATEGORY_HOME)) {
            onHomePressed(hasWindowFocus())
        }
    }

    /**
     * Like the default launcher does, pressing Home twice shows the recent apps when the service is enabled, and
     * pressing it once brings the launcher back to the top of its page: right away when it comes back from another
     * app, smoothly when it is already displayed.
     */
    private fun onHomePressed(inLauncher: Boolean) {
        val now = SystemClock.uptimeMillis()
        if (now - lastHomePressTime <= DOUBLE_HOME_PRESS_TIMEOUT_MS && RecentsAccessibilityService.showRecents()) {
            handler.removeCallbacks(backToTopInLauncher)
            lastHomePressTime = 0
            return
        }
        lastHomePressTime = now
        if (!::methodChannel.isInitialized) {
            return
        }
        handler.removeCallbacks(backToTopInLauncher)
        if (!inLauncher) {
            backToTop(animated = false)
        } else if (RecentsAccessibilityService.enabled) {
            // waits to know whether Home is pressed twice
            handler.postDelayed(backToTopInLauncher, DOUBLE_HOME_PRESS_TIMEOUT_MS)
        } else {
            backToTop(animated = true)
        }
    }

    private fun backToTop(animated: Boolean) = methodChannel.invokeMethod("homePressed", animated)

    override fun onResume() {
        super.onResume()
        if (::mediaSessionStreamHandler.isInitialized) {
            mediaSessionStreamHandler.refresh()
        }
        if (::watchNextStreamHandler.isInitialized) {
            watchNextStreamHandler.refresh()
        }
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == WATCH_NEXT_PERMISSION_REQUEST_CODE) {
            watchNextStreamHandler.refresh()
        }
    }

    override fun onDestroy() {
        handler.removeCallbacks(backToTopInLauncher)
        val launcherApps = getSystemService(LAUNCHER_APPS_SERVICE) as LauncherApps
        launcherAppsCallbacks.forEach(launcherApps::unregisterCallback)
        if (::mediaSessionStreamHandler.isInitialized) {
            mediaSessionStreamHandler.dispose()
        }
        if (::watchNextStreamHandler.isInitialized) {
            watchNextStreamHandler.dispose()
        }
        super.onDestroy()
    }

    private fun getApplications(): List<Map<String, Serializable?>> {
        val tvActivitiesInfo = queryIntentActivities(false)
        val nonTvActivitiesInfo = queryIntentActivities(true)
                .filter { nonTvActivityInfo -> !tvActivitiesInfo.any { tvActivityInfo -> tvActivityInfo.packageName == nonTvActivityInfo.packageName } }
        return tvActivitiesInfo.map { buildAppMap(it, false) } + nonTvActivitiesInfo.map { buildAppMap(it, true) }
    }

    private fun getApplication(packageName: String): Map<String, Serializable?>? {
        return packageManager.getLeanbackLaunchIntentForPackage(packageName)
            ?.resolveActivityInfo(packageManager, 0)
            ?.let { buildAppMap(it, false) }
            ?: return packageManager.getLaunchIntentForPackage(packageName)
                ?.resolveActivityInfo(packageManager, 0)
                ?.let { buildAppMap(it, true) }
    }

    private fun applicationExists(packageName: String) = try {
        val flag = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.N) {
            PackageManager.MATCH_UNINSTALLED_PACKAGES
        } else {
            @Suppress("DEPRECATION")
            PackageManager.GET_UNINSTALLED_PACKAGES
        }
        packageManager.getApplicationInfo(packageName, flag)
        true
    } catch (e: PackageManager.NameNotFoundException) {
        false
    }

    private fun queryIntentActivities(sideloaded: Boolean) = packageManager
            .queryIntentActivities(Intent(ACTION_MAIN, null)
                    .addCategory(if (sideloaded) CATEGORY_LAUNCHER else CATEGORY_LEANBACK_LAUNCHER), 0)
            .map(ResolveInfo::activityInfo)

    private fun buildAppMap(activityInfo: ActivityInfo, sideloaded: Boolean) = mapOf(
            "name" to activityInfo.loadLabel(packageManager).toString(),
            "packageName" to activityInfo.packageName,
            "banner" to activityInfo.loadBanner(packageManager)?.let(::drawableToByteArray),
            "icon" to activityInfo.loadIcon(packageManager)?.let(::drawableToByteArray),
            "version" to packageManager.getPackageInfo(activityInfo.packageName, 0).versionName,
            "sideloaded" to sideloaded,
    )

    private fun launchApp(packageName: String) = try {
        val intent = packageManager.getLeanbackLaunchIntentForPackage(packageName)
                ?: packageManager.getLaunchIntentForPackage(packageName)
        startActivity(intent)
        true
    } catch (e: Exception) {
        false
    }

    private fun openSettings() = try {
        startActivity(Intent(Settings.ACTION_SETTINGS))
        true
    } catch (e: Exception) {
        false
    }

    private fun openAppInfo(packageName: String) = try {
        Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
                .let(::startActivity)
        true
    } catch (e: Exception) {
        false
    }

    private fun uninstallApp(packageName: String) = try {
        Intent(ACTION_DELETE)
                .setData(Uri.fromParts("package", packageName, null))
                .let(::startActivity)
        true
    } catch (e: Exception) {
        false
    }

    private fun isDefaultLauncher() = try {
        val defaultLauncher = packageManager.resolveActivity(Intent(ACTION_MAIN).addCategory(CATEGORY_HOME), 0)
        defaultLauncher?.activityInfo?.packageName == packageName
    } catch (e: Exception) {
        false
    }

    private fun startAmbientMode() = try {
        Intent(ACTION_MAIN)
            .setClassName("com.android.systemui", "com.android.systemui.Somnambulator")
            .let(::startActivity)
        true
    } catch (e: Exception) {
        false
    }

    private fun requestWatchNextPermission() = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        requestPermissions(arrayOf(READ_TV_LISTINGS), WATCH_NEXT_PERMISSION_REQUEST_CODE)
        true
    } else {
        false
    }

    private fun drawableToByteArray(drawable: Drawable): ByteArray? {
        if (drawable.intrinsicWidth <= 0 || drawable.intrinsicHeight <= 0) {
            return null
        }

        fun drawableToBitmap(drawable: Drawable): Bitmap {
            val bitmap = Bitmap.createBitmap(drawable.intrinsicWidth, drawable.intrinsicHeight, Bitmap.Config.ARGB_8888)
            val canvas = Canvas(bitmap)
            drawable.setBounds(0, 0, canvas.width, canvas.height)
            drawable.draw(canvas)
            return bitmap
        }

        val bitmap = drawableToBitmap(drawable)
        val stream = ByteArrayOutputStream()
        bitmap.compress(Bitmap.CompressFormat.PNG, 100, stream)
        return stream.toByteArray()
    }
}
