# Waves Launcher TV
Waves Launcher TV is an open-source alternative launcher for Android TV, built with [Flutter](https://flutter.dev).

It is a fork of [FLauncher](https://gitlab.com/flauncher/flauncher) by Étienne Fesser.

## Features
- [x] No ads
- [x] Customizable categories
- [x] Manually reorder apps within categories
- [x] Open "Android Settings"
- [x] Open "App info"
- [x] Uninstall app
- [x] Clock
- [x] Switch between row and grid for categories
- [x] Support for non-TV (sideloaded) apps
- [x] Navigation sound feedback
- [ ] Force stop app

## Screenshots
|  |  |  |
|--|--|--|
| ![](screenshots/Screenshot_1624378896.png) | ![](screenshots/Screenshot_1624378921.png) | ![](screenshots/Screenshot_1624378938.png) |

## Set Waves Launcher TV as default launcher

### Method 1: remap the Home button
This is the "safer" and easiest way. Use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap the Home button of the remote to launch Waves Launcher TV.

### Method 2: disable the default launcher
**:warning: Disclaimer :warning:**

**You are doing this at your own risk, and you'll be responsible in any case of malfunction on your device.**

The following commands have been tested on Chromecast with Google TV only. This may be different on other devices.

Once the default launcher is disabled, press the Home button on the remote, and you'll be prompted by the system to choose which app to set as default.

#### Disable default launcher
```shell
# Disable com.google.android.apps.tv.launcherx which is the default launcher on CCwGTV
$ adb shell pm disable-user --user 0 com.google.android.apps.tv.launcherx
# com.google.android.tungsten.setupwraith will then be used as a 'fallback' and will automatically
# re-enable the default launcher, so disable it as well
$ adb shell pm disable-user --user 0 com.google.android.tungsten.setupwraith
```

#### Re-enable default launcher
```shell
$ adb shell pm enable com.google.android.apps.tv.launcherx
$ adb shell pm enable com.google.android.tungsten.setupwraith
```

#### Known issues
On Chromecast with Google TV (maybe others), the "YouTube" remote button will stop working if the default launcher is disabled. As a workaround, you can use [Button Mapper](https://play.google.com/store/apps/details?id=flar2.homebutton) to remap it correctly.

## License
Waves Launcher TV is free software, released under the [GNU General Public License v3.0](LICENSE) or (at your option) any later version.

It is a modified version of [FLauncher](https://gitlab.com/flauncher/flauncher), copyright (C) 2021 Étienne Fesser, with contributions by Fernando Casas Schössow. It was forked from FLauncher's commit `4930cd7` and has been modified by Aurélien Lustrement since October 2026. The source files carry the copyright of both the original authors and the fork, according to who wrote them.

The [Outfit](https://github.com/Outfitio/Outfit-Fonts) font is licensed under the [SIL Open Font License 1.1](assets/fonts/outfit/OFL.txt).

If you enjoy it, you can also support the original author of FLauncher:

<a href="https://www.buymeacoffee.com/etienn01" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="200"></a>
