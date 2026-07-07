# Phase 3: Scene Themes - Research

**Researched:** 2026-07-07
**Domain:** Flutter `CustomPainter` full-screen animated scenes driven by a shared wall-clock progress value, combined with independent local decorative loop animations
**Confidence:** MEDIUM (Flutter core animation APIs are HIGH-reputation official-docs-confirmed; the design doc's exact colors/formulas are final-fidelity project spec, not externally sourced; one critical finding below is derived directly from reading this project's own `TimerController` source, not from external docs)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Scene visual fidelity (D-01):** All four scenes' colors, geometry, thresholds, and motion
formulas are treated as final per `design/README.md` §§C–F — this was not re-litigated in
discussion (per project Constraints: "Fidelity ... treated as final, not starting points"). The
color-zone thresholds for Shrinking Disc (`r > 0.5` green, `0.2 < r ≤ 0.5` yellow→green lerp,
`r ≤ 0.2` red→yellow lerp), the sky/star/moon/sun/hill formulas for Night to Sunrise, and the
`left = 6 + p*62%` arrival mechanic for Walking Home / Car on a Road are locked exactly as
written in the design doc — no gray area here.

**Decorative loop-animation feel (D-02):** Design doc specifies these motions qualitatively
("gentle twinkle", "gentle vertical bob", "spinning wheels") without exact timings. Recommended
default: subtle and slow — twinkle a soft opacity pulse (~2–3s cycle), walk/car bob a small
amplitude (a few px) at a gentle cadence, wheel spin continuous but unhurried. These are
decorative loops independent of the shared progress-driven `TickerProviderStateMixin` per Phase
1 research's `ARCHITECTURE.md`, tuned for the app's calm, non-distracting tone — never
fast/bouncy/attention-grabbing, consistent with "playful but calm" from PROJECT.md.

**Smooth-animation validation approach (D-03, SCENE-05):** No automated pixel-diff or
frame-timing tooling exists in this project (confirmed absent during Phase 2 verification).
Recommended approach, consistent with Phase 2's established pattern
(`workflow.human_verify_mode: end-of-phase`): automated widget tests cover progress-driven
correctness (color-zone thresholds, arrival-at-p=1, `shouldRepaint` boundaries, no exceptions
across the full 0..1 range) as the CI-checkable layer; actual "smooth, no jank" perceptual
validation is a human end-of-phase check on a real low/mid-end Android device (API 24–28) —
already flagged as a Blocker/Concern in STATE.md for this phase.

### Claude's Discretion

- Exact file/class structure for the four scene widgets and their painters (already strongly
  guided by `.planning/research/ARCHITECTURE.md`'s `SceneRenderer` contract and `scenes/<theme>/`
  folder layout) — a technical/architectural detail, not a product decision.
- Negative-opacity clamping and other formula edge cases (e.g., the star fade formula
  `opacity = 1 − p*2.3` goes negative before p=1) — implementation-level correctness detail, not
  a product-facing gray area.
- Whether decorative loop `AnimationController`s pause/dispose alongside the shared
  `TimerController`'s paused/done phases, or keep running independently while paused — technical
  lifecycle detail; should default to pausing decorative loops whenever the timer itself is
  paused, for consistency with the "timer paused = scene frozen" mental model.

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope. Parent Controls, chime, and the "All done" pill are
explicitly Phase 4 concerns (already scoped there in ROADMAP.md), not folded into Phase 3.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| SCENE-01 | Shrinking Disc theme renders full-screen; disc scales down as time passes with green→yellow→red color zones | Exact thresholds locked in design doc §C; see Code Examples §"Disc color-zone function" and Common Pitfall 1 (200ms-tick smoothness problem) |
| SCENE-02 | Night to Sunrise theme renders full-screen; sky interpolates night→day, stars/moon fade, sun rises, hill warms | Exact formulas locked in design doc §D; see Common Pitfall 3 (negative-opacity clamp) and Code Examples §"Sunrise formulas" |
| SCENE-03 | Walking Home theme renders full-screen; character walks a path toward a house, arriving at time-up | Exact `left = 6 + p*62%` mechanic locked in design doc §E; see Code Examples §"Arrival mechanic" |
| SCENE-04 | Car on a Road theme renders full-screen; car drives a path toward a destination, arriving at time-up | Same arrival mechanic as SCENE-03, design doc §F; wheel-spin decorative loop, see Pattern 2 |
| SCENE-05 | All 4 scenes read only a shared `progress` value (0..1) via a common scene-renderer contract; nothing is tappable by the child | `SceneRenderer` contract per `ARCHITECTURE.md` Pattern 2, extended here with a local high-frequency ticker (Pattern 1 below); "nothing tappable" verified via widget test asserting no gesture-reactive ancestor in the scene subtree |
</phase_requirements>

## Summary

This phase builds the four real, full-screen, progress-driven scenes that Phase 2's static
mini-previews (`lib/scenes/scene_preview.dart`) foreshadow, replacing
`lib/screens/placeholder_running_screen.dart`. The project's own `ARCHITECTURE.md` and
`PITFALLS.md` already resolve most of the standard Flutter architecture (CustomPainter over
widget-tree animation, wall-clock progress not `AnimationController.duration`, the
`SceneRenderer` contract, `scene_registry.dart` as the single `SceneTheme → widget` switch). This
research does not re-litigate those; it focuses on three things this phase specifically needs
that weren't (and couldn't be) resolved before Phase 1's `TimerController` was actually
implemented, and before the four scenes' exact motion formulas were mapped to Dart.

