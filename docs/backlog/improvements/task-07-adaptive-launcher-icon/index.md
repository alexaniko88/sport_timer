---
id: IMP-07
status: draft
type: improve
complexity: 6
depends-on: [IMP-06]
touches:
  - assets/icons/app_icon.png
  - assets/icons/launcher/**
  - pubspec.yaml
  - ios/Runner/Assets.xcassets/AppIcon.appiconset/**
  - android/app/src/main/res/mipmap-*/**
  - android/app/src/main/res/values/colors.xml
  - android/app/src/main/ic_launcher-playstore.png
  - android/app/src/main/AndroidManifest.xml
skills: []
---

# Adaptive launcher icon for iOS and Android

Improvements: [Improvements](../index.md)

Related: [IMP-06: Notification icon](../task-06-add-notification-icon/index.md).

> **Run this task by hand in an interactive session, not with `skill-dispatcher`.** It needs `rsvg-convert` (Homebrew `librsvg`) and `fvm dart run icons_launcher:create`, which dispatcher runners may not run. That is why it stays `draft`: the dispatcher only picks `ready` tasks. Ask the user before installing `librsvg` if `rsvg-convert` is missing.

## Goal

Replace today's black launcher icon with a white barbell on brand red, and let it follow the home screen: iOS 18 light, dark and tinted appearances, and an Android adaptive icon with a themed (monochrome) layer for Android 13+. The barbell is redrawn as SVG from the approved mockup, so the icon is sharp at every size.

## Context

- Current behavior:
  - Source `assets/icons/app_icon.png`: 256 x 256, black line barbell on transparent. It is listed by `- assets/icons/` in `pubspec.yaml`, so it is bundled into the app, but no code uses it.
  - `pubspec.yaml` `icons_launcher:` block (dev dependency `icons_launcher` 3.1.0): only `image_path: "assets/icons/app_icon.png"` and `android`/`ios` `enable: true`.
  - iOS: `icons_launcher` removes the alpha channel of the iOS light image (`removeAlpha()` in its `lib/src/ios.dart`), which turned the transparent area black. `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` is a fully black square; the barbell cannot be seen. Only a light appearance exists.
  - Android: only legacy `android/app/src/main/res/mipmap-*/ic_launcher.png` (black barbell on transparent). No `mipmap-anydpi-v26/`, no background or monochrome layer. On dark wallpapers it is nearly invisible.
- Brand color: `AppPalette.brand` = `0xFFFF5252` (`lib/shared/presentation/theme/app_palette.dart`).
- `icons_launcher` 3.1.0 facts this plan relies on (read in its source under the pub cache):
  - iOS keys: `image_path`, `dark_path`, `tinted_path`. Only the light image gets `removeAlpha()`; dark and tinted images are saved as given. `Contents.json` gets `appearances: [{appearance: luminosity, value: dark}]` and `value: tinted` entries.
  - Android keys: `image_path` (legacy `mipmap-*/ic_launcher.png`, 48 to 192 px), `adaptive_background_color`, `adaptive_foreground_image` and `adaptive_monochrome_image` (written as `mipmap-*/ic_launcher_foreground.png` and `mipmap-*/ic_launcher_monochrome.png`, 108 to 432 px), `mipmap-anydpi-v26/ic_launcher.xml`, and the color in `values/colors.xml` as `ic_launcher_background`. Without `adaptive_round_image` it adds no `android:roundIcon`.
- Approved mockup: [mockup.html](mockup.html). Its `BARBELL` constant is the drawing. iOS tiles use scale 0.9 of the canvas; Android uses scale 0.75 of the visible icon.
- macOS has no runner in this repo (`macos/` holds only `Flutter/` and `Podfile`), so there is no macOS icon.
- IMP-06 must be merged first: it moves the Android notification off the launcher icon. Without it, the notification would show a white square after this change.

## Contract

Source files, all new here, in `assets/icons/launcher/` (a subfolder, so `- assets/icons/` in `pubspec.yaml` does not bundle them). Every SVG uses `viewBox="0 0 100 100"` and draws the barbell with this group, where `S` is the scale and `C` the color:

