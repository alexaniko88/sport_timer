---
id: TPL-03-03
status: ready
type: feat
complexity: 6
depends-on: [TPL-03-05]
touches:
  - lib/features/templates/presentation/template_form_state.dart
  - lib/features/templates/presentation/template_form_view_model.dart
  - lib/features/templates/presentation/template_form_args.dart
  - lib/features/templates/presentation/template_form_page.dart
  - lib/features/templates/presentation/extensions/custom_template_icon_name_extension.dart
  - lib/navigation.dart
  - lib/l10n/
  - test/features/templates/presentation/template_form_view_model_test.dart
  - test/features/templates/presentation/template_form_page_test.dart
  - test/snapshots/ui_snapshots_test.dart
  - test/snapshots/README.md
  - test/snapshots/goldens/template_form_create.png
  - test/snapshots/goldens/template_form_name_error.png
  - test/snapshots/goldens/template_form_edit.png
  - test/snapshots/goldens/template_delete_dialog.png
skills: []
---

# Add the template form

Story: [Create your own templates](../index.md)

Epic: [Templates](../../../index.md)

## Goal

A full-page form, on its own route, to create and edit an own template, with delete from the app bar in edit mode. Nothing opens it yet; Open the form from Templates (TPL-03-07) adds the "+" and the long press. Serves R2, R3, R9 and R10.

## Context

- Setting cards to reuse: `TimerSettingCard` and `TimerSettingGrid` (`lib/features/settings/presentation/widgets/timer_setting_card.dart`) and `TimerSettingsPickerWheel.show` (`widgets/timer_settings_picker_wheel.dart`). `_buildOption` in `lib/features/settings/presentation/timer_setup_page.dart` shows the exact icons, colors (`context.timerColors`), labels (`setupPreparation`, `setupWork`, `setupRest`, `commonRounds`), `semanticHint: l10n.commonOpensSelectorHint` and limits: preparation `maxMinutes: 5`; work `minDuration: Duration(seconds: 1)`, `maxMinutes: 60`; rest `maxMinutes: 60`; rounds `maxRounds: TimerSettings.maxRounds`. Its private `_SessionOverview` is the model for the footer; the form gets its own private footer widget.
- Routes: `RoutePath` and `Routes.router` in `lib/navigation.dart`; pages get their view model from `state.extra`.
- Name extension to copy: `lib/features/templates/presentation/extensions/template_names_extension.dart`.
- Approved [mockup](../mockup.html).

## Contract

- `SettingsViewModel.saveCustomTemplate`, `deleteCustomTemplate`, `SettingsState.customTemplates`, `SettingsState.timerSettings` — provided by TPL-03-04.
- `CustomTemplate` (`maxNameLength`), `CustomTemplateIcon`, `CustomTemplateListIds.nextId` — provided by TPL-03-02. `CustomTemplateIconData.iconData` and the harness parameter `configureFakeDependencies(customTemplates:)` — provided by TPL-03-05.
- `TemplateFormArgs` — new here: `class TemplateFormArgs { final SettingsViewModel settingsViewModel; final CustomTemplate? template; }`, `const` constructor with named parameters (`template` optional). `template == null` means create. Consumer: TPL-03-07.
- `RoutePath.templateForm('/template-form')` — new here; its `GoRoute` (with `name: RoutePath.templateForm.value`, like the other routes) builds `TemplateFormPage(args: state.extra as TemplateFormArgs)`. Consumer: TPL-03-07.
- `TemplateFormState` — new here: `name` (`String`), `icon` (`CustomTemplateIcon`), `settings` (`TimerSettings`), `hasNameError` (`bool`), `isBusy` (`bool`), `isEditing` (`bool`); `const`, `copyWith`, `==`, `hashCode`.
- `TemplateFormViewModel` — new here, `TemplateFormViewModel({required SettingsViewModel settingsViewModel, CustomTemplate? template})`:
  - Create starts with `name: ''`, `icon: CustomTemplateIcon.weights`, `settings:` the current `timerSettings`. Edit starts from the template.
  - `updateName(String)`: sets `name`; clears `hasNameError` when the trimmed name is not empty.
  - `selectIcon(CustomTemplateIcon)`, `updatePreparationTime(Duration)`, `updateRoundTime(Duration)`, `updateRestTime(Duration)`, `updateRounds(int)`: change only the form state.
  - `Future<bool> save()`: trimmed name empty → `hasNameError: true`, returns `false`, no write. Otherwise builds `CustomTemplate(id: template?.id ?? customTemplates.nextId, name: <trimmed>, icon, settings)` and returns `saveCustomTemplate(...)`.
  - `Future<bool> delete()`: returns `deleteCustomTemplate(template.id)`; only in edit mode.
  - Both set `isBusy` while running, return `false` at once when already busy, and do not set state after `dispose()`.
- `CustomTemplateIconName` — new here, `extension CustomTemplateIconName on AppLocalizations { String customTemplateIconName(CustomTemplateIcon icon) }`, an exhaustive `switch` over the 8 values.