**The single most important finding:** `TimerController` (as actually implemented in Phase 1,
verified by reading `lib/timer/timer_controller.dart` directly) drives its `notifyListeners()`
cadence from a **200ms** periodic ticker (`_tickInterval = tickInterval ?? const
Duration(milliseconds: 200)`), i.e. 5 updates/second. `ARCHITECTURE.md`'s Pattern 3 suggested
"just rebuild the whole `SceneRenderer` subtree each time `TimerController.notifyListeners()`
fires" as the "simpler idiom" — but that idiom, applied literally, produces visibly stepped
motion (5 discrete positions/second) that fails SCENE-05's "animate smoothly ... without visible
jank" success criterion outright, regardless of how well each individual scene is painted. The
fix is architectural, not cosmetic: each scene needs its own continuously-running frame source
(a `Ticker`, not tied to `TimerController`'s notify cadence) that polls `TimerController.progress`
fresh every frame — safe to do because `progress` is a **pure getter recomputed from wall-clock
time on every access**, not a cached value that only updates when `notifyListeners()` fires. This
same per-scene ticker is also the natural host for each scene's local decorative loop (twinkle,
bob, spin), directly answering the CONTEXT.md open question about combining a shared
progress-driven rebuild with a local loop animation without conflicting controllers — one
continuously-running ticker per scene serves both purposes, and only `TimerController.phase`
(a low-frequency, discrete signal) needs `context.watch` for start/pause/done transitions.

Beyond that, the standard `CustomPainter` performance and testing patterns from `PITFALLS.md`
(Pitfall 3, 5) apply directly to all four scenes, and two of the four scenes' exact formulas
(star/moon opacity fade) require explicit clamping before reaching Flutter's `Color` API, which
asserts its alpha/opacity argument is within `0.0..1.0`.

**Primary recommendation:** Implement the `SceneRenderer` contract exactly as
`ARCHITECTURE.md` specifies, but give every concrete scene (`DiscScene`, `SunriseScene`,
`WalkScene`, `CarScene`) its own `TickerProviderStateMixin`-hosted `Ticker` that (a) polls
`TimerController.progress` fresh every frame for smooth motion and (b) derives all decorative
loop phases (twinkle/bob/spin) from the same ticker's elapsed time — started on
`TimerPhase.running`, stopped on `TimerPhase.paused`/`done`. Keep all four scenes' pure
calculation logic (color-zone lerp, opacity formulas, position formulas) in small top-level
functions separate from `paint()`, so they are unit-testable without pumping a widget tree.

## Architectural Responsibility Map

Zual is a single-tier Flutter client app (no server/API/CDN tiers) — this phase's "architectural
tiers" map to the app's own internal layers as established in `ARCHITECTURE.md`, not a
multi-service topology.

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Disc/Sunrise/Walk/Car pixel drawing (shapes, gradients, color-zone lerp) | Rendering (`CustomPainter`) | — | Pure function of `progress` + local decorative phase; no state ownership |
| Smooth 60fps progress sampling | Rendering (per-scene `Ticker`) | Domain/State (`TimerController.progress` getter) | Ticker owns *when* to repaint; `TimerController` remains the sole source of *what* progress currently is |
| Decorative loop motion (twinkle/bob/spin) | Rendering (per-scene `Ticker`) | — | Entirely local to the scene; never touches `TimerController` |
| `SceneRenderer` contract / `scene_registry.dart` mapping | Client/Presentation (composition) | — | The one place `SceneTheme` maps to a widget; already established by Phase 2's `ScenePreviewPainter` discipline |
| "Nothing tappable by the child" | Client/Presentation (`RunningScreen`/`SceneHost`) | — | Absence-of-gesture-handler is a composition-root concern, not a per-scene concern — scenes must not add their own `GestureDetector`s |
| Phase-driven ticker start/stop (running/paused/done) | Client/Presentation (scene `State`, via `context.watch<TimerController>().phase`) | Domain/State (`TimerPhase` enum) | Discrete, low-frequency signal — safe to use `context.watch` rebuild for this, unlike continuous progress |

## Standard Stack

### Core

No new packages are required for this phase. Every technique below (`CustomPainter`,
`CustomPaint`, `Ticker`, `TickerProviderStateMixin`, `AnimatedBuilder`, `Color.lerp`,
`LinearGradient`/`RadialGradient`) is part of the Flutter SDK itself
`[VERIFIED: pubspec.yaml — flutter: sdk: flutter already present, no scene-specific packages listed]`.

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Flutter SDK (`dart:ui`, `package:flutter/widgets.dart`, `package:flutter/scheduler.dart`) | bundled with Flutter 3.18.0-18.0.pre.54+ (already pinned in this project) | `CustomPainter`, `Canvas`, `Ticker`, gradients, `Color` | Zero-dependency, official, already the pattern established by `lib/scenes/scene_preview.dart`'s painters `[VERIFIED: lib/scenes/scene_preview.dart]` |

### Supporting

