# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Sport Timer is a Flutter interval timer for workouts (preparation, round, rest, number of rounds). Platforms: Android, iOS, macOS.

## Commands

The Flutter version is pinned in `.fvmrc`. Always use `fvm flutter` / `fvm dart`, never bare `flutter` or `dart`.

```bash
fvm flutter pub get
fvm dart run build_runner build      # needed after every fresh clone, see "Generated code"
./rebuild.sh                         # clean + build_runner + pub get
fvm flutter analyze
fvm flutter run                      # entry point is lib/main.dart
fvm flutter test                     # all tests
fvm flutter test test/widget_test.dart
```

`.zed/tasks.json` (local, git-excluded) wraps run, pub get, rebuild and test as Zed tasks.

`test/widget_test.dart` is the untouched Flutter counter template and fails: it pumps `MyApp`, which starts on the login page. There are no other tests.

## Current architecture (being replaced)

This is what the code does today. It is being migrated to the target in the next two sections, see `docs/mvvm-migration.md`. Update this section as each migration step lands, so it stays true.

Feature-first layout. Login and settings are already MVVM (see the target sections). Only the timer still uses Bloc/Cubit state. `get_it` for DI (registered by hand), and `go_router` for navigation.

- `lib/main.dart` holds `main()` and `MyApp`. It initializes Firebase, sets `SimpleBlocObserver`, then calls `configureDependencies()` before `runApp`.
- `lib/features/<name>/` holds the cubit, state and repository. `login` and `settings` are MVVM (`*_view_model.dart`, `*_state.dart`, normal imports, no barrel). `timer` has a barrel file (`timer.dart`) that declares the imports and the `part` directives, so the cubit, state and `timer.freezed.dart` files are all `part of` that one library. Add imports to the barrel, not to the part files.
- `lib/presentation/` holds pages and widgets. `home` is a bottom-navigation shell over the setup, templates and statistics pages.
- `lib/navigation.dart` defines the routes (`/` login, `/home`, `/timer`) and creates the timer cubit in a `BlocProvider`. The login and home pages create their own ViewModels, and `HomePage` shares one `SettingsViewModel` with its tabs. `/timer` receives a `TimerParams` through `state.extra`, which goes straight to the `TimeCountdownCubit` constructor.
- `lib/di/di.dart` registers the app-wide singletons by hand: `AudioPlayer`, `AudioManager`, `UserRepository` and `SettingsRepository`. Cubits are not registered. `AudioManager` plays the round sounds through the `AudioPlayer`.
- `lib/core/result.dart` holds the sealed `Result<T>` (`Success` and `Failure`). The user and settings repositories return it from the methods that can fail, and the ViewModels and cubits turn it into state.
- Timer settings are stored in `SharedPreferences` (`SharedPreferencesSettingsRepository`). Sign-in goes through `FirebaseAuth` in `FirebaseUserRepository`.
- The UI helpers (extensions, mixins, connectivity widgets) come from the separate `basic_flutter_helper` git package, tracked on its `master` branch.

## Target architecture (MVVM)

New code follows this section and the next one. Existing Bloc code stays as it is until its migration step. Do not mix the two inside one feature.

The layers, from the top:

- **View**: pages and widgets in `lib/presentation/`. A View reads the ViewModel state and calls its methods. It does navigation (`go_router`) and shows snackbars. It never calls a repository or `getIt`.
- **ViewModel**: one per screen or feature, in `lib/features/<name>/`. It holds the state, calls repositories and managers, and owns timers and side effects such as sounds. It never imports widgets or `BuildContext`, so it can be unit tested without a widget tree.
- **Data layer**: repositories and managers (`lib/features/<name>/*_repository.dart`, `lib/managers/`). They wrap platform APIs (`FirebaseAuth`, `SharedPreferences`, `AudioPlayer`). Each layer only talks to the one below it.

Rules:

