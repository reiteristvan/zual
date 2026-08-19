# Coding Conventions

**Analysis Date:** 2026-08-19 (v1.0 shipped)

These are the conventions actually observed across `lib/` and `test/`, not generic Dart
style advice. Where the codebase deviates from a common Flutter default, the reason is
noted — those deviations are deliberate and should be preserved.

## Naming Patterns

**Files:**
- `snake_case.dart` for every source file
- One primary class per file, named after the file: `timer_controller.dart` →
  `TimerController`, `hold_repeat_button.dart` → `HoldRepeatButton`
- Scenes come in pairs under a per-scene folder: `lib/scenes/disc/disc_scene.dart` (the
  widget) + `disc_painter.dart` (the `CustomPainter`). Same shape for `sunrise/`, `walk/`,
  `car/`.
- Tests mirror the source path and append `_test`: `lib/timer/timer_controller.dart` →
  `test/timer/timer_controller_test.dart`
- **Developer tools under `test/tool/` deliberately avoid the `_test.dart` suffix when they
  write files** (`generate_feature_graphic.dart`), so a plain `flutter test` never
  discovers and re-runs them. Non-writing helpers (`icon_renderer.dart`,
  `icon_painters.dart`) and shared test utilities (`test/support/progress_sweep.dart`) also
  go without the suffix.

**Classes:**
- `PascalCase`. Widgets are named for what they are (`SetupScreen`, `SceneCard`,
  `PressableSurface`), not suffixed with `Widget`.
- Private `State` classes use the `_ClassNameState` convention: `_SetupScreenState`.
- Platform adapters are named `<Plugin><Interface>`: `WakelockScreenWake`,
  `AudioplayersChimePlayer`. Their test doubles are `Noop<Interface>`: `NoopScreenWake`,
  `NoopChimePlayer`. Test-local fakes use the `Fake<Interface>` prefix: `FakeScreenWake`.
- `AppTokens` is an `abstract class` used purely as a namespace for `static const` values —
  never instantiated, never extended.

**Functions and variables:**
- `camelCase`; leading `_` for anything private to the file.
- File-private constants are `_lowerCamelCase` with a leading underscore and a doc comment:
  `const int _minMinutes = 1;`, `const String _durationMinKey = 'durationMin';`
- Public compile-time constants in tool files use the `k` prefix: `kFeatureGraphicSize`,
  `kHeroProgress`.

**Types:**
- Explicit return types on every function, including `build`.
- `final` for anything not reassigned; `const` constructors wherever possible.
- Widget constructors use named parameters with `required` and `super.key`.

## Code Style

**Formatting:**
- `dart format` defaults — 2-space indent, ~80-column target. The codebase holds to this:
  only 13 lines in all of `lib/` exceed 80 characters, and the longest is 88.
- Trailing commas are used to force the formatter into one-argument-per-line layouts for
  widget trees.

**Linting:**
- `flutter_lints` 6.0.0, included via `analysis_options.yaml`
  (`include: package:flutter_lints/flutter.yaml`). The `linter.rules` block is present but
  empty — no rule has been added or suppressed.
- `flutter analyze` is expected to report **zero** issues; it does as of 2026-08-19.
- No `// ignore:` or `// ignore_for_file:` directives exist anywhere in `lib/`. Keep it that
  way — fix the code rather than silencing the analyzer.

## Import Organization

**Order** (blank line between groups):
1. `dart:` imports — `dart:async`, `dart:math`, `dart:typed_data`, `dart:ui`
2. `package:` imports — `package:flutter/...`, then third-party (`package:provider/...`)
3. Local imports

**Local import style — note the split:**
- **Inside `lib/`, use relative imports** (`import '../timer/timer_controller.dart';`).
  This is the established convention throughout the app code and the opposite of the usual
  "always use `package:`" advice — follow the codebase, not the general guidance.
- **Inside `test/`, use `package:zual/...` absolute imports** for the code under test
  (`import 'package:zual/timer/timer_controller.dart';`), with relative imports reserved for
  test-local helpers (`import '../support/progress_sweep.dart';`).

**Flutter import granularity:** import `package:flutter/widgets.dart` rather than
`material.dart` where Material components are not actually used — most scenes, painters,
and the timer layer do this. Only files that use Material widgets import `material.dart`.

## Error Handling

**Philosophy:** fail soft. Nothing user-visible ever surfaces an error — a child-facing
timer showing an error dialog is worse than one quietly falling back to defaults.

**Patterns:**
- **Validate untrusted reads at the boundary, on every read.** `SetupPreferences.load()`
  clamps `durationMin` into 1–120, resolves the theme with
  `SceneTheme.values.firstWhere(..., orElse: ...)`, and wraps each `getInt`/`getString` in
  its own try/catch because those perform an unchecked cast and throw `TypeError` on a
  wrong-typed stored value.
- **Defense in depth at the composition root.** `main()` additionally wraps the whole
  preference load in a catch-all fallback, so launch cannot fail on *any* unexpected
  preference error.
- **Clamp at the single write path,** independently of UI state. `_setCustomMin` clamps to
  1–120 regardless of whether the caller thinks a stepper button is disabled;
  `TimerController.start` clamps its `minutes` argument again.
- **Make illegal transitions no-ops** rather than throwing: `pause()` returns early unless
  running, `resume()` unless paused.