None. No image/asset packages needed — design doc explicitly states "No image assets. All
visuals ... built from CSS primitives" and instructs reproducing with vector/shape primitives
`[CITED: design/README.md §Assets]`.

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| Per-scene `Ticker` polling `TimerController.progress` every frame | `AnimatedBuilder` wrapping `TimerController` directly via `context.watch` (ARCHITECTURE.md's originally-suggested "simpler idiom") | Simpler code, but caps visual update rate at `TimerController`'s 200ms notify interval (5fps) — fails SCENE-05's smoothness requirement; rejected for this phase |
| Extracting pure calculation functions (color-zone lerp, opacity formulas) outside the painter | Computing everything inline inside `paint()` | Inline calculation is what `scene_preview.dart`'s *static* painters do (fine since they never repaint), but the real animated scenes need these formulas independently unit-testable without pumping a widget tree — extract them |

**Installation:** None — no `pubspec.yaml` changes needed for this phase.

**Version verification:** N/A — no new packages recommended.

## Package Legitimacy Audit

**Not applicable.** This phase introduces zero new external packages; all techniques use the
Flutter SDK already declared in `pubspec.yaml`. No packages to check, none removed, none flagged.

## Architecture Patterns

### System Architecture Diagram

```
TimerController (existing, Phase 1)
  .phase: TimerPhase (setup|running|paused|done)   -- discrete, low-frequency
  .progress: double 0..1 (pure getter, wall-clock derived, no caching)
        │
        │  context.watch<TimerController>().phase   (rebuild only on phase change)
        ▼
RunningScreen / SceneHost  ── passes `theme` to scene_registry.dart ──▶  sceneFor(theme) widget
        │
        ▼
Active Scene widget (DiscScene | SunriseScene | WalkScene | CarScene)
  State mixes in TickerProviderStateMixin
  ┌─────────────────────────────────────────────────────────────┐
  │  Local Ticker (created in initState, started when phase==running,│
  │  stopped when phase==paused/done)                              │
  │      │  every frame:                                            │
  │      ├─▶ poll TimerController.progress fresh (NOT via notify)   │
  │      ├─▶ compute local decorative phase (elapsed % loopMs)      │
  │      └─▶ trigger CustomPaint repaint (setState/ValueNotifier)   │
  └─────────────────────────────────────────────────────────────┘
        │
        ▼
CustomPainter.paint(canvas, size)
  ├─▶ pure calc fns (discColorForRemaining, sunriseSkyColors, arrivalLeft, ...)
  └─▶ canvas.draw*(...)   -- shapes, gradients, no widget-tree animation
```

Data flows one-directional: `TimerController` → scene → painter → pixels. Nothing flows back up
(no scene ever calls into `TimerController`), preserving Anti-Pattern 1 from `ARCHITECTURE.md`.

### Recommended Project Structure

Matches `.planning/research/ARCHITECTURE.md`'s existing `scenes/` layout exactly — this phase
fills in the folders that layout already reserved:

```
lib/scenes/
├── scene_theme.dart          # existing (Phase 2) — unchanged
├── scene_preview.dart        # existing (Phase 2) — unchanged, cross-reference only
├── scene_renderer.dart       # NEW — shared SceneRenderer contract + ticker-hosting mixin
├── scene_registry.dart       # NEW — SceneTheme -> SceneRenderer factory (the one switch)
├── disc/
│   ├── disc_scene.dart
│   └── disc_painter.dart     # + top-level discColorForRemaining(double remaining) -> Color
├── sunrise/
│   ├── sunrise_scene.dart
│   └── sunrise_painter.dart  # + top-level pure fns for star/moon opacity, sun top%, hill color
├── walk/
│   ├── walk_scene.dart
│   └── walk_painter.dart     # + top-level arrivalLeftFraction(double progress) -> double
└── car/
    ├── car_scene.dart
    └── car_painter.dart      # shares arrivalLeftFraction with walk/
```

### Pattern 1: Per-scene `Ticker` decouples smooth rendering from `TimerController`'s notify cadence

**What:** Each scene's `State` mixes in `TickerProviderStateMixin` and creates one `Ticker` (via
`createTicker`) in `initState`. On every tick, the scene re-reads `TimerController.progress`
directly (via `context.read`, not `watch` — this avoids depending on `notifyListeners()` for
per-frame updates) and calls `setState`/updates a `ValueNotifier<double>` feeding the
`CustomPaint`'s `repaint:` parameter. The scene separately watches `TimerController.phase` (a
low-frequency, discrete value) via `context.watch` purely to decide whether the `Ticker` should
be running (`start()`/`stop()`), not to drive per-frame painting.

**When to use:** Any scene where `progress`-driven motion must look continuous (60fps) but the
underlying value's owner only signals rebuilds at a lower rate. This is exactly this project's
situation: `TimerController`'s 200ms tick interval is correct and sufficient for *state* bookkeeping
(phase transitions, `done` detection) but insufficient as a *repaint* trigger for smooth motion.

**Trade-offs:** Slightly more setup per scene (one `Ticker` + lifecycle wiring) than the
"just `context.watch` and rebuild" idiom `ARCHITECTURE.md` originally proposed — but that idiom
was written before `TimerController`'s actual 200ms interval was implemented and is not sufficient
for SCENE-05. The extra ticker is cheap (one `Ticker` per active scene, only one scene active at
a time) and this pattern also directly solves the decorative-loop-animation problem for free (see
Pattern 2).