## View spec

- **App bar:** back button and title `templateFormCreateTitle` or `templateFormEditTitle`. Edit mode only: action `IconButton(icon: Icon(Icons.delete_outline), tooltip: l10n.templateFormDeleteTooltip)`, then `SizedBox(width: AppSpacing.s8)`.
- **Body** (`ListView`, padding `AppSpacing.s16`):
  - `TextField` with a `TextEditingController` the page's `State` creates in `initState` (text = state `name`) and disposes; `onChanged: viewModel.updateName`; label `templateFormNameLabel`, `maxLength: CustomTemplate.maxNameLength` with its counter, `errorText: l10n.templateFormNameEmpty` when `hasNameError`, `textCapitalization: TextCapitalization.sentences`, initial text from the state.
  - Section label `templateFormIconLabel` (`AppTextThemeExtension.emphasizedLabel`, `onSurfaceVariant`).
  - A `GridView.count(crossAxisCount: 4, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(), mainAxisSpacing: AppSpacing.s8, crossAxisSpacing: AppSpacing.s8, childAspectRatio: 1.5)` of the 8 icons in enum order (about 56 high at 390 wide). Each is an `AppSurface(isSelected: <chosen>, onTap: …)` at least 48 by 48, holding `Icon(icon.iconData, color: colorScheme.primary)`, wrapped in `Semantics(button: true, selected: <chosen>, inMutuallyExclusiveGroup: true, label: l10n.customTemplateIconName(icon), excludeSemantics: true)`.
  - Section label `templateFormTimerLabel`, then the `TimerSettingGrid` with the 4 `TimerSettingCard`s; each opens its wheel and calls the form view model, never `SettingsViewModel`.