- **Latch one-shot side effects.** Both the completion chime and `Navigator.pop()` are
  guarded by booleans so a rebuild or a second exit path cannot fire them twice.
- Null safety is used plainly: `?.`, `??`, and nullable fields over `late` (`late` appears
  only where genuinely needed).

## Logging

**None.** There is no logging framework, and `lib/` contains no `print`, `debugPrint`, or
logging calls at all. The app collects and emits nothing — consistent with the privacy
posture in `docs/index.html`. If diagnostics are ever needed, add them behind a debug-only
guard rather than shipping unconditional output.

## Comments

**Density:** high, and deliberately so. Dartdoc on public classes, fields, and non-obvious
methods is the norm, not the exception — many files open with a multi-paragraph `///` block
explaining the design contract.

**What comments must do:** explain *why*, and cite the decision that made it so. The
codebase consistently references planning identifiers inline:
- Locked decisions — `(D-01)`, `(D-09)`, `(D-10)`
- Threat model entries — `(T-02-02)`, `(T-04-06)`
- Plans, research, reviews, and specs — `Plan 04-05`, `04-RESEARCH.md Pattern 2`,
  `05-REVIEW.md WR-04`, `UI-SPEC`
- Requirement IDs — `PERSIST-01`, `SETUP-02`, `CTRL-04`

Keep this up. It is what makes a non-obvious choice (wall-clock over `Stopwatch`,
accumulated durations over a wall-clock read in `HoldRepeatButton`, a 440 px content cap on
Setup) auditable years later without re-reading the planning archive.

**Style:**
- `///` for anything public or contract-bearing; `//` for local asides
- Prose sentences, not `@param`/`@return` tags — reference other symbols with `[Brackets]`
- Document the *reason a default exists* on injected parameters, e.g. "this literal default
  only applies to callers (e.g. widget tests) that construct `MyApp` directly"

## Function Design

**Size:** small and single-purpose. Long `build` methods are decomposed into private
`_buildX()` helpers on the `State` class (`_buildPresetCard`, `_buildCustomCard`) rather
than left inline.

**Parameters:**
- Named parameters throughout for widgets and controllers; `required` for mandatory ones
- `super.key` in constructor delegation, never `key: key`
- **Constructor injection for everything testable.** `TimerController` accepts `clock`,
  `tickInterval`, and `screenWake`; `MyApp`/`SetupScreen`/`RunningScreen` accept
  `chimePlayer`, `soundOn`, `initialDurationMin`, `initialTheme`. Each defaults to the
  production value or a no-op double, so tests construct real widgets without platform
  channels or real elapsed time.

**Single write path:** where a value has invariants, funnel all mutation through one private
setter that enforces them (`_setCustomMin`), rather than clamping at each call site.

**Return values:** explicit types everywhere; `Future<void>` for async; `void` for
side-effecting methods.

## Module Design

**Organization:** `lib/` is grouped by concern, not by widget/model/service layer:

```
lib/
  audio/     chime synthesis + player interface and adapters
  scenes/    scene contract, registry, theme enum, previews, one folder per scene
  screens/   SetupScreen, RunningScreen
  settings/  SetupPreferences
  theme/     AppTokens
  timer/     TimerController, TimerPhase, lifecycle binder, screen-wake
  widgets/   shared reusable UI
  main.dart  composition root
```

**Exports:** no barrel files. Every import names the specific file it needs. Adding one
would obscure the dependency edges the architecture depends on.

**Dependency rules that must hold:**
- **One plugin import per plugin.** `wakelock_plus`, `shared_preferences`, and
  `audioplayers` are each imported by exactly one file. Everything upstream depends on a
  plugin-free interface. Adding a second import site breaks widget testability.
- **`sceneFor()` is the only place allowed to name a concrete scene widget by type.**
  `RunningScreen` depends on the registry, never on `DiscScene` et al., so new scenes never
  require touching it. `SceneGrid` follows the same rule for preview painters via the
  `ScenePreviewPainter` abstraction.
- **Painters stay pure.** A scene painter is a function of `(progress, loopPhase)` and
  reads no controller and holds no state.
- **No hardcoded design values.** Colors, radii, shadows, and text styles come from
  `AppTokens`. New tokens go in that file, transcribed from `design/README.md`.
- **Reuse `PressableSurface`** for any tappable surface rather than reaching for
  `ElevatedButton` — plain Material buttons do not apply the locked pressed-state colors.

## Testing Conventions

- `test/` mirrors `lib/` directory for directory: 21 `_test.dart` files plus 4 non-suffixed
  helpers/generators, ~2,846 LOC, 134 tests.
- Widget tests build real widgets with injected doubles — no mocking framework is used, and
  none should be added; hand-written `Fake*` classes implementing the interface are the norm.
- Time-dependent logic is tested by injecting a fake `clock` and pumping fake timers, never
  by sleeping. `HoldRepeatButton` accumulates scheduled durations rather than reading a wall
  clock specifically so it stays deterministic under `tester.pump(duration)`.
- `test/support/progress_sweep.dart` holds shared helpers for sweeping a painter across the
  0..1 progress range — the standard way scene painters are exercised.
- Test names carry the requirement or threat ID they cover, matching the comment convention.

---

*Convention analysis: 2026-08-19*