**Example:**
```dart
// lib/scenes/scene_renderer.dart
abstract class SceneRenderer extends StatefulWidget {
  const SceneRenderer({super.key});
}

abstract class SceneRendererState<T extends SceneRenderer> extends State<T>
    with TickerProviderStateMixin {
  late final Ticker _ticker;
  double _progress = 0.0;
  Duration _elapsedSinceStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _progress = context.read<TimerController>().progress;
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    _elapsedSinceStart = elapsed;
    final fresh = context.read<TimerController>().progress;
    if (fresh != _progress) setState(() => _progress = fresh);
  }

  /// Local decorative-loop phase in 0..1, given a loop period. Subclasses use
  /// this for twinkle/bob/spin instead of a second AnimationController.
  double loopPhase(Duration period) =>
      (_elapsedSinceStart.inMilliseconds % period.inMilliseconds) /
      period.inMilliseconds;

  double get progress => _progress;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phase = context.watch<TimerController>().phase;
    if (phase == TimerPhase.running && !_ticker.isTicking) {
      _ticker.start();
    } else if (phase != TimerPhase.running && _ticker.isTicking) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }
}
```
Source pattern for `Ticker`/vsync mechanics: official Flutter docs on `AnimatedBuilder` and
animation-listener idioms `[CITED: Context7 /flutter/website — AnimatedBuilder/addListener examples]`;
the specific application to this project's 200ms-vs-60fps gap is this research's own analysis,
grounded in `[VERIFIED: lib/timer/timer_controller.dart]`.

### Pattern 2: Decorative loops derive their phase from the same ticker, never a second controller

**What:** Twinkle (~2–3s), bob (~0.6s), and spin (~0.7s) are all just `loopPhase(period)` calls
against the one ticker from Pattern 1, fed through `sin()`/linear interpolation inside the
painter — not separate `AnimationController`s with their own vsync subscriptions.

**When to use:** Always for this app's four scenes — avoids the exact "conflicting
`AnimationController`/`CustomPainter` repaint triggers" problem flagged as an open question in
CONTEXT.md, because there is only ever one frame-driving object per scene.

**Trade-offs:** Loop periods become manual modulo/phase math rather than declarative
`AnimationController(duration: ...)..repeat()` calls — a small amount of extra arithmetic, but it
guarantees exactly one repaint scheduler per scene and trivially keeps "pause timer = freeze
decorations" correct (Claude's Discretion decision) since stopping the one ticker stops
everything at once.

**Example:**
```dart
// Inside DiscPainter.paint / SunrisePainter.paint, or the scene's build():
final twinkle = 0.35 + 0.65 * (0.5 - 0.5 * cos(2 * pi * loopPhase(const Duration(seconds: 3))));
// bob: 0 -> -7px -> 0 over ~0.62s
final bobOffset = -7.0 * (0.5 - 0.5 * cos(2 * pi * loopPhase(const Duration(milliseconds: 620))));
// spin: continuous rotation, 0.7s per revolution
final wheelAngle = 2 * pi * loopPhase(const Duration(milliseconds: 700));
```

### Pattern 3: Keep every formula as a standalone pure function, separate from `paint()`

**What:** `discColorForRemaining(double remaining) -> Color`,
`starOpacity(double progress) -> double`, `moonOpacity(double progress) -> double`,
`sunTopFraction(double progress) -> double`, `arrivalLeftFraction(double progress) -> double` —
each a small top-level (or static) function taking only numeric input and returning a numeric or
`Color` result, called from inside `paint()` but unit-testable in complete isolation.

**When to use:** Always, for every one of the four scenes' progress-driven values. This is the
only practical way to satisfy the D-03-mandated automated-test layer (color-zone thresholds,
arrival-at-p=1, no-exception-across-0..1) without needing pixel introspection of `Canvas` calls,
which Flutter's test framework does not support directly.

**Trade-offs:** Marginally more files/functions than inlining the math in `paint()`, but this is
exactly the technique that made Phase 2's `ScenePreviewPainter`s straightforward to verify
(`shouldRepaint` tests) and generalizes cleanly to formulas with real inputs.

**Example:**
```dart
// lib/scenes/disc/disc_painter.dart
Color discColorForRemaining(double remaining) {
  const green = Color(0xFF7FA87A);
  const yellow = Color(0xFFE8B75A);
  const red = Color(0xFFDE6A4B);
  if (remaining > 0.5) return green;
  if (remaining > 0.2) {
    final t = (remaining - 0.2) / (0.5 - 0.2); // 0 at r=0.2, 1 at r=0.5
    return Color.lerp(yellow, green, t)!;
  }
  final t = remaining / 0.2; // 0 at r=0, 1 at r=0.2
  return Color.lerp(red, yellow, t)!;
}
```
```dart
// test/scenes/disc/disc_painter_test.dart
test('r=0.6 is pure green', () {
  expect(discColorForRemaining(0.6), const Color(0xFF7FA87A));
});
test('r=0.2 boundary is red->yellow lerp start (pure red)', () {
  expect(discColorForRemaining(0.2), const Color(0xFFDE6A4B));
});
```

### Anti-Patterns to Avoid

- **Passing `TimerController.progress` into a scene only via `context.watch` rebuilds:** Caps
  visual smoothness at 200ms/5fps steps — fails SCENE-05 outright. Always sample `progress`
  fresh from a per-scene `Ticker`, per Pattern 1.
