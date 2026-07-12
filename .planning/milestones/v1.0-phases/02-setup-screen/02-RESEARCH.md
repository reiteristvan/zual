# Phase 2: Setup Screen - Research

**Researched:** 2026-07-07
**Domain:** Flutter UI (first screen-building phase) — gesture handling, CustomPainter, local persistence, offline font bundling
**Confidence:** MEDIUM-HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

- **D-01:** Start navigates to a minimal, inert placeholder running screen — full-screen,
  no text/numbers (consistent with the child-facing constraint even as a stub). It shows
  progress advancing over time via a plain shrinking-circle style indicator, with no color
  zones or polish (that refinement belongs to Phase 3's real Shrinking Disc theme).
- **D-02:** The placeholder has one small, always-visible escape hatch (e.g. a plain
  top-left back control) that calls `TimerController.endTimer()` and returns to Setup. This
  is explicitly not the real Parent Controls UX (hidden 850ms long-press, bottom sheet) —
  that's Phase 4's job. It exists only so the screen is usable/testable before Phase 4 lands.
- **D-03:** No long-press gesture, no bottom sheet, no pause/resume affordance in this
  phase's placeholder — completely out of scope until Phase 4.
- **D-04:** When the controller reaches `TimerPhase.done`, the placeholder auto-navigates
  back to Setup. No chime, no "All done" pill (Phase 4 scope) — just close the loop simply.
- **D-05:** Build simplified static mini-previews for each of the 4 scene cards (74px per
  design) — not animated, but visually representative of each theme at rest: a solid green
  circle for Disc, a small night→day gradient swatch for Sunrise, a tiny ground+house
  silhouette for Walk, a tiny road+car silhouette for Car. Use the exact colors from
  `design/README.md`'s Design Tokens section for each.
- **D-06:** Structure each mini-preview as its own isolated painter/widget per theme (not
  inlined into the grid/card layout code), so Phase 3 can later swap in "render the real
  scene painter at progress=0, scaled to 74px" without touching the Setup screen's card or
  grid code. The Setup screen should depend on a per-theme preview abstraction, not on each
  theme's literal implementation details.
- **D-07:** Tapping − or + changes the value by exactly 1 minute. Holding either button
  repeats and accelerates the rate the longer it's held, so reaching either end of the
  1–120 range doesn't require up to 119 individual taps.
- **D-08:** The − button disables (visually greyed, non-interactive) at 1 minute; the +
  button disables at 120 minutes. Clear affordance that the range edge has been reached.
- **D-09:** On a very first launch (no persisted "last used" value yet), the Shrinking Disc
  theme is pre-selected by default — it's the design doc's designated anchor/hero scene, a
  low-surprise default. Default duration remains 5 min per the design spec.
- **D-10:** Persistence (PERSIST-01) only remembers preset durations and the last-used
  theme. If a Custom value was last used, relaunching does NOT reopen the custom stepper
  with that exact value — it falls back to the nearest/default preset instead. Simpler
  persisted state; "last used" is scoped to presets only.

### Claude's Discretion

- Persistence mechanism (`shared_preferences` vs alternative local key-value storage) — a
  technical implementation detail, not a product decision.
- Font bundling approach for Baloo 2 + Quicksand (bundled asset fonts vs a fonts package) —
  technical detail; app should work fully offline so prefer an approach that doesn't require
  network access at runtime.
- Exact shape/geometry of the placeholder running screen's progress indicator, as long as it
  reads as "a shrinking circle" and shows zero text/numbers.
- Exact "nearest preset" fallback logic when Custom was last used (e.g., round to closest of
  1/5/10/15/30, or always fall back to the 5-min default) — an edge-case detail, not a
  product-facing gray area the user needs to weigh in on.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. (Real Parent Controls, chime, and completion
pill were explicitly named as Phase 4 concerns during discussion, not folded into Phase 2.)
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SETUP-01 | Parent can pick a duration from presets (1, 5, 10, 15, 30 min) | Standard Stack / Architecture Patterns — `Wrap`/`GridView` of tappable cards with local `int durationMin` state, selection ring per Color section |
| SETUP-02 | Parent can pick a custom duration (1–120 min) via a stepper | Common Pitfalls #1, Code Examples "Hold-Repeat Stepper Button" — GestureDetector `onTap`/`onLongPressStart` pattern, disposal rules |
| SETUP-03 | Parent can pick one of 4 visual scene themes via thumbnail cards | Don't Hand-Roll (n/a — no package fits); Architecture Patterns "Scene Preview Abstraction" (D-06) |
| SETUP-04 | Parent starts the timer with a single Start button showing the selected duration | Existing Code Insights — `TimerController.start(minutes)` already exposed; Architectural Responsibility Map |
| SETUP-05 | Setup screen matches Layout A pixel-accurately | 02-UI-SPEC.md is the source of truth; this research does not re-derive visual values, only implementation mechanics (fonts, painters, tokens file) |
| PERSIST-01 | App remembers last-used duration and theme, pre-selects on next launch | Standard Stack (`shared_preferences` 2.5.5), Code Examples "Preload Prefs Before First Frame", Common Pitfalls #3 |
</phase_requirements>

## Summary

This is the first screen-building phase in an otherwise headless (state-machine-only) Flutter
codebase — `lib/main.dart` is still the generated counter-app scaffold, and `lib/` has no
`screens/`, `widgets/`, or `theme/` directories yet. Everything researched here is about
*introducing* Flutter UI-layer conventions on top of the existing `TimerController`
(`ChangeNotifier`, already wired via `provider`), not about the timer logic itself, which
Phase 1 already completed and this phase must not touch.

Four mechanically distinct problems drive this phase's plan: (1) a custom accelerating
hold-repeat stepper button, for which Flutter's `GestureDetector` long-press family turns out
to line up almost exactly with the UI-SPEC's 500ms threshold, letting a single-tap-vs-hold
distinction fall out of the framework for free rather than needing manual down/up timestamp
tracking; (2) a `CustomPainter`-based abstraction for the four scene mini-previews, which is a
natural fit since `CustomPainter` is already an abstract class Phase 3 can subclass identically
later; (3) `shared_preferences` (confirmed current at 2.5.5 against the live pub.dev registry)
for the two scalar persisted values, read once at launch before `runApp`; and (4) local
`.ttf` font asset bundling in `pubspec.yaml`, which needs no new package at all.

**Primary recommendation:** Establish `lib/screens/`, `lib/widgets/`, `lib/theme/` now (per
`STRUCTURE.md`'s already-suggested layout); add `shared_preferences` as the only new
dependency; hand-roll the stepper and scene-preview widgets (no pub.dev package fits either
need); bundle fonts as local assets, not `google_fonts`.

## Architectural Responsibility Map

Tiers below are adapted for a single-process Flutter mobile app (no client/server split):
**UI Widget Layer** (widgets, gestures, painters), **App State Layer** (`ChangeNotifier`
controllers), **Local Persistence Layer** (`shared_preferences`), **Platform/OS Layer**
(Android font rendering, wakelock — already handled by Phase 1, not touched here).

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Preset/custom duration selection | UI Widget Layer | — | Pure local widget state (`durationMin`, `customMin`, `showCustom`); never touches `TimerController` until Start is pressed |
| Hold-repeat stepper acceleration | UI Widget Layer | — | Self-contained `GestureDetector` + `Timer` inside one stateful widget; no app-state or persistence involvement |
| Scene theme selection | UI Widget Layer | — | Local `theme` enum state on the Setup screen |
| Scene mini-preview rendering (D-05/D-06) | UI Widget Layer | — | `CustomPainter` subclasses; Phase 3 will later point the same call site at real scene painters — still UI-layer only |
| Start → launch timer | App State Layer | UI Widget Layer | `TimerController.start(minutes)` (already implemented in Phase 1) is the actual state transition; the Setup screen's button is just the trigger |
| Placeholder running screen progress | App State Layer | UI Widget Layer | Reads `TimerController.phase`/`progress`, which Phase 1 already computes from wall-clock elapsed time — this phase only renders it |
| Last-used duration + theme persistence (PERSIST-01) | Local Persistence Layer | UI Widget Layer | `shared_preferences` owns the read/write; the Setup screen's `initState`/`main()` sequencing owns *when* it's read |
| Screen wake during running | Platform/OS Layer (via App State) | — | Already fully implemented in Phase 1 (`WakelockScreenWake`, paired to phase transitions) — **out of scope for this phase**, do not re-touch |

**Sanity check for the planner:** nothing in this phase should add new logic to
`TimerController` or `TimerLifecycleBinder` — SETUP-04's "Start" behavior is a one-line call
into the existing public API. If a plan task proposes modifying `timer_controller.dart`,
that is a signal the task is scoped wrong for this phase.

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `shared_preferences` | `^2.5.5` [VERIFIED: pub.dev registry via `flutter pub add --dry-run`] | Persist last-used preset duration (int) + theme (String/enum name) (PERSIST-01) | Official Flutter-team package (`flutter/packages` monorepo, verified publisher `flutter.dev`), the de facto standard for "a small amount of simple data" per its own pub.dev description — anything heavier (Hive, sqflite, Isar) is unjustified for two scalars |
| `provider` | `^6.1.5+1` (already in `pubspec.yaml`) | Expose `TimerController` to the Setup and placeholder Running screens | Already adopted in Phase 1; this phase is a consumer only (`context.watch<TimerController>()` / `context.read<TimerController>()`), no new DI plumbing |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `flutter` SDK (`Material` widgets) | bundled (Flutter 3.38.7 / Dart 3.10.7, both confirmed installed via `flutter --version`) | Structural primitives only (`Scaffold`, `GestureDetector`, `CustomPaint`) | Per UI-SPEC: every visual property is overridden by design tokens; Material is used for behavior/semantics, not its default look |
| Material Icons (already `uses-material-design: true`) | bundled | `Icons.arrow_back` on the placeholder Running screen's escape hatch | No new package — already available |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `shared_preferences` | `hive` / `sqflite` / `Isar` | All are overkill for two scalar values (an int and a short string); add build-step or native-binding complexity PERSIST-01 doesn't need |
| Hand-rolled `GestureDetector` + `Timer` stepper | pub.dev packages like `number_inc_dec`, `count_stepper`, `stepper_a` | [VERIFIED: pub.dev search] None expose a custom accelerating 500ms→2s→4s curve with fully custom pixel-accurate visuals; adopting one would mean fighting its own widget tree to match the design spec exactly. Confirmed no exact-fit package exists — hand-rolling here is the *correct* call, not a shortcut being skipped |
| Local bundled `.ttf` fonts | `google_fonts` package | `google_fonts` defaults to runtime HTTP fetch of font files on first use; while it has an "offline"/`LicenseRegistry` + local-asset mode, it adds a dependency and indirection for something `pubspec.yaml`'s native `fonts:` section does directly. Locked by Claude's Discretion note in CONTEXT.md ("must work fully offline") |

**Installation:**
```bash
flutter pub add shared_preferences
```
(Resolves to `shared_preferences: ^2.5.5` plus platform-implementation transitive packages —
confirmed via `flutter pub add shared_preferences --dry-run` against the live pub.dev registry
in this session; no other new direct dependency is needed for this phase.)

**Version verification:** `flutter pub add <pkg> --dry-run` was run against the live pub.dev
registry in this research session (equivalent to `npm view` for the pub ecosystem) — output
confirmed `shared_preferences 2.5.5` resolves cleanly against this project's existing
`pubspec.yaml` constraints with no version conflicts.

## Package Legitimacy Audit

> The `package-legitimacy check` seam only supports `npm|pypi|crates` ecosystems; Dart/pub is
> not covered. Verification below was done manually against the pub.dev registry and its
> official metadata, which is the closest equivalent available.

| Package | Registry | Age | Downloads/Popularity | Source Repo | Verdict | Disposition |
|---------|----------|-----|----------------------|--------------|---------|-------------|
| `shared_preferences` | pub.dev | Long-established Flutter-team package (part of the `flutter/packages` monorepo) | 10.5k likes / 160 pub points [CITED: pub.dev package page, fetched this session] | `github.com/flutter/packages/tree/main/packages/shared_preferences/shared_preferences` | OK | Approved |

**Packages removed due to [SLOP] verdict:** none
**Packages flagged as suspicious [SUS]:** none

No other new external packages are introduced by this phase's plan. `provider`, `flutter`,
Material Icons, and `wakelock_plus` are already present in `pubspec.yaml` from Phase 1 and are
consumed, not newly installed.

## Architecture Patterns

### System Architecture Diagram

```
                         ┌─────────────────────────────┐
                         │        main() / app root      │
                         │  (reads persisted prefs once   │
                         │   before runApp — see Pitfall  │
                         │   #3 for why this matters)      │
                         └───────────────┬────────────────┘
                                          │ initial durationMin, theme
                                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                          SetupScreen (widget)                    │
│                                                                    │
│  ┌────────────────────┐        ┌────────────────────────────┐    │
│  │ Duration section    │        │ Scene section               │    │
│  │ - preset grid taps  │        │ - 4 scene cards, tap-select │    │
│  │ - Custom → stepper  │        │ - each card renders one     │    │
│  │   (HoldRepeatButton │        │   ScenePreviewPainter via   │    │
│  │    × 2, D-07/D-08)  │        │   the shared abstraction    │    │
│  └─────────┬───────────┘        └─────────┬───────────────────┘    │
│            │ local widget state            │ local widget state    │
│            └───────────────┬────────────────┘                       │
│                             ▼                                       │
│                    Start button (always enabled)                    │
└─────────────────────────────┬─────────────────────────────────────┘
                               │ TimerController.start(minutes)   [SETUP-04]
                               │ + persist chosen preset/theme     [PERSIST-01]
                               ▼
                  ┌─────────────────────────────┐
                  │   TimerController (Phase 1)   │  ← existing, untouched
                  │   phase / progress getters     │
                  └───────────────┬────────────────┘
                                  │ context.watch<TimerController>()
                                  ▼
                  ┌─────────────────────────────┐
                  │  PlaceholderRunningScreen      │
                  │  - shrinking circle = progress │
                  │  - back control → endTimer()   │  [D-02]
                  │  - phase==done → pop to Setup  │  [D-04]
                  └─────────────────────────────┘
```

### Recommended Project Structure

```
lib/
├── main.dart                      # app root; now also loads persisted prefs before runApp
├── theme/
│   └── app_tokens.dart            # colors/spacing/radii/text-style constants from UI-SPEC
├── screens/
│   ├── setup_screen.dart          # SETUP-01..05 — Layout A
│   └── placeholder_running_screen.dart   # D-01..D-04 stand-in Start destination
├── widgets/
│   ├── hold_repeat_button.dart    # SETUP-02/D-07/D-08 — accelerating −/+ stepper button
│   ├── duration_grid.dart         # SETUP-01 — preset + Custom card grid
│   └── scene_grid.dart            # SETUP-03 — 2×2 scene card grid, hosts scene previews
├── scenes/
│   └── scene_preview.dart         # D-06 — shared preview abstraction + 4 concrete painters
├── settings/
│   └── setup_preferences.dart     # PERSIST-01 — shared_preferences read/write wrapper
└── timer/                         # Phase 1 — do not modify
    ├── screen_wake.dart
    ├── timer_controller.dart
    ├── timer_lifecycle_binder.dart
    ├── timer_phase.dart
    └── wakelock_screen_wake.dart
```

This matches `.planning/codebase/STRUCTURE.md`'s already-suggested `lib/screens/`,
`lib/widgets/` layout; `theme/`, `scenes/`, and `settings/` are new subdirectories this phase
introduces, chosen to keep each new responsibility (tokens, per-theme previews, persistence)
in its own file rather than growing `setup_screen.dart` into a monolith (function/module-size
conventions in `CONVENTIONS.md`).

### Pattern 1: Hold-Repeat Stepper via GestureDetector's Long-Press Family

**What:** Use `GestureDetector.onTap` for a single ±1 step and
`onLongPressStart`/`onLongPressEnd`/`onLongPressCancel` to drive a self-rescheduling `Timer`
for the accelerating repeat, instead of manually tracking `onTapDown`/`onTapUp` timestamps.

**When to use:** Any button needing "tap = one step, hold = repeat" behavior where the
hold-recognition threshold can be ~500ms (Flutter's `LongPressGestureRecognizer` default,
`kLongPressTimeout`) — which is exactly the UI-SPEC's own first threshold. `onTap` and the
long-press callbacks are mutually exclusive per gesture (Flutter's gesture arena resolves to
at most one recognizer per pointer sequence), so a quick release naturally fires `onTap` only,
and a hold past 500ms naturally fires `onLongPressStart` instead — the single-tap-vs-hold
split falls out of the framework rather than needing hand-tracked timestamps.
[CITED: api.flutter.dev — `GestureDetector.onLongPressStart`, `LongPressGestureRecognizer`]

**Example:**
```dart
// Source: pattern synthesized from Flutter GestureDetector long-press API
// (api.flutter.dev) — no single official recipe covers the acceleration curve,
// which is UI-SPEC-specific and hand-rolled here.
class HoldRepeatButton extends StatefulWidget {
  const HoldRepeatButton({
    super.key,
    required this.onStep,
    required this.enabled,
    required this.child,
  });

  final VoidCallback onStep;
  final bool enabled;
  final Widget child;

  @override
  State<HoldRepeatButton> createState() => _HoldRepeatButtonState();
}

class _HoldRepeatButtonState extends State<HoldRepeatButton> {
  Timer? _repeatTimer;
  DateTime? _holdStart;

  static const _initialInterval = Duration(milliseconds: 350); // held > ~500ms
  static const _midInterval = Duration(milliseconds: 150);     // held > ~2s
  static const _fastInterval = Duration(milliseconds: 60);     // held > ~4s

  Duration _currentInterval() {
    final start = _holdStart;
    if (start == null) return _initialInterval;
    final held = DateTime.now().difference(start);
    if (held >= const Duration(seconds: 4)) return _fastInterval;
    if (held >= const Duration(seconds: 2)) return _midInterval;
    return _initialInterval;
  }

  void _scheduleNextTick() {
    _repeatTimer?.cancel();
    _repeatTimer = Timer(_currentInterval(), () {
      if (!widget.enabled) {
        _stopRepeating();
        return;
      }
      widget.onStep();
      _scheduleNextTick(); // re-check interval every tick so it can accelerate mid-hold
    });
  }

  void _startRepeating() {
    _holdStart = DateTime.now();
    widget.onStep(); // the step that coincides with onLongPressStart firing (~500ms mark)
    _scheduleNextTick();
  }

  void _stopRepeating() {
    _repeatTimer?.cancel();
    _repeatTimer = null;
    _holdStart = null;
  }

  @override
  void dispose() {
    _repeatTimer?.cancel(); // see Common Pitfalls #1 — the #1 leak/crash source here
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.enabled ? widget.onStep : null,
      onLongPressStart: widget.enabled ? (_) => _startRepeating() : null,
      onLongPressEnd: (_) => _stopRepeating(),
      onLongPressCancel: _stopRepeating,
      child: widget.child,
    );
  }
}
```
The parent (stepper row) owns clamping/disabling per D-08 by passing `enabled: customMin > 1`
(for −) / `enabled: customMin < 120` (for +) and a no-op-safe `onStep` — this widget never
needs to know about the 1–120 range itself.

### Pattern 2: Scene Preview Abstraction (D-05/D-06)

**What:** One shared abstract type all four preview painters implement, so
`SceneGrid`/`SceneCard` depends only on the abstraction — matching the requirement that Phase 3
can later swap in "the real scene painter rendered at progress=0" without touching this
phase's grid/card layout code.

**When to use:** Exactly this situation — a widget needs to render one of N visually distinct
but interface-identical things, and a future phase will swap the implementations.

**Example:**
```dart
// Source: pattern built on Flutter's own CustomPainter contract
// (docs.flutter.dev/cookbook/design — CustomPainter.paint/shouldRepaint)
abstract class ScenePreviewPainter extends CustomPainter {
  const ScenePreviewPainter();
  // No extra members needed yet — CustomPainter's own paint(Canvas, Size) and
  // shouldRepaint(oldDelegate) are the entire contract. Keeping this as a thin
  // marker subclass (rather than a bespoke interface) means Phase 3's real
  // scene painters can extend ScenePreviewPainter directly instead of Setup
  // screen code needing to know about two different painter families.
}

class DiscPreviewPainter extends ScenePreviewPainter {
  const DiscPreviewPainter();

  @override
  void paint(Canvas canvas, Size size) {
    // flat #F3E8D6 background + centered 44px #7FA87A circle, per UI-SPEC
  }

  @override
  bool shouldRepaint(covariant DiscPreviewPainter oldDelegate) => false; // static, D-05
}

// SunrisePreviewPainter, WalkPreviewPainter, CarPreviewPainter follow the same shape.

// The grid/card layout code only ever depends on the abstraction:
class SceneCard extends StatelessWidget {
  const SceneCard({super.key, required this.preview, required this.label, /* ... */});
  final ScenePreviewPainter preview;
  final String label;
  // build() uses CustomPaint(painter: preview, size: const Size.fromHeight(74)), never
  // references DiscPreviewPainter/etc. by name.
}
```
Phase 3 satisfies D-06 by adding a `SceneRenderer.previewAt(progress: 0)`-style adapter that
also extends `ScenePreviewPainter`, and swapping which concrete instance `SceneCard` is given —
zero changes to `SceneCard`, `SceneGrid`, or `SetupScreen`.

### Anti-Patterns to Avoid

- **Reaching into `TimerController` from inside stepper/scene-selection widgets:** Duration and
  theme selection are pure Setup-screen-local state until Start is pressed (see Architectural
  Responsibility Map). Only the Start button's `onPressed` should touch `TimerController`.
- **Modifying `timer_controller.dart`, `timer_lifecycle_binder.dart`, or
  `wakelock_screen_wake.dart` for this phase:** Phase 1 already implements everything this
  phase needs from the timer/wake layer (`start`, `endTimer`, `phase`, `progress`, wake
  enable/disable paired to phase transitions). If a plan task touches these files, it is
  out of scope.
- **Wrapping the whole Setup screen in a single 300-line `build()` method:** `CONVENTIONS.md`
  calls for extracting helpers past ~30 lines; the recommended structure above already splits
  duration grid, scene grid, and stepper into separate widget files for this reason.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Reading/writing a couple of persisted scalar settings | A hand-rolled file-based key-value store, or raw `dart:io` file reads | `shared_preferences` | Cross-platform-correct, battle-tested, already the ecosystem standard for exactly this scope; a hand-rolled version would need to reinvent platform-specific storage backends for no benefit |
| Font weight/family switching | Manual `.ttf` parsing or a custom text-rendering shim | `pubspec.yaml`'s native `flutter: fonts:` declaration + `TextStyle(fontFamily:, fontWeight:)` | This is a first-class SDK feature; there is nothing to hand-roll here at all |

**Key insight:** the two things this phase *should* hand-roll — the accelerating stepper
button and the scene-preview abstraction — are hand-rolled precisely because pub.dev has
no package matching the pixel-accurate, custom-curve requirements (confirmed via pub.dev
search this session), and inventing a plugin-abstraction layer for a 4-variant, in-app-only
preview concept would be over-engineering relative to a shared base class extending
`CustomPainter`. Everything else (persistence, fonts) has an off-the-shelf, standard answer
and should not be hand-rolled.

## Common Pitfalls

### Pitfall 1: Repeat `Timer` outlives its widget
**What goes wrong:** The accelerating repeat `Timer` keeps firing after the user has
navigated away or the widget has otherwise been disposed, causing a `setState()` called after
dispose exception (or, in release builds, a silent leak that keeps incrementing/decrementing
state no one reads anymore).
**Why it happens:** `onLongPressEnd`/`onLongPressCancel` cover a normal release, but they do
not cover the widget being torn down mid-hold (e.g. the user backgrounds the app or the Custom
row is closed by selecting a preset while still holding − or +).
**How to avoid:** Cancel the `Timer` in *both* the long-press end/cancel handlers **and** in
`State.dispose()` — never assume one path is sufficient. Prefer `Timer` (single-shot,
rescheduled) over `Timer.periodic` for the accelerating case, since a fixed-interval
`Timer.periodic` can't change its own interval — cancel-and-reschedule is required either way,
so a self-rescheduling single-shot `Timer` is simpler than fighting `Timer.periodic`.
**Warning signs:** "setState() called after dispose()" in debug console; stepper value still
changing after the Custom row visually closes.

### Pitfall 2: Selecting a preset while the Custom stepper is mid-hold
**What goes wrong:** Per the Interaction Contract, selecting a preset button closes (hides)
the Custom row. If the − or + button is actively repeating when that happens, its `Timer`
must stop even though neither `onLongPressEnd` nor `onLongPressCancel` will necessarily fire
(the widget is being removed from the tree, not released by the user).
**Why it happens:** The stepper widget's lifecycle is tied to whether `showCustom` is true;
toggling it off unmounts the stepper row.
**How to avoid:** This is exactly what Pitfall 1's `dispose()`-cancels-the-Timer rule handles —
unmounting triggers `dispose()`, which is the safety net. Verify this behavior explicitly with
a widget test that holds +, then taps a preset mid-hold, and asserts no exception and no
further increments.
**Warning signs:** Value continuing to change (invisibly, since the row is hidden) after
switching to a preset and back to Custom in the same session.

### Pitfall 3: Reading `shared_preferences` after the first frame causes a visible "flash" of defaults
**What goes wrong:** If `SetupScreen` reads persisted prefs inside `initState()`/`build()`
asynchronously, the first frame renders the hard-coded defaults (5 min / Disc) and then jumps
to the real last-used values a frame or two later — a visible flicker on every launch.
**Why it happens:** All `shared_preferences` APIs (`SharedPreferences.getInstance()`,
`SharedPreferencesAsync`, `SharedPreferencesWithCache.create()`) are `Future`-based; there is
no synchronous read API. [CITED: pub.dev/packages/shared_preferences via Context7]
**How to avoid:** Read the persisted values once in `main()`, **before** `runApp()` is called
(the same place `TimerController` is already constructed) — `main()` is already `async`-able
since `WidgetsFlutterBinding.ensureInitialized()` is called there. Pass the resolved
`durationMin`/`theme` into `SetupScreen` as constructor parameters (or into a small
`SetupPreferences` value object), so the very first frame already shows the correct values.
Do not use a `FutureBuilder` inside `SetupScreen` for this — it would still show a
default/loading frame first.
**Warning signs:** Screenshot tests or manual QA showing a one-frame flash of the 5-min/Disc
defaults before settling on the real last-used values.

### Pitfall 4: Treating "Custom" as a 6th persistable value
**What goes wrong:** Naively persisting whatever `durationMin` was last active — including a
custom value — contradicts D-10, which requires falling back to the 5-min default (not
persisting/restoring a custom number) whenever Custom was the last-used selection.
**Why it happens:** It's tempting to just always write `durationMin` on Start regardless of
`showCustom`.
**How to avoid:** Only ever write a *preset* value to `shared_preferences`. If Start is
pressed while `showCustom` is true, do not update the persisted preset at all (leave whatever
preset was last persisted, or the built-in default if none) — the *live* session continues to
use the custom value for that run, but persistence is untouched. This keeps the persisted
state exactly "last-used preset + last-used theme," never a custom number.
**Warning signs:** Relaunching after using a Custom value shows some arbitrary preset (e.g.
30 min, because 47 was written and something tried to "round" it) instead of always landing on
the documented 5-min fallback.

### Pitfall 5: Google Fonts static file names/weights may not match memory
**What goes wrong:** Assuming Quicksand and Baloo 2 are available as simple per-weight static
`.ttf` downloads (e.g. `Quicksand-Regular.ttf`, `Quicksand-Medium.ttf`, ...,
`BalooTwo-Bold.ttf`) without checking — several Google Fonts families have moved to
variable-font-only distribution on fonts.google.com, which changes how you obtain a specific
static weight.
**Why it happens:** Training-data familiarity with older Google Fonts static-file conventions
may be stale; this was not verified against the current fonts.google.com download flow in this
session (websearch confidence was LOW on this specific point).
**How to avoid:** At implementation time, download directly from fonts.google.com's UI (which
generates static instances per selected weight regardless of the family's underlying variable
axes) rather than assuming a GitHub raw-file URL pattern. Confirm the resulting file for the
700 weight is genuinely Bold-instanced, not the default/Regular instance mislabeled.
**Warning signs:** Wordmark or bold UI text rendering at a lighter visual weight than the
UI-SPEC's 700 despite `fontWeight: FontWeight.w700` being set in code — a sign the bundled
`.ttf` itself isn't actually the bold static instance.

## Code Examples

### Preload Prefs Before First Frame (PERSIST-01, Pitfall 3)
```dart
// Source: pattern built on shared_preferences' documented async API
// (pub.dev/packages/shared_preferences via Context7) — this project's async main()
// wrapper is a straightforward extension of the existing main() shape.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final initialDurationMin = prefs.getInt('durationMin') ?? 5;       // D-09 default
  final initialTheme = SceneTheme.values.firstWhere(
    (t) => t.name == prefs.getString('theme'),
    orElse: () => SceneTheme.disc,                                   // D-09 default
  );

  final timerController = TimerController(screenWake: const WakelockScreenWake());
  TimerLifecycleBinder(timerController).attach();

  runApp(MyApp(
    timerController: timerController,
    initialDurationMin: initialDurationMin,
    initialTheme: initialTheme,
  ));
}
```

### Persisting Only Presets, Never Custom (D-10, Pitfall 4)
```dart
// Source: hand-rolled per D-10's explicit "simpler persisted state" decision.
Future<void> persistIfPreset({
  required bool showCustom,
  required int durationMin,
  required SceneTheme theme,
}) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('theme', theme.name); // theme always persists
  if (!showCustom) {
    await prefs.setInt('durationMin', durationMin); // only persist real presets
  }
  // If showCustom is true, durationMin is intentionally left untouched in storage.
}
```

### Custom Fonts in pubspec.yaml (offline bundling)
```yaml
# Source: docs.flutter.dev/cookbook/design/fonts (via Context7)
flutter:
  uses-material-design: true
  fonts:
    - family: Baloo 2
      fonts:
        - asset: assets/fonts/BalooTwo-Bold.ttf
          weight: 700
    - family: Quicksand
      fonts:
        - asset: assets/fonts/Quicksand-Regular.ttf
          weight: 400
        - asset: assets/fonts/Quicksand-Medium.ttf
          weight: 500
        - asset: assets/fonts/Quicksand-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/Quicksand-Bold.ttf
          weight: 700
```
Exact filenames must be re-verified against whatever fonts.google.com actually serves at
download time (see Pitfall 5) — the names above are the conventional pattern, not a confirmed
listing.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `SharedPreferences.getInstance()` singleton | `SharedPreferencesAsync` / `SharedPreferencesWithCache` | Introduced in shared_preferences 2.3.0; legacy API "to be deprecated" per pub.dev docs [CITED] | For this phase's scope (two scalars, read once at launch, written on Start), the legacy singleton API is simpler and sufficiently supported — but note it for future-proofing if this project's persistence needs grow, since new code is steered toward the newer APIs |

**Deprecated/outdated:**
- `google_fonts`' default runtime-fetch mode is not "deprecated" but is explicitly the wrong
  fit here per the offline constraint — not a state-of-the-art regression, just a mismatch
  with this project's requirements.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Google Fonts static `.ttf` files for Quicksand/Baloo 2 follow the `$family-$style.ttf` naming convention and are available per-weight without extra tooling | Common Pitfalls #5, Code Examples "Custom Fonts in pubspec.yaml" | Wrong filenames in `pubspec.yaml` fail the build immediately (loud failure, low real risk) — but if a variable-font instance is mislabeled as a static weight, the bold wordmark could silently render at the wrong visual weight (SETUP-05 fidelity risk) |
| A2 | No community "official" recipe exists for the exact accelerating hold-repeat curve; the `onTap` + `onLongPressStart/End/Cancel` pattern is a synthesis, not a single verified source | Architecture Patterns "Pattern 1" | Low risk — the pattern only combines documented, individually-verified API pieces (`GestureDetector` callbacks, `Timer`), but the *combination* itself was not found in an official cookbook and should be validated with a widget test exercising the full tap→hold→accelerate→release lifecycle |

## Open Questions

1. **Exact "nearest preset" fallback wording is explicitly left to Claude's Discretion, but D-10/UI-SPEC already resolve it to "always 5-min default."**
   - What we know: `02-UI-SPEC.md`'s Interaction Contract states plainly: "Setup falls back to
     the default preset (5 min) rather than attempting a nearest-preset match."
   - What's unclear: Nothing — this is resolved, listed only so the planner doesn't
     re-litigate it as an open design question.
   - Recommendation: Implement exactly as Code Example "Persisting Only Presets, Never Custom"
     above; no further research needed.

2. **Exact static font file names/weights for Quicksand and Baloo 2.**
   - What we know: Both families are on Google Fonts and support the required weights (Baloo 2
     up to ExtraBold, so 700/Bold exists; Quicksand up to Bold in its original four weights,
     700 exists).
   - What's unclear: The precise filenames/packaging Google Fonts' current download flow
     produces (variable vs. static instances) — not verified this session (see Assumption A1).
   - Recommendation: Resolve at implementation time by downloading directly from
     fonts.google.com and inspecting the resulting archive; do not hardcode a guessed URL.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | All phase work | ✓ | 3.38.7 (stable channel) [VERIFIED: `flutter --version`] | — |
| Dart SDK | All phase work | ✓ | 3.10.7 (bundled with Flutter) [VERIFIED: `flutter --version`] | — |
| Android SDK / toolchain | Eventual on-device verification of SETUP-05 pixel fidelity | ✓ | SDK 36.1.0 [VERIFIED: `flutter doctor`] | — |
| Android emulator/device | Visual QA against Layout A on the actual target platform | ✗ (none connected at research time — only Windows desktop + Chrome/Edge web targets found) [VERIFIED: `flutter devices`] | — | Widget tests and `flutter analyze` need no device; iterate visually on the Windows desktop or Chrome target (layout/colors/fonts render identically) and start an Android emulator before final pixel-fidelity sign-off on SETUP-05 |
| `shared_preferences` package | PERSIST-01 | ✗ (not yet added) | resolves to 2.5.5 [VERIFIED: `flutter pub add --dry-run`] | None needed — trivial `flutter pub add shared_preferences` |
| Font asset files (Baloo 2, Quicksand `.ttf`) | SETUP-05 typography fidelity | ✗ (not present anywhere in the repo; `design/` has no font files, no `assets/` dir exists yet) [VERIFIED: filesystem search this session] | — | Must be downloaded and added under `assets/fonts/` as part of this phase's plan — this is a plan task, not a blocker, but the planner must include it explicitly (nothing to fall back to if skipped — text would render in the platform default font, failing SETUP-05) |

**Missing dependencies with no fallback:**
- Font asset files must be sourced and bundled — SETUP-05 (pixel-accurate typography) cannot
  be met without them. This is expected first-phase-of-UI work, not a blocker, but must be an
  explicit plan task.

**Missing dependencies with fallback:**
- No Android emulator/device currently connected — non-blocking; desktop/web targets are a
  fine iteration loop, but final SETUP-05 visual sign-off should happen on Android before the
  phase is considered done, consistent with this being an Android-only v1 per `CLAUDE.md`.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter SDK; already used in `test/widget_test.dart` and `test/timer/timer_controller_test.dart`) |
