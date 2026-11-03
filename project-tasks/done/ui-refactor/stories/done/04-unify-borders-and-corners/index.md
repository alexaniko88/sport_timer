# STORY 4: Unify borders and corner radii across the app

Epic: [UI refactor](../../../index.md).

Status: Done on `improve/unify-borders-corners`; PR pending.

## User outcome

As a user, I want consistent corner shapes and border thickness across the app so that screens and controls feel like one product.

## Scope

- Cover corner radii and border widths throughout the app, including cards, buttons, inputs, dialogs, sheets, pickers, navigation surfaces and active-timer UI wherever these treatments exist.
- Establish shared rules by component role and state, then replace one-off values with the agreed shared treatment. Consistency does not require every component to have the same shape or an outline.
- Use the current Templates treatment and existing theme building blocks as the starting reference. The resulting values, state differences and exceptions are recorded below.
- Preserve light/dark support, visible selection and focus, clipping, hit areas and existing behavior.
- Exclude changes to colors, typography, spacing, navigation and features. Other UI stories retain ownership of their layouts and behavior; this story owns the shared radius and border-width rules.

## Acceptance criteria

- An agreed inventory maps existing component roles and states to shared radius and border-width rules, with any exceptions explained.
- All existing app screens and overlays follow those rules; equivalent components do not retain conflicting local values.
- Default, selected, focused, disabled and error states use the agreed rules wherever applicable, without layout jumps or lost state visibility.
- Light and dark themes remain usable, with no new clipping, overflow or behavior changes.

## Component inventory and shared rules

The shared values and exceptions below were delivered by [IMP-01](../../../../../improvements/done/01-unify-styles-app-wide.md), merged in PR #42. Definitions live in `lib/shared/presentation/theme/app_spacing.dart`, `sport_theme.dart`, and `widgets/app_surface.dart`. The drawer treatment was completed on this story's branch.

| Component and locations | Radius and border treatment |
| --- | --- |
| Setup cards and Start surface, selected template shortcut, Templates tiles, Statistics cards, Timer styles tiles | `AppSurface`: 12 radius, 1 border normally and 2 when selected. Selection reduces inner padding to preserve size; an optional border color distinguishes a custom template. Focus does not change border width. |
| Rectangular primary, secondary and text buttons, including Login and Statistics Retry | Theme shape uses 12 radius; outlined `AppButton.secondary` uses a 1 border. Disabled and focused states do not introduce a different border width. |
| Account sign-out dialog and account/picker sheets | Dialogs use 20 radius; modal sheets use 20 on their upper corners. Picker sheet repeats that shape for its own clipping. |
| Picker wheel items | 8 radius, 1 phase-colored border on highlighted items; the phase color is an intentional exception. |
| Home navigation drawer | 20 radius on the trailing outer edge, direction-aware; its Material destination indicator remains pill-shaped. Bottom navigation and separators use their framework treatment. |
| Timer phase chip, template phase bar and rounds strip | Intentional pill shapes; active timer's circular ring and pause control remain circular. Full-color timer has no bordered card. |
| Timer style preview frame | Intentional preview-frame exception, using a 20-radius clip and its own display proportions. |
| Account avatar and icon controls | Circular shape; framework icon-button state and focus behavior remain intact. |
| Snackbars | Framework shape and state treatment; no custom app border. Login and account errors and the timer recording notice use snackbars. |
| Text inputs and outlined error states | No text input fields are present in the current app. Do not infer a new input rule from absent controls. |

Colors, typography and layouts remain outside this story. There are no pending UI layout requirements to migrate: Stories 1–3 are archived. The existing state distinctions and both themes are retained; these rules do not add an outline to every control.

## Tasks

1. [Audit and agree shared border and radius rules](done/01-agree-border-and-radius-rules.md) — Done.
2. [Apply shared border and radius rules app-wide](done/02-apply-border-and-radius-rules.md) — Done.

## Dependencies and open decisions

The [styling improvement](../../../../../improvements/done/01-unify-styles-app-wide.md) delivered the shared radius and border rules in PR #42. This story records the inventory and completes the drawer treatment. Its implementation, test results and review evidence are recorded in the archived tasks. The branch's PR is pending.