- **A second `AnimationController` per scene for decorative loops, alongside the progress
  ticker:** Two independent vsync subscriptions in one scene is exactly the "conflicting
  controllers" scenario CONTEXT.md flagged — derive decorative phase from the same ticker
  instead (Pattern 2).
- **Inlining color/opacity/position formulas directly in `paint()` with no pure-function
  extraction:** Makes the D-03-mandated automated test layer impossible to write without pumping
  a full widget tree per assertion; extract pure functions instead (Pattern 3).
- **Passing an unclamped `1 − p*2.3`/`1 − p*1.7` opacity value straight into
  `Color.withValues(alpha: ...)`:** Throws an assertion error once progress exceeds
  ~0.43/~0.59 respectively (see Common Pitfall 3) — always `.clamp(0.0, 1.0)` first.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Color interpolation between zone boundaries | Manual per-channel RGB lerp math | `Color.lerp(colorA, colorB, t)` | Built into `dart:ui`, handles alpha/channel interpolation correctly, already implicitly used by Flutter's own `ColorTween` |
| Sky gradient rendering | Manually drawing horizontal color bands | `LinearGradient(...).createShader(rect)` (already the pattern in `scene_preview.dart`'s `SunrisePreviewPainter`) | Hardware-accelerated shader, single draw call, matches the existing static-preview convention exactly |
| Continuous frame callbacks for smooth 60fps motion | Reinventing a frame loop with `Timer.periodic(Duration(milliseconds: 16))` | `Ticker` via `TickerProviderStateMixin.createTicker` | `Ticker` is vsync-synced to the actual display refresh and automatically pauses when the app is backgrounded/the route isn't visible — a raw `Timer.periodic` does neither and would waste battery exactly like Pitfall 4 in `PITFALLS.md` warns against |

**Key insight:** Every one of this phase's "hard" visual problems (gradients, color lerp, smooth
per-frame motion) already has a direct, zero-extra-dependency Flutter SDK primitive — the actual
engineering risk in this phase is entirely in *sequencing/lifecycle* (which object drives repaint,
when it starts/stops), not in drawing primitives themselves.

## Common Pitfalls

### Pitfall 1: Trusting `TimerController`'s 200ms notify cadence as the scene's repaint trigger

**What goes wrong:** A scene built with `context.watch<TimerController>()` feeding `progress`
straight into its `CustomPainter` will only visually update 5 times per second, producing
obviously stepped/jerky motion — most visible on the Shrinking Disc (the "hero" scene) where a
smoothly shrinking circle is the entire value proposition.

**Why it happens:** `ARCHITECTURE.md`'s Pattern 3 (written before `TimerController` was actually
implemented) suggested this as the "simpler idiom," reasonably assuming a rebuild-per-notify
model would be adequate — but Phase 1 settled on 200ms as the *state* reconciliation interval,
which is correct for that purpose but was never intended as a *frame rate*.

**How to avoid:** Use Pattern 1 (per-scene `Ticker` polling `progress` fresh every frame).

**Warning signs:** Visual "stepping" or "ticking" motion in manual testing, especially noticeable
in the disc scale animation; DevTools timeline showing paint calls clustered every ~200ms instead
of every ~16ms.

### Pitfall 2: `CustomPainter.shouldRepaint` over- or under-triggering once two inputs (progress + decorative phase) are merged into one ticker

**What goes wrong:** If `shouldRepaint` naively returns `true` unconditionally (common shortcut),
the painter repaints every tick regardless of whether progress or loop phase actually changed —
wasteful but not incorrect. The opposite mistake — comparing only `progress` and forgetting the
decorative loop phase also needs to trigger a repaint — causes twinkle/bob/spin to visually
freeze even while progress-driven elements keep moving.

**Why it happens:** Once a scene's painter takes two logically-separate time-varying inputs
(shared progress, local decorative phase), it's easy to only wire `shouldRepaint`'s comparison to
the one that "matters more" (progress) and forget the other.

**How to avoid:** Pass both values into the painter's constructor and compare both fields in
`shouldRepaint`, per the `SignaturePainter`/`ParallaxFlowDelegate` idiom from official docs
`[CITED: Context7 /flutter/website]`.

**Warning signs:** Decorative elements (stars, bob, wheels) appear static in a running scene even
though the main progress-driven element (disc size, character position) visibly moves.

### Pitfall 3: Negative opacity from the star/moon fade formulas crashing `Color.withValues`/`withOpacity`

**What goes wrong:** `opacity = 1 − p*2.3` (stars) goes negative once `p > 0.435`; `opacity = 1 −
p*1.7` (moon) goes negative once `p > 0.588`. Both are well inside the normal 0..1 progress range
this scene runs for its full duration. Passing a negative value to `Color.withOpacity(double)` or
`Color.withValues(alpha: double)` throws an assertion error (`opacity >= 0.0 && opacity <= 1.0`)
`[CITED: api.flutter.dev Color.withOpacity; flutter/flutter issue #56092]`.

**Why it happens:** The design doc's formulas are written for a CSS/DOM context (where CSS
silently clamps out-of-range opacity to 0/1) — Flutter's `Color` API does not silently clamp and
will throw instead.

