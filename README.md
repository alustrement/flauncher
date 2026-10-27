# Waves Launcher TV
Waves Launcher TV is an open-source alternative launcher for Android TV, built with [Flutter](https://flutter.dev). It is a fork of [FLauncher](https://gitlab.com/flauncher/flauncher) by Étienne Fesser, with a calmer look and the media you play at its heart.

Its interface is in French.

## Features

### Home screen
- **Now playing**: the media playing on the TV, or on another device through Spotify Connect, shown at the top of the screen with its artwork through the waves, and controlled with the media keys of the remote
- **Recent plays**: Android TV's "Play Next" programs, the last video watched and the last media of the apps playing in the background, such as Spotify, to resume them
- **Categories** of apps, shown as rows or grids, sorted alphabetically or manually, with their row height and number of columns to choose
- **All apps** page, opened from the top bar
- Clock, in 12 or 24 hour format
- Violet waves wallpaper, Outfit font and Material Symbols icons

### Navigation
- Pressing Home in the launcher goes back to the top of the page, and pressing it twice shows the recent apps
- Going up or down leads to the leftmost visible element of the next row
- Navigation sound feedback

### Apps
- Open, reorder, hide or uninstall an app, or open its info
- Support for non-TV (sideloaded) apps
- Shortcut to the Android settings
- No ads, no analytics

## Screenshots
|  |  |  |
|--|--|--|
| ![](screenshots/Screenshot_1624378896.png) | ![](screenshots/Screenshot_1624378921.png) | ![](screenshots/Screenshot_1624378938.png) |

## Installation on NVIDIA Shield TV Pro
These steps were followed on a Shield TV Pro (2019) running Android 11. Other Android TV devices use other package names for their stock launcher.

**:warning: You are doing this at your own risk: disabling the stock launcher is done with `adb`, and you'll be responsible in any case of malfunction on your device.**

### 1. Connect to the Shield with `adb`
1. In *Settings > Device Preferences > About*, press *Build* 7 times to unlock the developer options.
2. In *Settings > Device Preferences > Developer options*, enable *Network debugging*, which shows the address of the Shield.
3. Connect to it, and accept the prompt shown on the TV:
```shell
$ adb connect <address of the Shield>:5555
```

### 2. Install Waves Launcher TV
```shell
$ adb install app-release.apk
```

### 3. Disable the stock launcher
The stock launcher of the Shield is `com.google.android.tvlauncher`. Once disabled, Android TV's settings (`com.android.tv.settings`) only remain as a fallback home.
```shell
$ adb shell pm disable-user --user 0 com.google.android.tvlauncher
```

### 4. Set Waves Launcher TV as default launcher
```shell
$ adb shell cmd package set-home-activity com.aurelienlustrement.waveslaunchertv/.MainActivity
```
Without `adb`, press the Home button of the remote, and choose Waves Launcher TV, then *Always*.

### 5. Grant the accesses
Some features need accesses that the Shield doesn't offer to grant from its settings:

| Feature | Access | How to grant it |
|--|--|--|
| Recent plays | TV listings | The "Autoriser" button of the row, or `adb shell pm grant com.aurelienlustrement.waveslaunchertv android.permission.READ_TV_LISTINGS` |
| Now playing | Notification access | `adb shell cmd notification allow_listener com.aurelienlustrement.waveslaunchertv/com.aurelienlustrement.waveslaunchertv.MediaNotificationListener` |
| Recent apps on a double Home press | Accessibility service | Enable Waves Launcher TV in *Settings > Device Preferences > Accessibility* |

### Re-enable the stock launcher
```shell
$ adb shell pm enable com.google.android.tvlauncher
$ adb shell cmd package set-home-activity com.google.android.tvlauncher/.MainActivity
```

## License
Waves Launcher TV is free software, released under the [GNU General Public License v3.0](LICENSE) or (at your option) any later version.

It is a modified version of [FLauncher](https://gitlab.com/flauncher/flauncher), copyright (C) 2021 Étienne Fesser, with contributions by Fernando Casas Schössow. It was forked from FLauncher's commit `4930cd7` and has been modified by Aurélien Lustrement since October 2026. The source files carry the copyright of both the original authors and the fork, according to who wrote them.

The [Outfit](https://github.com/Outfitio/Outfit-Fonts) font is licensed under the [SIL Open Font License 1.1](assets/fonts/outfit/OFL.txt).