| Config file | none — no `dart_test.yaml`; standard `flutter test` discovery over `test/` |
| Quick run command | `flutter test test/screens/ test/widgets/` (once created) |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SETUP-01 | Tapping a preset (1/5/10/15/30) selects it and shows the ring overlay | widget | `flutter test test/screens/setup_screen_test.dart` | ❌ Wave 0 |
| SETUP-02 | Tap on −/+ changes by 1; hold repeats and accelerates; disables at 1/120 | widget | `flutter test test/widgets/hold_repeat_button_test.dart` | ❌ Wave 0 |
| SETUP-03 | Tapping a scene card selects it (single-select) | widget | `flutter test test/screens/setup_screen_test.dart` | ❌ Wave 0 |
| SETUP-04 | Start calls `TimerController.start(minutes)` with the correct value and navigates | widget | `flutter test test/screens/setup_screen_test.dart` | ❌ Wave 0 |
| SETUP-05 | Visual/pixel fidelity to Layout A | manual-only — no automated pixel-diff tooling configured in this project | manual QA against `design/README.md` §A / `Zual.dc.html` on an Android emulator | n/a |
| PERSIST-01 | Last-used preset + theme restored on next launch | unit + widget | `flutter test test/settings/setup_preferences_test.dart` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** `flutter test <changed test file>` (fast, targeted)
- **Per wave merge:** `flutter test` (full suite, including Phase 1's existing
  `timer_controller_test.dart` and `widget_test.dart` — the latter will need updating since it
  currently asserts on the "Hello, World!" scaffold text this phase removes)
