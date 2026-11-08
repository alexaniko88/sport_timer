# Adaptive app icon: planning record

> **Frozen.** This record is historical. The authoritative files are [IMP-06](../../improvements/06-add-notification-icon/index.md) and [IMP-07](../../improvements/07-adaptive-launcher-icon/index.md). The approved mockup moved to [IMP-07's folder](../../improvements/07-adaptive-launcher-icon/mockup.html); "the mockup" below means that file. Android legacy icon: the tasks use scale 0.75 (like the adaptive icon), refining D6.

## Original request

"We need to check the application icon that is being used right now because it's black color. So I guess we have to adopt the color of the icon according to the scene. If it's dark or black, or basically around where it's being used, because otherwise having black everywhere it just doesn't feel good. Please only plan for now."

## Evidence

- Source image: `assets/icons/app_icon.png`, 256 x 256 RGBA. A black line barbell on a transparent background. It is listed under `flutter: assets: - assets/icons/` in `pubspec.yaml`, so it is bundled into the app, but no Dart code references it.
- Generator: `icons_launcher` 3.1.0 (dev dependency, `pubspec.yaml` `icons_launcher:` block) with only `image_path` and `android`/`ios` `enable: true`. Last icon change: commit `142c291` "Integrating a new app icon".
- iOS today: `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` is RGB with no alpha. `icons_launcher` (`lib/src/ios.dart`, `createIosIcons`) calls `removeAlpha()` on a light image that has alpha, which flattened the transparent area to black. Result: a fully black square, barbell invisible. Only one (light) appearance. Deployment target iOS 15.0.
- Android today: only legacy `mipmap-*/ic_launcher.png` (black barbell on transparent RGBA). No `mipmap-anydpi-v26` adaptive icon, no background layer, no monochrome layer. On a dark wallpaper the barbell is nearly invisible; Android 8+ launchers shrink a legacy icon into their own shape.
- macOS: `macos/` holds only `Flutter/` and `Podfile`, no `Runner` or `AppIcon.appiconset`. Nothing to change.
- The app UI does not show the app icon anywhere (the drawer header uses `Icons.timer_outlined`).
- Brand color: `AppPalette.brand` = `0xFFFF5252` in `lib/shared/presentation/theme/app_palette.dart`.
- `icons_launcher` 3.1.0 supports Android `image_path`, `adaptive_background_color`, `adaptive_foreground_image`, `adaptive_round_image`, `adaptive_monochrome_image`, and iOS `image_path`, `dark_path`, `tinted_path` (written to `Contents.json` with `appearances: [{appearance: luminosity, value: dark|tinted}]`).
- Tools: no `rsvg-convert`, `magick` or `inkscape` installed on the machine. Dispatcher runners cannot run image tools, interpreters or `fvm dart run icons_launcher:create` (`.agents/skills/skill-dispatcher/references/project-overrides.md`, "Minimal tools").
- Platform docs: Android adaptive icons and themed icons (https://developer.android.com/develop/ui/views/launch/icon_design_adaptive): 108 dp layers, 66 dp safe zone, monochrome layer for Android 13+. Apple app icons (https://developer.apple.com/design/human-interface-guidelines/app-icons): iOS 18 light, dark and tinted appearances; the light icon is opaque.
- No existing task in `project-tasks/` (including `done/`) covers the launcher icon.

## Coverage

| Ref | Requirement | State | Evidence or decision |
| --- | --- | --- | --- |
| C1 | iOS icon is visible (not all black) | resolved | D1: opaque red light icon |
| C2 | iOS icon follows light / dark / tinted | resolved | D2, D3 |
| C3 | Android icon visible on light and dark wallpapers | resolved | D1, D6: adaptive icon with red background |
| C4 | Android themed icon | resolved | D4 |
| C5 | Icon colors and look | resolved | D1, D2, D6; mockup approved |
| C6 | Source artwork and how it is made | resolved | D5, D7 |
| C7 | macOS | not applicable | No macOS runner in the repo |
| C8 | In-app icon usage | not applicable | The UI does not show the app icon |
| C9 | How success is checked | resolved | D8 |
| C10 | Old Android (7.x and older) legacy icon | resolved | D6 |
| C11 | Leftover old source image | resolved | D7 |

## Decisions

- D1. Default (light) icon look: white barbell on brand red `#FF5252` (`AppPalette.brand`). Accepted recommendation: matches the app's brand and reads on light and dark wallpapers.
- D2. iOS 18 dark appearance: brand red `#FF5252` barbell on a transparent background (the system draws the dark background). Accepted recommendation: Apple's dark icon guideline.
- D3. iOS 18 tinted appearance: ship a grayscale tinted variant (white barbell on opaque black). Accepted recommendation: the system-made tint of a red icon often looks muddy.
- D4. Android 13+ themed icons: ship a monochrome layer. Accepted recommendation: otherwise the icon stays red while other icons follow the wallpaper.
- D5. Artwork: an agent redraws the same barbell as SVG sources and converts them to PNG inputs for `icons_launcher`. User-chosen. Consequence: the work needs `rsvg-convert` (Homebrew `librsvg`) and `fvm dart run icons_launcher:create`, which dispatcher runners may not run, so it runs through `skill-orchestrator` in an interactive session, not the dispatcher.
- D6. Mockup approved (`mockup.html`, version 3). Barbell geometry as in its `BARBELL` constant. iOS: barbell at 90% of the 100-unit canvas. Android: barbell at 75% of the visible icon (user asked to make it bigger than the first 60% draft), which stays inside the 66 dp safe zone. Android legacy `ic_launcher.png` for Android 7.x and older: the same red square with the white barbell (follows the light icon; no question needed).
- D7. Planner proposal following repo patterns: SVG sources and generated PNG inputs live in `assets/icons/launcher/` (a subfolder, so `- assets/icons/` in `pubspec.yaml` does not bundle them). The old `assets/icons/app_icon.png` is deleted because nothing uses it after the change.
- D8. Checks: no Dart test is useful (no Dart code changes). Checks are commands on the generated files plus `fvm dart tool/agent_check.dart` (it runs the Android and iOS debug builds when `android/`, `ios/` or `pubspec.yaml` change) and a look at the generated PNGs against the mockup.

- D9. Add a dedicated Android notification icon. Accepted recommendation. `audio_service` 0.18.19 defaults `androidNotificationIcon` to `'mipmap/ic_launcher'` and `AudioServiceConfig` in `lib/features/timer/data/default_background_keep_alive.dart` does not set it. Android draws the small icon from its alpha only, so an opaque red launcher icon would become a white square. Fix: a white barbell vector drawable `android/app/src/main/res/drawable/ic_stat_sport_timer.xml` and `androidNotificationIcon: 'drawable/ic_stat_sport_timer'`. It is plain text, so a dispatcher runner can do it, and it must merge before the launcher change.
- D10. Generator facts that fix the config (from `icons_launcher` 3.1.0 source): `removeAlpha()` runs only on the iOS light image; `dark_path` and `tinted_path` images are saved as given, so the transparent dark PNG keeps its alpha. Android legacy `mipmap-*/ic_launcher.png` comes from the Android `image_path`; the adaptive layers come from `adaptive_background_color`, `adaptive_foreground_image` and `adaptive_monochrome_image`. No `adaptive_round_image`, so no `android:roundIcon` is added. `minSdk` is `flutter.minSdkVersion`, so legacy PNGs are still needed for Android 7.x and older.
- D11. "Adapt the color to the scene" is covered by the system appearances the user chose (D2 iOS dark, D3 iOS tinted, D4 Android themed) on top of the fixed brand light icon (D1).

## Open questions

None.

## Review

Interview completeness review (fresh agent), result `incomplete`, six findings, all resolved:

1. Dark iOS PNG alpha: investigated, kept (D10). Acceptance checks the dark PNG has alpha and the light one does not.
2. Android legacy and round icons: investigated (D10).
3. Mockup covers iOS light, dark, tinted and Android adaptive shapes and themed; legacy Android uses the light square (D6).
4. Interpretation of "adapt to the scene": recorded (D11).
5. Notification icon: user decided to add one (D9).
6. `pubspec.yaml` `image_path` repointed: covered in the launcher task contract.