**How to avoid:** Wrap every progress-derived opacity/alpha value in `.clamp(0.0, 1.0)` before
passing it to `withValues(alpha: ...)` (the API already used in this codebase's
`scene_preview.dart`, e.g. `Colors.white.withValues(alpha: 0.8)` — prefer this over the
deprecated `withOpacity` for consistency with existing code).

**Warning signs:** A runtime assertion crash the moment progress crosses ~0.44 (stars) or ~0.59
(moon) during manual testing or a 0..1 progress-sweep widget test.

### Pitfall 4: `pumpAndSettle()` hangs against this phase's genuinely infinite decorative loops

**What goes wrong:** Any widget test that calls `tester.pumpAndSettle()` on a screen hosting one
of these four scenes (all of which have at least one infinite decorative loop — twinkle, bob, or
spin) will time out, because `pumpAndSettle` waits for animations to stop scheduling frames, which
an infinite `Ticker` never does. Already documented generically in `PITFALLS.md` Pitfall 5; this
phase is precisely where it will first bite.

**Why it happens:** `pumpAndSettle()` is the reflexive default in most Flutter test tutorials.

**How to avoid:** Use `tester.pump(fixedDuration)` at deliberately chosen checkpoints (e.g. pump
0ms, then pump specific durations corresponding to progress 0.0/0.25/0.5/1.0) instead of
`pumpAndSettle()` for every scene widget test `[CITED: Context7 /flutter/website — testing
cookbook pump()/pumpAndSettle() distinction]`.

**Warning signs:** CI test runs hang or fail with a `pumpAndSettle timed out` exception the moment
a scene widget test is added.

### Pitfall 5: Recreating `Gradient`/`Shader` objects every frame in the two gradient-heavy scenes

**What goes wrong:** Night-to-Sunrise's sky gradient is legitimately progress-driven every frame
(cannot be cached outright), but if the *disc* scene's static-per-frame `Paint` objects (shadow
blur, stroke paints) are also reconstructed from scratch inside `paint()` on every tick rather
than cached as fields, frame-time creep accumulates over a long-running (up to 120 min) session.

**Why it happens:** It's the path of least resistance to construct all `Paint`/`Shader` objects
fresh inside `paint()`, and this "works" in short manual tests without revealing the gradual
cost.

**How to avoid:** Cache `Paint` objects that don't depend on `progress` as instance fields set
once in the painter's constructor; only the objects whose *values* genuinely change per-frame
(the sky gradient's colors, the disc's fill color) need reconstruction each call. Keep
`shouldRepaint` narrow (Pitfall 2) so repaints are skipped entirely when nothing changed.

**Warning signs:** DevTools Performance view showing frame-time creep over a multi-minute manual
test run, most visible on the Sunrise scene (28 stars + moon + sun + gradient, all potentially
progress-driven).

## Code Examples

### Sunrise formulas (clamped)

```dart
// lib/scenes/sunrise/sunrise_painter.dart
double starOpacity(double progress) => (1 - progress * 2.3).clamp(0.0, 1.0);
double moonOpacity(double progress) => (1 - progress * 1.7).clamp(0.0, 1.0);

/// top: 86% at p=0 down to 22% at p=1, per design doc "top = (86 - p*64)%".
double sunTopFraction(double progress) => (86 - progress * 64) / 100;

Color hillColor(double progress) =>
    Color.lerp(const Color(0xFF26314F), const Color(0xFF6E9060), progress)!;
```
Source for formulas: `[CITED: design/README.md §"D. Running — Night to Sunrise"]` (locked, final
per D-01). Clamping is this research's own correctness addition, per Pitfall 3.

### Arrival mechanic (Walking Home / Car on a Road, shared)

```dart
// lib/scenes/walk/walk_painter.dart (and reused by car_painter.dart)
/// left = 6 + p*62%, per design doc §E/§F. p is TimerController.progress,
/// already clamped to 0..1 upstream (TimerController._rawFraction), but
/// re-clamped here defensively since this function may be called with
/// values from other call sites in future (e.g. a scene preview).
double arrivalLeftFraction(double progress) =>
    (6 + progress.clamp(0.0, 1.0) * 62) / 100;
```
Source: `[CITED: design/README.md §"E. Running — Walking Home", §"F. Running — Car on a Road"]`
(locked, final per D-01).

### Disc color-zone function

See Pattern 3 above for the full `discColorForRemaining` implementation
`[CITED: design/README.md §"C. Running — Shrinking Disc"]` (locked, final per D-01).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| `Color.withOpacity(double)` | `Color.withValues(alpha: double)` | Flutter deprecated `withOpacity` in favor of `withValues` to avoid precision loss `[CITED: api.flutter.dev; flutter/flutter issues #154491, #160592, #164991]` | This codebase already uses `withValues(alpha: ...)` in `scene_preview.dart` — follow that convention in all four new scenes, do not introduce `withOpacity` calls |