- **Phase gate:** Full suite green, plus one manual Android-emulator pass against Layout A
  before `/gsd-verify-work`

### Wave 0 Gaps
- [ ] `test/screens/setup_screen_test.dart` — covers SETUP-01, SETUP-03, SETUP-04
- [ ] `test/widgets/hold_repeat_button_test.dart` — covers SETUP-02 (tap-once, hold-accelerate,
      disabled-edge, and the Pitfall 1/2 dispose-mid-hold cases)
- [ ] `test/settings/setup_preferences_test.dart` — covers PERSIST-01 and the D-10
      preset-only-persistence rule (Pitfall 4)
- [ ] `test/widget_test.dart` must be **updated**, not left as-is — it currently expects
      `MyHomePage`'s "Hello, World!" text, which `SetupScreen` replaces
- [ ] No `SharedPreferences` fake/mock helper exists yet — `shared_preferences` ships an
      official `SharedPreferences.setMockInitialValues()` test helper; use it rather than
      hand-rolling a fake backend [CITED: pub.dev/packages/shared_preferences testing guidance]

## Security Domain

`security_enforcement` is enabled (ASVS Level 1) per `.planning/config.json`. This phase has
no network calls, no authentication, no server-side surface, and no untrusted external input
beyond local persisted preferences the app itself wrote — most ASVS categories are structurally
not applicable to a fully local, single-user, offline Flutter app.

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-------------------|
| V2 Authentication | No | No accounts/login in this app (`REQUIREMENTS.md` "Out of Scope") |
| V3 Session Management | No | No sessions — single local device, single user |
| V4 Access Control | No | No multi-user/role concept |
| V5 Input Validation | Yes (narrow) | The custom stepper's 1–120 range must be enforced in code, not just visually (D-08) — clamp `customMin` server-side-equivalent (i.e., in the state setter itself, not only by disabling buttons), so no code path can push it outside 1–120 even via a bug in the disable logic |
| V6 Cryptography | No | No secrets, no encrypted-at-rest requirement for "last used duration + theme" — plaintext `shared_preferences` storage is appropriate for this non-sensitive data |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|----------------------|
| Corrupted/out-of-range persisted value (e.g. a manually-edited `SharedPreferences` XML/plist on a rooted device, or a future app version writing an unexpected value) causing an out-of-range `durationMin`/unknown `theme` string to be read back | Tampering | Always clamp/validate on read, not just on write: clamp any restored `durationMin` into `1..120` (mirroring `TimerController.start`'s own `.clamp(_minMinutes, _maxMinutes)` pattern already used in Phase 1) and fall back to `SceneTheme.disc` via `firstWhere(..., orElse: () => SceneTheme.disc)` (as shown in the Code Examples section) rather than trusting the stored string to always match a valid enum name |

## Sources

### Primary (HIGH confidence)
- `flutter --version`, `flutter doctor`, `flutter devices`, `flutter pub add --dry-run` —
  direct tool output against this machine and the live pub.dev registry, confirming Flutter
  3.38.7 / Dart 3.10.7 / `shared_preferences` resolving to `2.5.5`

### Secondary (MEDIUM confidence)
- Context7 `/websites/pub_dev_packages_shared_preferences` — shared_preferences API surface
  (`getInstance`, `SharedPreferencesAsync`, `SharedPreferencesWithCache`)
- Context7 `/websites/api_flutter_dev` — `GestureDetector` long-press callback family,
  `LongPressStartDetails`/`LongPressEndDetails`
- Context7 `/websites/flutter_dev` — `CustomPainter`/`CustomPaint` contract
  (docs.flutter.dev/flutter-for/*), custom font declaration in `pubspec.yaml`
  (docs.flutter.dev/cookbook/design/fonts)
- WebFetch of pub.dev/packages/shared_preferences — publish date, likes/pub-points, GitHub
  source repo location

### Tertiary (LOW confidence)
- WebSearch — general community consensus on `Timer`+`GestureDetector` hold-repeat patterns
  (no single official source; cross-referenced against Context7's API docs above)
- WebSearch — Google Fonts static-file naming conventions and variable-font migration status
  for Quicksand/Baloo 2 (flagged in Assumptions Log A1 and Common Pitfalls #5 — needs
  re-verification at implementation time)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — `shared_preferences` version/registry presence directly verified
  against pub.dev this session; no other new packages introduced
- Architecture: MEDIUM — patterns synthesized from verified individual API pieces (Context7),
  but the specific hold-repeat combination and scene-preview abstraction are original designs
  for this project, not lifted from a single verified official example
- Pitfalls: MEDIUM — Timer/dispose and prefs-timing pitfalls are well-established Flutter
  patterns; the D-10 persistence-scoping pitfall is project-specific reasoning, not sourced
- Fonts: LOW-MEDIUM — `pubspec.yaml` mechanics are verified via Context7; exact Google Fonts
  static-file availability for these two families is not verified this session (Assumption A1)

**Research date:** 2026-07-07
**Valid until:** 2026-08-06 (30 days — Flutter/Dart APIs used here are stable, not fast-moving;
re-verify `shared_preferences` version and Google Fonts static-file status if this estimate is
exceeded)
