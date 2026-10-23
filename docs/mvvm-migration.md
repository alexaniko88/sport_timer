# MVVM migration

Goal: move from Bloc/Cubit, `freezed` and `injectable` to MVVM with `ValueNotifier` state and hand-written `get_it` registrations. The target rules are in `CLAUDE.md` ("Target architecture" and "Target state management").

Do one step per change, and keep the app working after each one. Tick the box when a step lands, and update the "Current architecture" section in `CLAUDE.md` in the same change.

## Steps

- [x] 1. Remove the unused dependencies: `json_annotation`, `json_serializable`, `mockito`, `bloc_test`. `freezed` moved to `dev_dependencies`.
- [x] 2. Replace `injectable` with hand-written `get_it` registrations in `lib/di/di.dart`. Register only repositories, `AudioManager` and `AudioPlayer`. Cubits are still created in `navigation.dart` (build them with `getIt` arguments, not by registering them). Remove `injectable`, `injectable_generator`, `di_module.dart`, `di.config.dart` and the annotations.
- [x] 3. Add a `Result` type for the data layer and make the repositories return it.
- [ ] 4. Login: `LoginViewModel` with a hand-written `LoginState`. `signIn` returns `Future<bool>`, and `login_page.dart` awaits it instead of using the `BlocListener`. Move the text controllers out of `build`.
- [ ] 5. Settings: one `SettingsViewModel` owned by `HomePage` and passed to the setup and templates tabs by constructor. This removes the second instance created in `templates_page.dart` and the reload on tab 0 in `home_page.dart`.
- [ ] 6. Timer: write `TimerViewModel`, which owns the `Timer` and plays the sounds through `AudioManager`. `TimerPage` becomes stateful and disposes it. Fix `start()` so it cannot create a second timer.
- [ ] 7. Statistics: pass the user name in, so `statistics_page.dart` no longer reads `UserRepository` itself.
- [ ] 8. Remove the `basic_flutter_helper` package completely. The app only uses `printLog` (cubit, bloc observer, `stopwatch.dart`) and `asMinutesAndSeconds` (`timer_setup_page.dart`, `stopwatch.dart`). Replace them with a local logging call and a local `Duration` extension, remove the imports in `lib/features/timer/timer.dart`, `lib/presentation/home/home.dart`, `lib/presentation/timer/timer.dart` and the dependency from `pubspec.yaml`. Then `bloc`, `flutter_bloc` and `provider` leave `pubspec.lock` together with the direct dependency.
- [ ] 9. Cleanup: remove `SimpleBlocObserver`, `flutter_bloc`, `freezed`, `freezed_annotation` and `build_runner`. Update `rebuild.sh`, `.gitignore`, `.claude/skills/skill-orchestrator/SKILL.md` and the "Commands", "Architecture", "Generated code" and "Dependencies" sections of `CLAUDE.md`. Delete this file and every reference to it.

Tests are out of scope for this migration. They will be covered later, after it is done.

## Risks

- There are almost no tests today, so check the timer by hand (preparation, round, rest, pause, resume, finish, sounds) after step 6.
- Async work can finish after the page is gone. Check `_disposed` before setting state.
- Bloc closed cubits for us. A ViewModel must be disposed by the page that creates it, including its `Timer`.

## Known issues to fix on the way

- `start()` can create a second timer (`time_countdown_cubit.dart`).
- `playPreparationSound` adds a new listener on every call (`default_audio_manager.dart`).