**Deprecated/outdated:** `Color.withOpacity` — still functions but is the older API; this
project's own `scene_preview.dart` already establishes `withValues(alpha:)` as the house style.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | Decorative loop periods (twinkle ~2–3s, bob ~0.62s, spin ~0.7s) are treated as reasonable defaults consistent with the design doc's qualitative language and its own CSS keyframe durations, not independently re-verified against a canonical UX source | Decorative Loop-Animation Feel section, Pattern 2 | Low — CONTEXT.md D-02 already accepts these as Claude's Discretion defaults; if the human end-of-phase device check finds them feeling off-tone, timings are a one-line tweak, not a structural change |
| A2 | Community/blog-sourced guidance on `Gradient`/`Shader` recreation cost (Pitfall 5) is directional, not backed by an official Flutter performance benchmark for this specific case | Common Pitfall 5 | Low-Medium — if the actual per-frame cost turns out to be negligible on target devices, the caching recommendation is still harmless defensive practice, just possibly unnecessary effort |

**All other claims in this research are either `[CITED]` from `design/README.md`/official Flutter
docs, or `[VERIFIED]` by direct inspection of this project's own source
(`lib/timer/timer_controller.dart`, `lib/scenes/scene_preview.dart`, `pubspec.yaml`).**

## Open Questions

1. **Exact device(s) available for the D-03 human end-of-phase smoothness check**
   - What we know: STATE.md already flags "Needs real low/mid-end Android device (API 24–28)" as
     a Blocker/Concern for this phase.
   - What's unclear: Whether such a device is actually available to the person running
     `/gsd-verify-work` for this phase, or whether a throttled emulator/profile will have to
     substitute.
   - Recommendation: Planner should include an explicit `checkpoint:human-verify` task for the
     device check, with an emulator-throttled-profile fallback noted as a lower-confidence
     substitute if no physical device is available.

2. **Whether `RunningScreen`/`SceneHost` composition (this phase) vs. per-scene `Ticker` (this
   research's recommendation) should own the phase-based ticker start/stop**
   - What we know: Pattern 1 places the ticker inside each scene's own `State` for encapsulation
     (mirrors "scenes are self-contained" from `ARCHITECTURE.md`).
   - What's unclear: Whether a shared ticker hosted once in `SceneHost` and passed down via
     `InheritedWidget`/constructor would reduce duplication across the four scenes (all four need
     identical start/stop-on-phase-change logic).
   - Recommendation: Leave as Claude's Discretion at planning time — either a shared base class
     (`SceneRendererState<T>` as sketched in Pattern 1, inherited by all four) or a single ticker
     hosted in `SceneHost` and passed as a `Listenable` are both valid; the base-class approach
     shown above is recommended as it requires zero changes to the existing `SceneRenderer`
     contract's "progress in" simplicity from the outside.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter/Dart SDK | All scene implementation | ✓ | 3.18.0-18.0.pre.54+ / Dart 3.10.7+ (already used in Phases 1–2) | — |
| Real low/mid-end Android device (API 24–28) | SCENE-05 human smoothness check (D-03) | Unconfirmed — flagged as open Blocker/Concern in STATE.md since Phase 3 was scoped | — | Throttled emulator / DevTools "Highlight repaints" + Performance view on any available device, clearly marked lower-confidence than a real low-end device |

**Missing dependencies with no fallback:** None — the device check has a documented (if
lower-confidence) fallback.

**Missing dependencies with fallback:**
- Real low/mid-end Android device — throttled emulator profile is a viable substitute for
  development iteration, but the phase's actual end-of-phase gate should still prefer a real
  device per D-03/STATE.md.

## Validation Architecture

### Test Framework

| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter SDK) |
| Config file | none — uses Flutter defaults, per `.planning/codebase/TESTING.md` |
| Quick run command | `flutter test test/scenes/` |
| Full suite command | `flutter test` |

### Phase Requirements → Test Map

| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| SCENE-01 | `discColorForRemaining` returns correct zone/lerp at r=0.6/0.35/0.1 boundaries | unit | `flutter test test/scenes/disc/disc_painter_test.dart` | ❌ Wave 0 |
| SCENE-01 | `DiscScene` renders without throwing across a 0.0→1.0 progress sweep | widget | `flutter test test/scenes/disc/disc_scene_test.dart` | ❌ Wave 0 |
| SCENE-02 | `starOpacity`/`moonOpacity`/`sunTopFraction`/`hillColor` never produce an out-of-range value across 0..1 | unit | `flutter test test/scenes/sunrise/sunrise_painter_test.dart` | ❌ Wave 0 |
| SCENE-02 | `SunriseScene` renders without throwing across a 0.0→1.0 progress sweep (guards the negative-opacity pitfall) | widget | `flutter test test/scenes/sunrise/sunrise_scene_test.dart` | ❌ Wave 0 |
| SCENE-03 | `arrivalLeftFraction(0.0) == 0.06`, `arrivalLeftFraction(1.0) == 0.68` (arrival at time-up) | unit | `flutter test test/scenes/walk/walk_painter_test.dart` | ❌ Wave 0 |
| SCENE-04 | `arrivalLeftFraction` shared/reused correctly by car scene; car renders without throwing across 0..1 sweep | unit + widget | `flutter test test/scenes/car/car_painter_test.dart` | ❌ Wave 0 |
| SCENE-05 | `sceneFor(theme, progress)` registry returns the correct concrete widget for all 4 `SceneTheme` values | unit | `flutter test test/scenes/scene_registry_test.dart` | ❌ Wave 0 |
| SCENE-05 | No `GestureDetector`/`InkWell`/tap-reactive ancestor exists anywhere in a mounted scene's subtree | widget | `flutter test test/scenes/scene_renderer_test.dart` | ❌ Wave 0 |
| SCENE-05 | `shouldRepaint` returns `false` when neither progress nor decorative phase changed, `true` when either does | unit | included in each scene's painter test file | ❌ Wave 0 |
| SCENE-05 (smoothness) | Visual motion is smooth/jank-free on a real low/mid-end Android device | manual-only | none — human end-of-phase check per D-03 | N/A |