```xml
<g transform="translate(50 50) scale(S) translate(-50 -50)" fill="none" stroke="C" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round">
  <rect x="17" y="30" width="11" height="22" rx="3.5"/>
  <rect x="72" y="30" width="11" height="22" rx="3.5"/>
  <path d="M28 41H72M41 41V72M59 41V72M41 57H59"/>
</g>
```

| SVG | Background | Barbell `C` | Scale `S` | PNG size | Used as |
| --- | --- | --- | --- | --- | --- |
| `ios_light.svg` | `<rect width="100" height="100" fill="#FF5252"/>` | `#FFFFFF` | 0.9 | 1024 | iOS `image_path` |
| `ios_dark.svg` | none (transparent) | `#FF5252` | 0.9 | 1024 | iOS `dark_path` |
| `ios_tinted.svg` | `<rect width="100" height="100" fill="#000000"/>` | `#FFFFFF` | 0.9 | 1024 | iOS `tinted_path` |
| `android_legacy.svg` | `<rect width="100" height="100" fill="#FF5252"/>` | `#FFFFFF` | 0.75 | 1024 | Android `image_path` |
| `android_foreground.svg` | none (transparent) | `#FFFFFF` | 0.5 | 432 | `adaptive_foreground_image` |
| `android_monochrome.svg` | none (transparent) | `#FFFFFF` | 0.5 | 432 | `adaptive_monochrome_image` |

Scale 0.5 on the 108 dp adaptive canvas equals the approved 0.75 of the visible 72 dp icon (0.75 x 72 / 108), and keeps the barbell inside the 66 dp safe zone.

Each PNG sits next to its SVG with the same base name (`ios_light.png`, ...), made with `rsvg-convert -w <size> -h <size> -o assets/icons/launcher/<name>.png assets/icons/launcher/<name>.svg`.

`pubspec.yaml` `icons_launcher:` block becomes:

```yaml
icons_launcher:
  platforms:
    android:
      enable: true
      image_path: "assets/icons/launcher/android_legacy.png"
      adaptive_background_color: "#FF5252"
      adaptive_foreground_image: "assets/icons/launcher/android_foreground.png"
      adaptive_monochrome_image: "assets/icons/launcher/android_monochrome.png"
    ios:
      enable: true
      image_path: "assets/icons/launcher/ios_light.png"
      dark_path: "assets/icons/launcher/ios_dark.png"
      tinted_path: "assets/icons/launcher/ios_tinted.png"
```

Generated outputs (by `fvm dart run icons_launcher:create`, never edited by hand): `ios/Runner/Assets.xcassets/AppIcon.appiconset/*` and `Contents.json`, `android/app/src/main/res/mipmap-*/ic_launcher*.png`, `android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml`, `android/app/src/main/res/values/colors.xml`, and possibly `android/app/src/main/ic_launcher-playstore.png` and an `AndroidManifest.xml` touch-up. Commit what the generator writes inside `touches`; if it writes anything outside `touches`, stop and report it.

Consumers: the iOS and Android launchers. No Dart code changes.

## Behavior

- iOS light (and iOS 15 to 17, which only have one icon): white barbell on opaque `#FF5252`.
- iOS 18 dark home screen: red barbell; iOS draws its own dark background behind the transparent area.
- iOS 18 tinted home screen: iOS recolors the grayscale white-on-black image with the user's tint.
- Android 8+: adaptive icon, red background layer, white barbell foreground; every launcher shape (circle, squircle, rounded square, teardrop) crops only background.
- Android 13+ with themed icons on: the launcher draws the monochrome barbell in wallpaper colors.
- Android 7.x and older: legacy PNG, white barbell on a red square.
- The Android notification icon stays the IMP-06 drawable; this task does not change it.

## Mockup

[mockup.html](mockup.html), approved. States this task implements: iOS Light, Dark, Tinted; Android Circle, Squircle, Rounded square, Teardrop, Themed, each on light and dark wallpaper. The "Today" tiles show the old icon for comparison only.

## Decisions

