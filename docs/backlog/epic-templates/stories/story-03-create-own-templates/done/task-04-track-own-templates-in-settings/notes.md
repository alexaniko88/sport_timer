# Notes

## Summary

- `SettingsState` gains `customTemplates` and `selectedCustomTemplate`.
- `SettingsViewModel` takes a `CustomTemplateRepository`. Own templates load with the settings. A load failure is logged and leaves the list empty.
- A saved own selection is restored only when its settings still match. Changing a setting clears the own selection.
- New methods: `selectCustomTemplate`, `saveCustomTemplate` and `deleteCustomTemplate`. Saving replaces a template in place or appends it. At most 20 own templates are allowed. Deleting or editing the selected template clears the selection when needed.
- Template writes run one after another, so two overlapping saves keep both templates (fixed after review).
- `HomePage` passes the repositories through `getIt`.

## Evidence

- Own templates load in stored order: "loads own templates with the settings".
- A load failure leaves the list empty and the settings still load: "own template load failure keeps settings".
- A valid own selection restores, and a mismatch or unknown id gives no selection: "restores a valid own selection only".
- A built-in selection still restores: "built-in selection still restores".
- Selecting an own template saves its id: "selecting an own template saves its id".
- Changing a setting clears the own selection: "editing a setting clears the own selection".
- Saving a new template appends it: "saving a new template appends it".
- Editing keeps the position: "editing keeps the position".
- The 21st template is refused: "the 21st template is refused".
- Editing the selected template updates it or clears the selection: "editing the selected template updates or clears the selection".
- Deleting the selected template clears the selection: "deleting the selected template clears the selection".
- A failed write returns false and keeps the state: "failed template write keeps the state".
- No write happens after a failed load: "no write after a failed load".
- Overlapping saves keep both templates: "overlapping saves keep both templates".

## Points to review

- `lib/features/settings/presentation/settings_view_model.dart:167`: `if (result is Failure) return false;` uses a type check. The project style asks for `if-case` or `fold`. Minor.
- `lib/features/settings/presentation/settings_view_model.dart:132`: after an awaited template write, `_clearSelection()` runs without a `_disposed` check. A write that ends after dispose can still save timer settings. Minor.
- The write queue (`_enqueueTemplateWrite`) was added during the fix. It is small, but it goes beyond the task text.

Decisions during the run: none.

## Run

implementer: Claude Sonnet 5.5; tests: Claude Sonnet 5.5; reviewer: Claude Opus 5.5