- **Footer** (fixed below the list, padding `AppSpacing.s16`): an `AppSurface` with a row `setupSessionLength` + total, computed exactly like `TimerSetupPage.build` (`TimerSchedule.fromParams(TimerParams(preparationTime: …, roundTime: …, restTime: …, rounds: …, style: settingsViewModel.state.value.timerStyle)).totalDuration`, from the form's settings) and shown with `asMinutesAndSeconds`, then `AppButton.primary` with `templateFormSave`, disabled (`onPressed: null`) while `isBusy`.
- **Save:** `true` → `context.pop()`; `false` with `hasNameError` → stay, the field shows the error; any other `false` → snackbar `templateSaveError`, stay with the input kept.
- **Delete:** `showDialog<bool>` with title `templateDeleteDialogTitle(name)`, content `templateDeleteDialogBody`, actions `TextButton(commonCancel)` and `TextButton(style: TextButton.styleFrom(foregroundColor: colorScheme.error), child: Text(templateDeleteDialogConfirm))`. Confirm closes the dialog, then calls `delete()`: `true` → `context.pop()`; `false` → snackbar `templateDeleteError`. Cancel or dismiss → nothing changes.
- **Back** leaves without saving.
- **Ownership:** `navigation.dart` builds `TemplateFormPage(args: …)`; the page's `State` creates the `TemplateFormViewModel` from `args` in `initState` and disposes it in `dispose`.
- If `saveCustomTemplate` refuses a 21st template (only possible in a race, since "+" blocks it), the page shows the generic `templateSaveError`.
- **Strings** (en / es; each English key with a `description`):
  - `templateFormCreateTitle`: "New template" / "Nueva plantilla"
  - `templateFormEditTitle`: "Edit template" / "Editar plantilla"
  - `templateFormNameLabel`: "Name" / "Nombre"
  - `templateFormNameEmpty`: "Enter a name" / "Escribe un nombre"
  - `templateFormIconLabel`: "Icon" / "Icono"
  - `templateFormTimerLabel`: "Timer" / "Temporizador"
  - `templateFormSave`: "Save" / "Guardar"
  - `templateFormDeleteTooltip`: "Delete template" / "Eliminar plantilla"
  - `templateDeleteDialogTitle`: "Delete \"{name}\"?" / "¿Eliminar «{name}»?" (`name`: `String`)
  - `templateDeleteDialogBody`: "This can't be undone." / "No se puede deshacer."
  - `templateDeleteDialogConfirm`: "Delete" / "Eliminar"
  - `templateSaveError`: "Couldn't save the template. Try again." / "No se pudo guardar la plantilla. Inténtalo de nuevo."
  - `templateDeleteError`: "Couldn't delete the template. Try again." / "No se pudo eliminar la plantilla. Inténtalo de nuevo."
  - `templateIconWeights` "Weights" / "Pesas", `templateIconRunning` "Running" / "Correr", `templateIconCycling` "Cycling" / "Ciclismo", `templateIconSwimming` "Swimming" / "Natación", `templateIconMartialArts` "Martial arts" / "Artes marciales", `templateIconGymnastics` "Gymnastics" / "Gimnasia", `templateIconYoga` "Yoga" / "Yoga", `templateIconTimer` "Timer" / "Temporizador".
- Both themes; no new tokens.

## Mockup

[mockup.html](../mockup.html): "Create form", "Create form, empty name after Save", "Edit form", "Delete confirmation dialog", "Save failed". Emoji there stand in for the `Icons.*` named here.

## Out of scope

- The "+" button, the long press and the limit snackbar (TPL-03-07).

## Files and tests

- New: the 4 `template_form_*` files in `lib/` and `custom_template_icon_name_extension.dart`.
- Unit: `template_form_view_model_test.dart`.
- Widget: `template_form_page_test.dart` (new; reason: popping, snackbars, the dialog flow and screen reader labels cannot be checked by goldens). Build a `GoRouter` with a start route that pushes `RoutePath.templateForm` with `TemplateFormArgs`, a `SettingsViewModel` on a fake settings repository (copy the private fake from `templates_view_model_test.dart`) and a `FakeCustomTemplateRepository`.
- Golden scenarios in `ui_snapshots_test.dart`, each building `TemplateFormPage(args: TemplateFormArgs(settingsViewModel: viewModel, template: …))` like the `templates_selected` scenario builds `TemplatesPage`:
  - `template_form_create`: create, current settings 0:10 / 1:30 / 0:15 / 3.
  - `template_form_name_error`: create, `whilePerforming: _tapInBothFrames(find.text('Save'))` (the helper the `setup_time_picker` scenario uses).
  - `template_form_edit`: edit "Tabata" (`custom-1`, `timer`, 0:10 / 0:20 / 0:10 / 8 rounds), stored with `configureFakeDependencies(customTemplates:)`.
  - `template_delete_dialog`: same as edit, `whilePerforming: _tapInBothFrames(find.byTooltip('Delete template'))`.
- Add the 4 rows and the `/template-form` route to `test/snapshots/README.md`.
- Run `fvm flutter gen-l10n` after editing both ARB files.

## Acceptance

- [ ] When the create form opens, then the name is empty, the icon is `weights` and the settings equal the current timer settings. Check: `test/features/templates/presentation/template_form_view_model_test.dart` "create starts from the current settings".
- [ ] When the edit form opens, then it has the template's name, icon and settings. Check: `test/features/templates/presentation/template_form_view_model_test.dart` "edit starts from the template".
- [ ] When Save runs with a blank or spaces-only name, then `hasNameError` is true, the result is `false` and nothing is saved; typing a name clears the error. Check: `test/features/templates/presentation/template_form_view_model_test.dart` "blank name is refused".
- [ ] When Save runs in create mode, then a template with the next `custom-<n>` id, the trimmed name, the icon and the form settings is appended. Check: `test/features/templates/presentation/template_form_view_model_test.dart` "create saves a new template".
- [ ] When Save runs in edit mode with changed values, then the template keeps its id and position and gets the new values. Check: `test/features/templates/presentation/template_form_view_model_test.dart` "edit replaces the template".
- [ ] When the form changes a setting, then the current timer settings do not change. Check: `test/features/templates/presentation/template_form_view_model_test.dart` "form values stay in the form".
- [ ] When the repository fails, then `save()` and `delete()` return `false` and the form state keeps the input. Check: `test/features/templates/presentation/template_form_view_model_test.dart` "failed write keeps the input".
- [ ] When `delete()` succeeds, then the template is gone from `customTemplates`. Check: `test/features/templates/presentation/template_form_view_model_test.dart` "delete removes the template".
- [ ] When Save succeeds on the page, then the form closes. Check: `test/features/templates/presentation/template_form_page_test.dart` "save closes the form".
- [ ] When Save fails on the page, then the snackbar "Couldn't save the template. Try again." shows and the form stays open with the typed name. Check: `test/features/templates/presentation/template_form_page_test.dart` "failed save keeps the form".
- [ ] When the delete dialog is confirmed and delete succeeds, then the form closes; when it fails, then the snackbar "Couldn't delete the template. Try again." shows; when it is cancelled, then the template is kept. Check: `test/features/templates/presentation/template_form_page_test.dart` "delete dialog flow".
- [ ] When a screen reader reads the edit form, then the delete icon is "Delete template" and each picker icon is a selectable button with its localized name, the chosen one selected. Check: `test/features/templates/presentation/template_form_page_test.dart` "form controls are labelled".
- [ ] When the create form is shown, then it matches the mockup in both themes. Check: `test/snapshots/goldens/template_form_create.png`.
- [ ] When Save is pressed with an empty name, then the field shows "Enter a name". Check: `test/snapshots/goldens/template_form_name_error.png`.
- [ ] When the edit form is shown, then the delete icon is in the app bar and the form has no delete button. Check: `test/snapshots/goldens/template_form_edit.png`.
- [ ] When the delete icon is tapped, then the dialog shows "Delete \"Tabata\"?", Cancel and Delete. Check: `test/snapshots/goldens/template_delete_dialog.png`.
- [ ] When the checks run, then everything passes, including `gen-l10n`. Check: `fvm dart tool/agent_check.dart --skip-build`.