- White barbell on brand red `#FF5252` as the default icon. Accepted recommendation: matches the app's brand and reads on light and dark wallpapers.
- iOS 18 dark: red barbell on transparent. Accepted recommendation: Apple's dark icon guideline.
- iOS 18 tinted: ship a grayscale variant. Accepted recommendation: the system's own tint of a red icon often looks muddy.
- Android 13+ themed icon: ship a monochrome layer. Accepted recommendation: otherwise the icon stays red while other icons follow the wallpaper.
- Redraw the barbell as SVG and convert with `rsvg-convert`. User-chosen. That is why the task runs interactively, outside the dispatcher.
- Android barbell at 75% of the visible icon. User-chosen: the first 60% draft looked too small.
- Sources in `assets/icons/launcher/`, old `assets/icons/app_icon.png` deleted (nothing uses it afterwards). Planner proposal following the existing asset layout.
- No round icon (`adaptive_round_image`): adaptive icons cover round launchers on Android 8+.

## Out of scope

- The Android notification icon ([IMP-06](../task-06-add-notification-icon/index.md)).
- macOS, web and desktop icons.
- Showing the app icon inside the app UI.
- The Android 12+ splash screen (it uses the launcher icon automatically; no separate config).
- Changing the barbell drawing beyond the approved mockup.

## Files and tests

1. Check `rsvg-convert --version`. If it is missing, ask the user, then `brew install librsvg`.
2. Create the six SVGs in `assets/icons/launcher/` exactly per the Contract table.
3. Convert each SVG to its PNG with the `rsvg-convert` command in the Contract.
4. Edit the `icons_launcher:` block in `pubspec.yaml` to the Contract YAML. Leave the `flutter: assets:` list as it is.
5. Delete `assets/icons/app_icon.png`.
6. Run `fvm dart run icons_launcher:create`.
7. Look at the generated images and compare them with [mockup.html](mockup.html): `Icon-App-1024x1024@1x.png` and the dark and tinted 1024 files in `AppIcon.appiconset`, `mipmap-xxxhdpi/ic_launcher.png`, `mipmap-xxxhdpi/ic_launcher_foreground.png`, `mipmap-xxxhdpi/ic_launcher_monochrome.png`.
8. Run the acceptance checks below, then `fvm dart tool/agent_check.dart` with builds (it runs the Android and iOS debug builds because `android/`, `ios/` and `pubspec.yaml` change; the Android build also compiles IMP-06's vector drawable).

No Dart test: no Dart code changes, and goldens do not capture launcher icons. `test/snapshots/` is unaffected.

## Acceptance

- [ ] When the iOS light icon is generated, then `Icon-App-1024x1024@1x.png` has no alpha and shows the white barbell on `#FF5252`, matching the mockup. Check: `sips -g hasAlpha ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` shows `no`, and a visual check against `mockup.html`.
- [ ] When the iOS dark icon is generated, then `Contents.json` has `luminosity` `dark` entries and the dark 1024 PNG has alpha (red barbell, transparent background). Check: `rg -n '"dark"' ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`, then `sips -g hasAlpha` on the 1024 file that entry names shows `yes`.
- [ ] When the iOS tinted icon is generated, then `Contents.json` has `luminosity` `tinted` entries pointing to a grayscale image (white barbell on black). Check: `rg -n '"tinted"' ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` and a visual check of the file it names.
- [ ] When Android 8+ loads the icon, then `mipmap-anydpi-v26/ic_launcher.xml` has `background`, `foreground` and `monochrome` layers, and the background color is `#FF5252`. Check: `rg -n "monochrome|foreground|background" android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml` and `rg -in "FF5252" android/app/src/main/res/values/colors.xml`.
- [ ] When Android 7.x or older loads the icon, then `mipmap-*/ic_launcher.png` shows the white barbell on a red square. Check: visual check of `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png`.
- [ ] When the foreground and monochrome layers are drawn, then the barbell is about 75% of the visible icon and inside the 66 dp safe zone. Check: visual check of `mipmap-xxxhdpi/ic_launcher_foreground.png` and `mipmap-xxxhdpi/ic_launcher_monochrome.png` against the mockup (the barbell spans about half the 432 px width, centered).
- [ ] When the sources are listed, then the SVGs and their PNGs are in `assets/icons/launcher/`, `pubspec.yaml` points `icons_launcher` at them, and `assets/icons/app_icon.png` is gone. Check: `ls assets/icons assets/icons/launcher` and `rg -n "assets/icons" pubspec.yaml`.
- [ ] When the change is checked, then the Android and iOS debug builds pass. Check: `fvm dart tool/agent_check.dart`.