### Sampling Rate

- **Per task commit:** `flutter test test/scenes/`
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`, plus the human device-smoothness
  checkpoint (D-03) recorded as a UAT item, not an automated gate.

### Wave 0 Gaps

- [ ] `test/scenes/disc/disc_painter_test.dart` — covers SCENE-01
- [ ] `test/scenes/disc/disc_scene_test.dart` — covers SCENE-01
- [ ] `test/scenes/sunrise/sunrise_painter_test.dart` — covers SCENE-02
- [ ] `test/scenes/sunrise/sunrise_scene_test.dart` — covers SCENE-02
- [ ] `test/scenes/walk/walk_painter_test.dart` — covers SCENE-03
- [ ] `test/scenes/car/car_painter_test.dart` — covers SCENE-04
- [ ] `test/scenes/scene_registry_test.dart` — covers SCENE-05 (registry contract)
- [ ] `test/scenes/scene_renderer_test.dart` — covers SCENE-05 (no-gesture-handler assertion)
- [ ] No shared test helper yet for "pump a scene across a progress sweep without
      `pumpAndSettle`" — worth a small `test/support/progress_sweep.dart` helper shared across all
      four scene test files (avoids duplicating the pump-at-fixed-durations loop four times)

## Security Domain

### Applicable ASVS Categories

This phase is pure client-side rendering with zero network, authentication, or persisted-secret
surface — consistent with the project's "no accounts, no network, fully local" constraints
(`.planning/REQUIREMENTS.md` Out of Scope table). Most ASVS categories are not applicable.

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | No auth surface anywhere in this app (single-device, no accounts) |
| V3 Session Management | No | No sessions — `TimerController` is in-memory app state, not a security session |
| V4 Access Control | No | No user roles/permissions; parent vs. child is a UX distinction (long-press gate, Phase 4), not an access-control boundary |
| V5 Input Validation | Marginally | The only "input" this phase handles is `TimerController.progress` (already clamped upstream) and the design doc's fixed formulas — validation here means defensive `.clamp()` calls on derived values (opacity, position), not user-input sanitization; no external/untrusted input reaches this phase |
| V6 Cryptography | No | No secrets, no data at rest for this phase (no persistence added here) |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| N/A — no injection/tampering surface | — | This phase has no parsers, no deserialization, no network/file I/O; the only "threat" analog is a correctness bug (unclamped opacity crashing the render), already covered under Common Pitfalls, not a security control |

## Sources

### Primary (HIGH confidence)
- `design/README.md` §§C–F, §"Design Tokens", §"Interactions & Behavior" — exact colors,
  geometry, motion formulas (project source of truth, final per D-01)
- `lib/timer/timer_controller.dart` — verified 200ms `_tickInterval`, pure-getter `progress`
  computation, `TimerPhase` semantics (read directly, this session)
- `lib/scenes/scene_preview.dart` — verified existing `withValues(alpha:)` convention,
  `LinearGradient`/`RadialGradient` usage patterns already established in this codebase
- `.planning/research/ARCHITECTURE.md` — `SceneRenderer` contract, `scene_registry.dart`,
  Anti-Pattern 1 (scenes never reach into `TimerController`)
- `.planning/research/PITFALLS.md` — Pitfall 3 (CustomPainter over widget-tree animation),
  Pitfall 5 (`pumpAndSettle` vs. infinite loops)

### Secondary (MEDIUM confidence)
- Context7 `/flutter/website` — `AnimatedBuilder`/`addListener` idioms, `shouldRepaint`
  field-comparison idiom (`SignaturePainter`, `ParallaxFlowDelegate` examples), `tester.pump()` vs
  `tester.pumpAndSettle()` testing-cookbook distinction

### Tertiary (LOW confidence)
- WebSearch: community guidance on `Gradient`/`Shader` recreation cost and `RepaintBoundary`
  usage (no official Flutter benchmark found; treat as directional, see Assumption A2)
- WebSearch: `flutter/flutter` GitHub issues confirming `Color.withOpacity`/`withValues` assert
  their argument is within `0.0..1.0` (issue-tracker-sourced, cross-checked against
  api.flutter.dev's own documented behavior)

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — no new packages, entirely existing Flutter SDK primitives already used
  in this codebase
- Architecture: MEDIUM-HIGH — core patterns extend `ARCHITECTURE.md` (already MEDIUM confidence)
  with one directly-verified correction (the 200ms tick finding) grounded in this project's actual
  source code
- Pitfalls: MEDIUM — three of five pitfalls are project-specific corrections/extensions of
  already-verified `PITFALLS.md` items; two (shader recreation cost, opacity assertion) rest on
  WebSearch/issue-tracker sourcing rather than an official performance doc

**Research date:** 2026-07-07
**Valid until:** 30 days (stable Flutter SDK APIs; re-verify sooner if `TimerController`'s tick
interval is changed in a future phase, since Pitfall 1's analysis depends on the current 200ms
value)