- Feature-first layout: `lib/features/<name>/` holds the ViewModel, its state and the repository. No `part` barrels, no generated files. Use normal imports.
- Repositories return a `Result` (a sealed class with a success and a failure case), so the caller must handle errors. The ViewModel turns the `Result` into state (data, error message, loading flag). A View never sees a `Result`.
- A ViewModel method that the View must react to once (sign in, save) returns `Future<bool>`. The View awaits it and then navigates or shows the snackbar. Do not put one-time events in the state.
- Navigation stays on `go_router`. `lib/navigation.dart` creates each page and passes route params (`state.extra`) to the ViewModel constructor.
- `get_it` holds only app-wide singletons: repositories, `AudioManager` and `AudioPlayer`. They are registered by hand in `lib/di/di.dart`, with no `injectable`.
- ViewModels are not registered in `get_it`. The page creates its ViewModel and takes its dependencies with `getIt<T>()` at that point. A ViewModel shared by several widgets is owned by their closest common parent and passed down through constructors.

## Target state management

State is held with `ValueNotifier`. There is no state management package.

- In every class, the fields come first, then the constructor, then the methods.
- Each ViewModel has a private `ValueNotifier<XState>`, exposed as `ValueListenable<XState> get state`. Only the ViewModel changes it, with `_state.value = _state.value.copyWith(...)`.
- `XState` is a plain immutable Dart class: `final` fields, a `const` constructor, `copyWith`, `==` and `hashCode`. `ValueNotifier` only notifies when the new value is not equal to the old one, so `==` is required. No `freezed`.
- Views read state with `ValueListenableBuilder`. To rebuild only part of a screen, build a smaller `ValueListenable` from the state for that widget.
- The ViewModel has a `dispose()` that cancels timers and subscriptions and disposes the notifier. The `State` of the page that created the ViewModel calls it from its own `dispose()`.
- Async methods check a `_disposed` flag before setting state, because the page can be gone when the work finishes.
- Test ViewModels with unit tests and hand-written fake repositories. No `bloc_test`, no mocking package unless it is added on purpose.

## Generated code

This section describes the current setup and goes away with the migration.

`**/*.freezed.dart` and `**/*.g.dart` are git-ignored, so the project does not analyze or compile until `build_runner` has run. Freezed classes must be declared `abstract class` (freezed 4).

## Dependencies and Android build

- All versions in `pubspec.yaml` are pinned exactly, with no `^`. Keep it that way when adding packages.
- Two packages are held back by conflicts, so check `fvm flutter pub outdated` before bumping them: `freezed` (4.0.3 needs `analyzer` 14, which the Flutter SDK's test package blocks) and `build_runner` (2.17 needs `build` 5; `injectable_generator`, which needed `build` 4, is gone, so this may be free to bump, check `pub outdated`). `flutter_bloc` must stay compatible with `basic_flutter_helper`, which pins its own range.
- The Android build uses Gradle 9.3.1, AGP 9.1.0 and Kotlin 2.4.0. `firebase_core` and `firebase_auth` still apply the old Kotlin Gradle plugin, so `android.builtInKotlin=false` in `android/gradle.properties` must stay until they migrate. The "plugins that apply KGP" warning during the build is expected.
- Firebase config (`lib/firebase_options.dart`, `android/app/google-services.json`, `ios/Runner/GoogleService-Info.plist`) is generated by `flutterfire configure` for the `sport-timer-503e8` project.

## Workflow

For an end-to-end change (bug, feature, improvement, refactor), use the `skill-orchestrator` skill in `.claude/skills/`. Never use `skill-ticket-orchestrator` here: this project has no tickets and no Linear. The skill asks for approval twice, on the plan and on the commit.

## Shared dev environment (my-dev-env)

Agents, skills, rules and task profiles are not stored in this repo. `~/.claude/{agents,skills,rules,profiles}` and `~/.claude/CLAUDE.md` are symlinks into `~/Projects/my-dev-env`, so every project picks them up with no per-repo setup. To change one, edit it in `~/Projects/my-dev-env`, never copy it here. `~/Projects/my-dev-env/profiles/index.md` says which task profile to read for which task (tests, review, hand-off, merge).

Rules that apply to this project only live in `.claude/rules/` in this repo (for example `.claude/rules/dart-style.md`), not in my-dev-env.

This is a personal repo (`alexaniko88`). Commit with the repo-local noreply email (`git config user.email`), never a company address.
