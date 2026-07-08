# Phase 4: Parent Controls & Completion - Research

**Researched:** 2026-07-08
**Domain:** Flutter mobile audio synthesis/playback, custom gesture recognition, modal bottom sheets, animation continuity bug fix
**Confidence:** MEDIUM (HIGH for gesture/sheet/codebase-derived findings; MEDIUM for audio-package choice and Android silent-mode behavior — flagged where relevant)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Mute toggle**
- D-01: Small icon button in the Parent Controls sheet header (near grab handle/title), not a full-width row.
- D-02: Mute state persists across app restarts via the same mechanism as PERSIST-01 (`shared_preferences`).
- D-03: Use standard Material speaker icons (`Icons.volume_up` / `Icons.volume_off`).
- D-04: Default on first launch (no persisted preference) is **unmuted**.

**Chime sound implementation**
- D-05: Real-time synthesized tone (two sine tones, D5 587.33 Hz -> G5 783.99 Hz, ~0.3s apart, gain ramp to ~0.16 over 60ms then exponential decay to ~0 over ~1.1s) — NOT a bundled audio asset.
- D-06: Chime plays through the standard media/notification audio channel and respects the device's silent/vibrate switch and system media volume.
- D-07: If the app returns to foreground already in the `done` phase, the chime still plays on that first foreground reveal (confirms Phase 1 D-02).

**Long-press hold feedback**
- D-08: The 850ms hold is fully silent/invisible until it fires — no scrim, ripple, or build-up affordance.
- D-09: Once `TimerPhase.done`, long-press does nothing — only the single-tap "All done" pill is interactive.

**Decorative loop continuity on pause/resume**
- D-10: Fix the snap — `SceneRenderer`'s decorative loops must resume from the same loop-phase they were frozen at when paused, not restart from phase=0.

### Claude's Discretion
- Exact Flutter package/mechanism for real-time tone synthesis (D-05) — research must evaluate against the "respects silent mode" constraint (D-06).
- Exact fix mechanism for the loop-phase freeze/resume (D-10) — e.g. tracking a `_pausedAtElapsed`/offset in `SceneRendererState` and subtracting it on restart.
- Bottom sheet visual details not already locked by `design/README.md` §G (sheet `#FBF4E8`, `border-radius:30px 30px 0 0`, grab handle, scrim `rgba(40,32,26,0.42)` + 3px blur, button colors `#7FA87A`/`#E0805F`) — only the mute icon's exact padding/placement within the header is Claude's call.
- Whether `GestureDetector.onLongPress` tolerates minor finger drift during the hold — use Flutter's standard long-press recognizer defaults, not a custom slop tolerance.

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope. Play Store readiness (app identity, signing, listing assets) remains Phase 5.
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| CTRL-01 | Hidden ~850ms long-press anywhere on the running screen opens Parent Controls bottom sheet | `RawGestureDetector` + custom `LongPressGestureRecognizer(duration: ...)` pattern (Architecture Patterns §1); `showModalBottomSheet` API (Architecture Patterns §2) |
| CTRL-02 | Sheet offers Pause/Resume, End timer (-> Setup), Keep watching (dismiss), sound mute toggle | Sheet button wiring to existing `TimerController.pause()/resume()/endTimer()` (Code Examples); mute toggle persistence pattern (Architecture Patterns §4) |
| CTRL-03 | Soft two-tone chime on completion (no alarm/celebration); scene settles into end visual | Tone-synthesis + playback stack (Standard Stack, Architecture Patterns §3); edge-triggered "play once" pattern (Architecture Patterns §5); scenes already settle correctly at `progress==1.0` (Runtime/codebase note below) |
| CTRL-04 | Breathing "All done" pill, returns to Setup on tap | Breathing animation pattern (Architecture Patterns §6); replaces `_maybeAutoPopWhenDone` (Common Pitfalls §1) |

Also addresses the Phase 3 carried-forward defect (not a formal REQ ID, tracked in STATE.md Blockers/Concerns and CONTEXT.md D-10): `SceneRenderer`'s decorative loop-phase reset on ticker stop/restart (Common Pitfalls §2, Code Examples).
</phase_requirements>

## Summary

This phase adds two new capabilities to an otherwise-complete Flutter scaffold that currently has **no audio dependency at all** (`pubspec.yaml` confirmed clean): (1) a hidden long-press gesture that reveals a parent-only bottom sheet, and (2) real-time synthesized two-tone chime playback on timer completion. Neither capability has any precedent in this codebase — `RunningScreen` currently has only a visible back `IconButton` (Phase 3 scaffolding, to be deleted) and no bottom-sheet, gesture-recognizer, or audio code exists anywhere in `lib/`.

For audio, three Flutter packages were evaluated for lowest-friction real-time tone synthesis: `audioplayers`, `flutter_soloud`, and `just_audio`. **`audioplayers` (^6.8.1) with its `BytesSource` API is the recommended choice** — it plays a raw in-memory byte buffer directly (no temp file), defaults to Android's `USAGE_MEDIA`/`STREAM_MUSIC` audio attributes (follows the device media-volume slider), and needs no native build changes (pure platform-channel plugin, no NDK/FFI). `flutter_soloud` is a native C++ engine built for games (3D audio, effects) — correct but disproportionate footprint for one short UI sound. `just_audio`'s custom-source API (`StreamAudioSource`) is explicitly marked `@experimental` and relies on an internal local HTTP proxy on some platforms — more moving parts for no benefit here.

An important nuance surfaced during research: **Android's ringer "silent mode" does not silence the media stream.** D-06's phrase "respects the device's silent/vibrate switch" is only partially achievable via the OS audio stream on Android (unlike iOS, which has a true hardware mute switch that `AVAudioSessionCategory.ambient` can honor). The actual mechanism satisfying the product intent on Android is the **in-app mute toggle** (D-01/D-02), not reliance on the ringer switch — the chime should still use the default media-stream audio attributes (so it *does* respect the media-volume slider a parent explicitly sets), but the planner should not assume the OS ringer-silent switch will silence it. This is flagged as an assumption needing no further user confirmation (it's a factual Android platform behavior, not a product decision), but the plan's verification steps should test against media volume, not ringer silent mode.

For the long-press gesture, `GestureDetector.onLongPress` does not expose a duration parameter — the 850ms threshold requires `RawGestureDetector` with a custom `LongPressGestureRecognizer(duration: Duration(milliseconds: 850))`. The bottom sheet uses `showModalBottomSheet`, but its `barrierColor` alone does **not** produce the ~3px blur specified in `design/README.md` — that requires `backgroundColor: Colors.transparent` plus a `BackdropFilter(filter: ImageFilter.blur(...))` wrapping the sheet content, a known pattern with a documented Flutter jank/flicker caveat (Common Pitfalls §3).

For the carried-forward D-10 defect, reading `SceneRendererState` confirms the root cause directly: the `Ticker`'s `elapsed` argument restarts from zero every time `_ticker.start()` is called after a `stop()`, and `loopPhase()` derives entirely from that per-segment `elapsed` value with no accumulated offset — exactly the observed "snap to phase-0" bug. The fix is a small, local, single-file change (Code Examples).

**Primary recommendation:** Add `audioplayers: ^6.8.1` as the only new dependency; synthesize the chime as hand-built 16-bit PCM/WAV bytes in pure Dart (fully unit-testable without any platform channel); wrap chime playback behind a small injectable interface (mirroring the existing `ScreenWake`/`NoopScreenWake` pattern) so widget tests never touch the real plugin; use `RawGestureDetector` + `LongPressGestureRecognizer(duration: 850ms)` for the hidden trigger; fix D-10 with an accumulated-offset field in `SceneRendererState`.

## Architectural Responsibility Map

This is a single-tier Flutter mobile app (no backend/frontend split) — "tiers" are adapted to this app's existing layers (per `.claude/CLAUDE.md`'s Architecture section: UI/Screen layer, domain/controller layer, platform-plugin layer).

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Long-press detection + bottom sheet UI | Screen (composition root: `RunningScreen`) | — | Per existing doc comment, composition-root responsibilities (gestures, navigation) live in `RunningScreen`, never inside a scene (SCENE-05 boundary already established) |
| Pause/Resume/End timer actions | Domain (`TimerController`, existing) | Screen (button `onPressed` wiring) | `TimerController` already exposes fully-tested `pause()`/`resume()`/`endTimer()` — no controller API changes needed, sheet buttons call these directly |
| Mute toggle state (in-memory + persisted) | New small domain object (e.g. `SoundPreferences`/`ValueNotifier<bool>`) | Platform (`shared_preferences`, existing) | Mirrors `TimerController`-as-`ChangeNotifier` and `SetupPreferences` precedents; must NOT live inside `TimerController` (keeps domain timer logic free of audio/UI concerns) |
| Chime tone synthesis (PCM/WAV byte generation) | New pure-Dart utility (no Flutter/plugin imports) | — | Deterministically unit-testable without any platform channel; keep entirely separate from playback |
| Chime playback (plugin call) | Platform-plugin wrapper (new `ChimePlayer` interface + `AudioPlayersChimePlayer` impl) | Screen (`RunningScreen` triggers play-once on phase transition) | Mirrors existing `ScreenWake`/`NoopScreenWake` interface-wraps-a-plugin shape (`lib/timer/screen_wake.dart` precedent) — the rest of the app never touches `audioplayers` directly |
| Decorative loop-phase freeze/resume fix (D-10) | `SceneRendererState` (existing shared base) | — | Single shared base every scene extends; the fix belongs here once, not per-scene (already established Phase 3 pattern) |
| "All done" breathing pill | Screen (`RunningScreen`) | — | New UI element, not a scene concern — scenes only render `progress`-driven pixels (SCENE-05) |

## Standard Stack

### Core

| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| `audioplayers` | ^6.8.1 [ASSUMED: package selection from training knowledge, corroborated by WebSearch — see Package Legitimacy Audit; version/publish-date VERIFIED via pub.dev API, published 2026-06-27] | Play the in-memory synthesized chime bytes via `BytesSource` | Most widely used general-purpose Flutter audio plugin (1M+ weekly downloads, 3,430 likes, verified publisher); supports raw in-memory bytes with no temp file and no native/NDK build changes |

### Supporting

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| `shared_preferences` | ^2.5.5 (already in `pubspec.yaml`) | Persist the mute toggle boolean | Reuse — do not add a second persistence package; extend the existing `SetupPreferences` load/write pattern (D-02) |
| `flutter/gestures.dart` (SDK, no new dependency) | bundled with Flutter SDK | `LongPressGestureRecognizer(duration:)` via `RawGestureDetector` | Standard SDK API — no package needed for a custom long-press threshold |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `audioplayers` `BytesSource` | `flutter_soloud` (^4.0.12) | Purpose-built for games (3D audio, real-time waveform gen, FFT) — powerful but requires native C++/NDK build (heavier APK, longer build), disproportionate for one short two-tone sound. [VERIFIED: pub.dev API — 4.0.12, published 2026-06-30, 587 likes, ~55.8k downloads] |
| `audioplayers` `BytesSource` | `just_audio` (^0.10.6) + custom `StreamAudioSource` | `StreamAudioSource` is marked `@experimental` in its own docs [CITED: github.com/ryanheise/just_audio README/AudioSources.md via Context7] and some platforms proxy it through a local HTTP server internally — more indirection for no benefit over a direct byte buffer. Also pulls in `audio_session`/`rxdart`/`path_provider` transitively. [VERIFIED: pub.dev API — 0.10.6, published 2026-06-29, 4,100+ likes, 952k weekly downloads] |
| Hand-rolled WAV header + PCM synth | A dedicated Dart tone-gen package (e.g. `wave_generator`) | A dedicated package saves ~30 lines of header-construction code but adds a dependency for a one-time, fully-spec'd (frequencies/envelope locked by design doc) computation — hand-rolling here is the *simpler* path, not hand-rolling a "solved problem" (see Don't Hand-Roll below for the distinction) |

**Installation:**
```bash
flutter pub add audioplayers
```

**Version verification:** `audioplayers` latest version confirmed via `pub.dev` API this session: **6.8.1, published 2026-06-27** [VERIFIED: pub.dev API]. Re-run `flutter pub add audioplayers` (not a pinned version literal) at planning/execution time in case a newer patch has shipped since this research.

## Package Legitimacy Audit

> The automated `package-legitimacy check` seam only supports `npm`/`pypi`/`crates` ecosystems — Dart/`pub` is not supported. The table below was assembled manually via `pub.dev` API/page fetches this session.

| Package | Registry | Age/Recency | Downloads/Likes | Source Repo | Verdict | Disposition |
|---------|----------|-------------|------------------|--------------|---------|-------------|
| `audioplayers` | pub.dev | v6.8.1 published 2026-06-27, verified publisher `blue-fire.xyz` | 1M+ weekly downloads, 3,430 likes, 150 pub points | github.com/bluefireteam/audioplayers | OK | Approved |
| `flutter_soloud` | pub.dev | v4.0.12 published 2026-06-30 | ~55.8k downloads, 587 likes, 160 pub points | github.com/alnitak/flutter_soloud | OK | Not selected (heavier footprint, see Alternatives) |
| `just_audio` | pub.dev | v0.10.6 published 2026-06-29, verified publisher `ryanheise.com` | 952k weekly downloads, 4,100+ likes, 150 pub points | github.com/ryanheise/just_audio | OK | Not selected (experimental custom-source API, see Alternatives) |

**Packages removed due to [SLOP] verdict:** none.
**Packages flagged as suspicious [SUS]:** none.

*All three package names above were identified from training knowledge/WebSearch, not from an automated authoritative-source scan — per provenance rules they are tagged `[ASSUMED]` in the Standard Stack table above despite the clean manual `pub.dev` verification. The planner should add a `checkpoint:human-verify` before `flutter pub add audioplayers` runs, consistent with the `[ASSUMED]` package gating rule.*

## Architecture Patterns

### System Architecture Diagram

```
Parent's finger on screen
        |
        v
[RawGestureDetector + LongPressGestureRecognizer(duration: 850ms)]  <-- wraps RunningScreen's Stack
        |  (850ms elapsed, no drift)
        v
showModalBottomSheet(...) ---> Parent Controls sheet
        |            |            |            |
        v            v            v            v
   Pause/Resume   End timer   Keep watching   Mute toggle icon
   (TimerController) (TimerController +   (Navigator.pop     (SoundPreferences /
                     Navigator.pop        -- no-op besides   persisted bool via
                     back to Setup)        dismiss)          shared_preferences)

Independently, every ~200ms (or on foreground-resume via TimerLifecycleBinder):
TimerController.syncToWallClock()
        |
        v
   phase -> TimerPhase.done (edge, once)
        |                                  \
        v                                   v
RunningScreen detects the done-EDGE   sceneFor(theme) already renders the
(not just done-LEVEL, to fire once)   correct end visual because every
        |                              scene is a pure function of
        v                              progress, and progress is clamped
ChimePlayer.play(toneBytes)            to 1.0 at done (no scene code change
  (skipped if muted)                   needed for the "settles into end
        |                              state" part of CTRL-03)
        v
"All done" breathing pill fades in (AnimationController, repeat(reverse:true))
        |
        v
   Parent taps pill -> TimerController.endTimer() + Navigator.pop() -> Setup
```

### Recommended Project Structure
```
lib/
├── audio/
│   ├── chime_synth.dart       # pure-Dart: generates 16-bit PCM + WAV header bytes for the two-tone chime (no Flutter imports -- unit testable in isolation)
│   ├── chime_player.dart       # abstract ChimePlayer interface (mirrors ScreenWake shape)
│   └── audioplayers_chime_player.dart  # concrete impl wrapping package:audioplayers
├── settings/
│   └── setup_preferences.dart  # extend with a third persisted scalar: soundOn (bool)
├── screens/
│   └── running_screen.dart     # add: RawGestureDetector, showModalBottomSheet call, done-edge chime trigger, breathing pill
└── scenes/
    └── scene_renderer.dart      # fix D-10: accumulated loop-phase offset across ticker stop/start
```

### Pattern 1: Custom-duration long-press via RawGestureDetector
**What:** `GestureDetector.onLongPress` uses a fixed ~500ms threshold (`kLongPressTimeout`) with no way to override it directly. `LongPressGestureRecognizer` itself accepts a `duration: Duration?` constructor parameter [CITED: api.flutter.dev/flutter/gestures/LongPressGestureRecognizer-class.html].
**When to use:** Any time a threshold other than the SDK default is required — exactly CTRL-01's 850ms.
**Example:**
```dart
// Source: Flutter SDK gestures API (LongPressGestureRecognizer.duration param), CITED
RawGestureDetector(
  gestures: <Type, GestureRecognizerFactory>{
    LongPressGestureRecognizer:
        GestureRecognizerFactoryWithHandlers<LongPressGestureRecognizer>(
      () => LongPressGestureRecognizer(duration: const Duration(milliseconds: 850)),
      (recognizer) {
        recognizer.onLongPress = _openParentControls;
      },
    ),
  },
  behavior: HitTestBehavior.opaque, // whole screen, not just painted pixels
  child: Positioned.fill(child: sceneFor(widget.theme)),
)
```
Per D-08 (no build-up affordance) and the "Claude's Discretion" note on drift tolerance, use `LongPressGestureRecognizer`'s default slop tolerance — do not set a custom `postAcceptSlopTolerance`.

### Pattern 2: Blurred modal bottom sheet scrim
**What:** `showModalBottomSheet`'s `barrierColor` parameter only sets a flat color — it does **not** blur content behind the barrier [CITED: WebSearch cross-checked against multiple sources incl. flutter/flutter GitHub issues #78356, #160963, #162006]. To get the ~3px blur specified in `design/README.md` §G, wrap the sheet's own content in a `BackdropFilter`, with `showModalBottomSheet(backgroundColor: Colors.transparent, ...)`.
**When to use:** CTRL-01's sheet, matching `design/README.md`'s `scrim: rgba(40,32,26,0.42) + 3px blur`.
**Example:**
```dart
// Pattern synthesized from CITED sources (flutter.dev docs + community writeups);
// verify jank-free on a real device per the project's established smoothness-check
// precedent (Phase 3 D-03).
showModalBottomSheet<void>(
  context: context,
  backgroundColor: Colors.transparent,
  barrierColor: const Color(0x6B28201A), // rgba(40,32,26,0.42)
  isDismissible: true,
  builder: (sheetContext) => BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
    child: Container(
      decoration: const BoxDecoration(
        color: AppTokens.sheetBg, // new token: #FBF4E8
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: /* grab handle, title, Pause/Resume, End timer, Keep watching, mute icon */,
    ),
  ),
);
```
**Known caveat:** `BackdropFilter` + `BottomSheet`'s default `clipBehavior` can silently no-op the blur, and there are open Flutter issues about jank/flicker with `BackdropFilter` on bottom sheets under Impeller [CITED: flutter/flutter#160963, #162006, #78356]. If real-device testing (per this project's established smoothness-check pattern) shows jank, the acceptable fallback is a flat semi-transparent scrim without blur — flag as an explicit tradeoff for the planner/human-verify step, not a silent regression.

### Pattern 3: In-memory tone synthesis + playback (no audio asset)
**What:** Generate 16-bit PCM samples for the two sine tones (with the gain-ramp/decay envelope) in pure Dart, prepend a minimal RIFF/WAV header, and hand the resulting `Uint8List` to `audioplayers`' `BytesSource` [CITED: Medium walkthrough cross-checked against `audioplayers` official `getting_started.md` "Sources" section via Context7, which confirms `BytesSource` is one of the four first-class source types alongside `UrlSource`/`DeviceFileSource`/`AssetSource`].
**When to use:** CTRL-03's chime — matches D-05 exactly (real-time synthesis, not a bundled asset).
**Example:**
```dart
// chime_synth.dart -- pure Dart, no Flutter/plugin imports, fully unit-testable
Uint8List synthesizeChime() {
  const sampleRate = 44100;
  // D5 587.33 Hz then G5 783.99 Hz, ~0.3s apart, per design/README.md
  final samples = <int>[];
  _appendTone(samples, frequencyHz: 587.33, sampleRate: sampleRate);
  _appendSilence(samples, seconds: 0.3, sampleRate: sampleRate);
  _appendTone(samples, frequencyHz: 783.99, sampleRate: sampleRate);
  return _wrapAsWav(pcm16: samples, sampleRate: sampleRate, channels: 1);
}

// audioplayers_chime_player.dart
class AudioplayersChimePlayer implements ChimePlayer {
  final AudioPlayer _player = AudioPlayer();
  @override
  Future<void> play(Uint8List wavBytes) async {
    await _player.play(BytesSource(wavBytes));
  }
}
```
Per D-06, leave `AudioContextAndroid` at its default `usageType: USAGE_MEDIA` (maps to `STREAM_MUSIC`) [CITED: github.com/bluefireteam/audioplayers `audio_context_config.dart`/`AudioContextAndroid.kt` via Context7] — this follows the device's media-volume slider. **Do not** set `respectSilence: true`: on Android that flag's iOS-oriented semantics do not map to an equivalent "ringer silent" concept the way they do on iOS, and this is an Android-only v1.

### Pattern 4: Extend the existing persisted-preferences object
**What:** `SetupPreferences` already loads/validates two scalars (`durationMin`, `theme`) via one `SharedPreferences.getInstance()` call in `main()` before `runApp()`. Add a third scalar `soundOn` (bool, default `true` per D-04) to the same class rather than introducing a second preferences object/load call.
**When to use:** CTRL-02's mute toggle persistence (D-02).
**Example:**
```dart
// setup_preferences.dart -- extend, following the exact validate-on-every-read
// shape already used for durationMin/theme (T-02-02 tampering defense)
const String _soundOnKey = 'soundOn';

class SetupPreferences {
  const SetupPreferences({
    required this.durationMin,
    required this.theme,
    this.soundOn = true, // D-04 default
  });
  final bool soundOn;
  // load(): prefs.getBool(_soundOnKey) ?? true, wrapped in the same try/catch
  //         fallback shape as durationMin/theme.
  // A new persistSoundOn(bool) method (always writes -- not gated behind
  // showCustom like durationMin) since mute has no "custom vs preset" concept.
}
```

### Pattern 5: Edge-triggered once-only actions (chime, pill reveal)
**What:** `RunningScreen` already has a proven idiom for "do X exactly once when a state transition happens" — the `_leftScreen` boolean guard around `_leaveOnce()`. Generalize this shape for the chime: a `bool _chimePlayed = false` field, set only when the *previous* watched phase was not `done` and the *current* one is.
**When to use:** CTRL-03 (play chime once per completion, including D-07's foreground-reveal case) — must NOT replay on every rebuild while `phase == done` stays true (the controller's `ChangeNotifier` can notify more than once while parked in `done`, e.g. from an unrelated future `notifyListeners()`).
**Example:**
```dart
// Source: derived directly from reading lib/screens/running_screen.dart in
// this session -- VERIFIED against actual codebase, not external docs.
TimerPhase? _previousPhase;
bool _chimePlayed = false;

void _maybeReactToPhaseChange(TimerPhase phase) {
  final justCompleted = phase == TimerPhase.done && _previousPhase != TimerPhase.done;
  _previousPhase = phase;
  if (justCompleted && !_chimePlayed) {
    _chimePlayed = true;
    if (!widget.muted) unawaited(_chimePlayer.play(_chimeBytes));
  }
}
```
This same `justCompleted` edge is also the point where `_maybeAutoPopWhenDone`'s auto-pop call must be **removed** (see Common Pitfalls §1) in favor of revealing the breathing pill instead.

### Pattern 6: Breathing pill animation
**What:** No `AnimationController` exists anywhere in this codebase yet — every existing animated element (scene decorative loops) deliberately uses the shared `SceneRenderer` `Ticker`/`loopPhase` idiom instead (per `03-RESEARCH.md` Pattern 2, referenced three times in `lib/scenes/`). The "All done" pill is **not** a scene decorative loop — it's composition-root UI (per Architectural Responsibility Map) — so introducing a plain `AnimationController` here (via `SingleTickerProviderStateMixin` on `_RunningScreenState`) does not violate that established "never a second AnimationController" scene convention; that convention is scoped to `SceneRendererState` subclasses only.
**When to use:** CTRL-04's `breathe: scale 1 -> 1.05 -> 1, 2.8s ease-in-out infinite` [locked, `design/README.md` §H].
**Example:**
```dart
// _RunningScreenState extends State<RunningScreen> with SingleTickerProviderStateMixin
late final AnimationController _breatheController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 2800),
)..repeat(reverse: true);

late final Animation<double> _breatheScale = CurvedAnimation(
  parent: _breatheController,
  curve: Curves.easeInOut,
).drive(Tween<double>(begin: 1.0, end: 1.05));
```
Dispose `_breatheController` in `dispose()`. Only start `.repeat()` once `phase == TimerPhase.done` is reached (or always run it and gate visibility) — starting it unconditionally at `initState` is simpler and harmless since the pill itself is only shown/opaque once done.

### Anti-Patterns to Avoid
- **Playing the chime from inside a scene painter/`SceneRendererState` subclass:** audio playback is a composition-root/platform concern, not a "progress in, pixels out" scene concern (SCENE-05 boundary) — keep it in `RunningScreen`.
- **Storing `soundOn` on `TimerController`:** keeps the domain timer state machine free of unrelated audio/UI concerns, consistent with the existing `ScreenWake` abstraction already being injected rather than hard-coded into the controller.
- **Calling `AudioPlayer()` directly from widget code/tests:** always go through the `ChimePlayer` interface so widget tests never hit a real platform channel (see Validation Architecture).

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Custom long-press timing/drift tolerance | A manual `GestureDetector.onTapDown` + `Timer` + drift-distance tracker | `LongPressGestureRecognizer(duration:)` (SDK) | The SDK recognizer already handles pointer-drift cancellation, multi-pointer edge cases, and hit-testing correctly; a hand-rolled `Timer`-based version would need to reinvent all of that (explicitly called out as Claude's Discretion to use SDK defaults, not a custom slop tolerance) |
| Modal dismiss/back-button/route-stack interaction for the sheet | A custom `Overlay`/`OverlayEntry` stack | `showModalBottomSheet` (SDK) | Handles focus, back-button-to-dismiss, `Navigator.pop(value)` return-value plumbing, and safe-area/keyboard-avoidance automatically |
| WAV/PCM audio decoding or a custom playback engine | A hand-rolled `AudioTrack`/platform-channel audio pipeline | `audioplayers`' `BytesSource` | Correct byte-buffer playback across the plugin's supported platforms, plus Android audio-focus/attribute handling, is already solved — only the *tone generation* (locked exact frequencies/envelope) is legitimately unique to this app and worth hand-writing |

**Key insight:** The chime's *tone-generation math* (the two exact frequencies + envelope from `design/README.md`) is inherently one-of-a-kind to this app and small enough (~30-40 lines) that hand-writing it is simpler and more testable than adding a tone-generation package — but everything *around* that math (gesture recognition, modal presentation, byte-buffer playback) is a solved, general problem with SDK/plugin support and should not be reinvented.

## Common Pitfalls

### Pitfall 1: `_maybeAutoPopWhenDone` still popping the screen on completion
**What goes wrong:** `RunningScreen`'s existing `_maybeAutoPopWhenDone` calls `_leaveOnce()` (which pops back to Setup) the instant `phase == TimerPhase.done`. If this method is left in place unmodified, the screen will pop before the parent ever sees the breathing "All done" pill or hears the chime, breaking CTRL-03/CTRL-04 outright.
**Why it happens:** It was Phase 3 scaffolding written before there was a real completion UI to show.
**How to avoid:** Remove the auto-pop call entirely; replace it with the done-edge chime trigger (Pattern 5) and conditional rendering of the breathing pill. The *only* remaining path back to Setup from `done` is the parent tapping the pill (`endTimer()` + `Navigator.pop()`), and from running/paused it's the sheet's "End timer" button.
**Warning signs:** A widget test that pumps a controller into `done` and finds itself back on `SetupScreen` instead of seeing the pill.

### Pitfall 2: Decorative loop-phase reset on pause/resume (D-10, carried from Phase 3)
**What goes wrong:** `SceneRendererState._onTick` sets `_elapsedSinceStart = elapsed` directly from the `Ticker`'s own `elapsed` argument. Flutter's `Ticker` measures `elapsed` from the instant `start()` was most recently called — so every `_ticker.stop()` + later `_ticker.start()` cycle (which is exactly what happens on pause -> resume, per `didChangeDependencies`) resets `elapsed` back toward zero, and `loopPhase()` (`elapsedSinceStart % period`) visibly snaps to phase-0. [VERIFIED: codebase read of `lib/scenes/scene_renderer.dart` lines 44-74, corroborated by the exact defect already documented in `.planning/STATE.md` and `03-REVIEW.md` WR-01 — this is an observed, reproduced bug, not a theoretical one.]
**Why it happens:** No accumulated offset is kept across ticker stop/start segments; only the current segment's raw `elapsed` is tracked.
**How to avoid:** Add an accumulator field (e.g. `Duration _loopBaseOffset = Duration.zero`) that captures the last-seen segment elapsed *before* stopping the ticker, and add it back on the next segment's ticks:
```dart
// In didChangeDependencies, before _ticker.stop():
_loopBaseOffset += _elapsedSinceStart - _segmentStartOffset; // or simpler: track directly
// In _onTick:
_elapsedSinceStart = _loopBaseOffset + elapsed;
```
(See Code Examples for the concrete minimal diff.)
**Warning signs:** Any widget test that pauses then resumes a scene and asserts `loopPhase()` continuity across the boundary — this is exactly the Wave 0 test gap to add (see Validation Architecture).

### Pitfall 3: `BackdropFilter` blur silently doing nothing, or janking, on the Parent Controls sheet
**What goes wrong:** The blur either doesn't render (if the `BottomSheet`'s `clipBehavior` isn't `Clip.none`/compatible) or introduces visible jank/flicker on first open, especially under the Impeller renderer. [CITED: flutter/flutter GitHub issues #160963, #162006, #78356 — cross-checked via WebSearch]
**Why it happens:** `BackdropFilter` forces an extra compositing pass; known open Flutter engine issues affect bottom sheets specifically.
**How to avoid:** Test the blurred sheet open/close on a real Android device early (mirrors this project's established Phase 3 D-03 smoothness-check precedent) before treating the 3px blur as locked-in; have a documented fallback (flat scrim, no blur) ready if jank appears, and flag the decision to the human rather than silently downgrading.
**Warning signs:** Visible flicker or a stutter on the sheet's opening animation on-device (won't necessarily show up in `flutter test`'s software rendering).

### Pitfall 4: Assuming Android's ringer silent mode mutes the chime
**What goes wrong:** Implementing/verifying D-06 by toggling the phone's ringer to silent and expecting the chime to stop — it won't, because Android's silent/DND mode only affects the ringtone/notification streams, not `STREAM_MUSIC`/`USAGE_MEDIA`. [CITED: WebSearch, cross-checked across two independent queries plus the `AudioContextAndroid.kt` source snippet confirming `USAGE_MEDIA -> STREAM_MUSIC` mapping via Context7]
**Why it happens:** iOS has a true hardware mute switch with OS-level media-ducking semantics; Android's "silent mode" concept is narrower (ringer/notification only) by design.
**How to avoid:** Verify D-06 against the device's **media volume slider** (which the chime correctly respects via default `USAGE_MEDIA`), and rely on the **in-app mute toggle** (D-01/D-02) as the actual "silence the chime" mechanism on Android. Document this distinction in the plan's verification steps so a human tester doesn't file a false-positive bug.
**Warning signs:** A UAT step that says "put phone on silent, confirm chime doesn't play" will fail/mislead unless it specifies media volume, not ringer silent mode.

### Pitfall 5: `AudioPlayer()` instantiation inside widget tests
**What goes wrong:** `audioplayers`' `AudioPlayer` talks to a real platform channel; instantiating/calling it directly inside a `flutter_test` widget test throws (no platform implementation registered) or requires brittle `MethodChannel` mocking.
**Why it happens:** Plugins assume a running platform; `flutter_test`'s harness has no real platform beneath it.
**How to avoid:** Route all chime playback through the `ChimePlayer` interface (Pattern 3/Architectural Responsibility Map) and inject a no-op/fake implementation in tests — exactly the same shape as the existing `NoopScreenWake` used for `TimerController` tests.
**Warning signs:** `MissingPluginException` in test output.

## Code Examples

### Fixing the loop-phase reset (D-10) — minimal diff to `lib/scenes/scene_renderer.dart`
```dart
// Source: derived from reading the actual current implementation this
// session (VERIFIED: codebase), combined with the general, well-established
// fact that Flutter's Ticker.elapsed restarts from zero on each start()
// after a stop() -- empirically confirmed by the exact bug already observed
// and documented in this project (STATE.md / 03-REVIEW.md WR-01).

abstract class SceneRendererState<T extends SceneRenderer> extends State<T>
    with TickerProviderStateMixin<T> {
  late final Ticker _ticker;
  double _progress = 0.0;
  Duration _elapsedSinceStart = Duration.zero;

  // NEW: accumulates elapsed time across ticker stop/start segments so
  // loopPhase() never resets when the ticker restarts.
  Duration _loopBaseOffset = Duration.zero;

  void _onTick(Duration elapsed) {
    _elapsedSinceStart = _loopBaseOffset + elapsed; // CHANGED
    final fresh = context.read<TimerController>().progress;
    if (fresh != _progress) {
      setState(() => _progress = fresh);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final phase = context.watch<TimerController>().phase;
    if (phase == TimerPhase.running && !_ticker.isTicking) {
      _ticker.start();
    } else if (phase != TimerPhase.running && _ticker.isTicking) {
      _loopBaseOffset = _elapsedSinceStart; // NEW: snapshot before stopping
      _ticker.stop();
    }
  }
  // ... rest unchanged
}
```

### Chime tone synthesis (pure Dart, no platform dependency)
```dart
// Source: synthesized from design/README.md's exact spec (frequencies,
// envelope, timing) -- this is app-specific math, not from an external doc.
import 'dart:math' as math;
import 'dart:typed_data';

Uint8List synthesizeChimeWav({int sampleRate = 44100}) {
  final pcm = BytesBuilder();
  void appendTone(double freqHz, double durationSec) {
    final sampleCount = (sampleRate * durationSec).round();
    for (var i = 0; i < sampleCount; i++) {
      final t = i / sampleRate;
      // Gain envelope: ramp to ~0.16 over 60ms, then exponential decay to
      // ~0 over ~1.1s, per design/README.md.
      final rampMs = 0.06;
      final gain = t < rampMs
          ? 0.16 * (t / rampMs)
          : 0.16 * math.exp(-(t - rampMs) / 0.35); // tuned for ~1.1s decay to ~0
      final sample = gain * math.sin(2 * math.pi * freqHz * t);
      final intSample = (sample * 32767).round().clamp(-32768, 32767);
      pcm.addByte(intSample & 0xFF);
      pcm.addByte((intSample >> 8) & 0xFF);
    }
  }
  appendTone(587.33, 0.5); // D5
  // ~0.3s gap between tone starts per design doc
  appendTone(783.99, 0.5); // G5
  return _wrapPcmAsWav(pcm.toBytes(), sampleRate: sampleRate, channels: 1, bitsPerSample: 16);
}
```
*(Exact envelope/timing constants above are a starting approximation of the locked design-doc spec — the planner/implementer should treat the numeric envelope shape as an implementation detail to tune against the design doc's description, not as a locked formula from this research.)*

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|---------------|--------|
| Bundling a pre-rendered chime `.wav`/`.mp3` asset | Real-time PCM synthesis + `BytesSource` playback | This phase (D-05, user's explicit choice) | No audio asset in `pubspec.yaml`'s `assets:` section; chime logic lives entirely in Dart source, trivially unit-testable and tunable without re-exporting audio files |
| Visible back `IconButton` (Phase 3 scaffolding) | Hidden long-press -> Parent Controls sheet | This phase (CTRL-01/02) | `lib/screens/running_screen.dart`'s `_handleBack`/back-button block is deleted outright, not kept as a fallback |
| Auto-pop-on-done | Chime + settled scene + breathing pill, manual return | This phase (CTRL-03/04) | `_maybeAutoPopWhenDone` removed; `done` becomes a real, visible, dwelled-in state for the first time in this app |

**Deprecated/outdated:** none applicable — this is greenfield capability addition on top of existing Phase 1-3 scaffolding, not a version migration.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | `audioplayers` is the correct/available package name on `pub.dev` for this purpose (vs. a similarly-named or renamed package) | Standard Stack, Package Legitimacy Audit | Low — corroborated this session via `pub.dev` API fetch (version, publisher, download/like counts all resolved successfully), but the *name itself* came from training/WebSearch, not an authoritative-source lookup, per provenance rules |
| A2 | `flutter_soloud` and `just_audio` package names/APIs as described | Standard Stack alternatives | Low — same corroboration caveat as A1; not selected for this phase regardless |
| A3 | Exact envelope/decay-rate constants in the Code Examples' `synthesizeChimeWav` snippet (`0.35` decay-time-constant, `0.5`s per-tone duration) | Code Examples | Medium — these are illustrative starting values, not derived from the design doc's precise math; implementer must tune against `design/README.md`'s stated envelope (ramp 60ms to ~0.16, exponential decay to ~0 over ~1.1s) rather than treat this snippet as final |
| A4 | `LongPressGestureRecognizer`'s default `postAcceptSlopTolerance` is "good enough" for an 850ms hold without a curious child's hand drifting off before it fires | Architecture Patterns §1 | Low — explicitly called out as Claude's Discretion in CONTEXT.md; SDK default is the locked choice per that discretion, so this isn't really open, just noted |

**If this table is empty:** N/A — see entries above; none are high-risk/blocking, all are either corroborated or explicitly delegated to Claude's Discretion already.

## Open Questions

1. **Exact tuning of the chime envelope (ramp/decay constants)**
   - What we know: `design/README.md` specifies gain ramps to ~0.16 over 60ms then exponential decay to ~0 over ~1.1s, applied per-note, two notes ~0.3s apart.
   - What's unclear: The precise decay-rate formula/constant to hit "~0 over ~1.1s" is not given as an exact equation (only descriptive), so any implementation involves picking a decay-rate constant that matches the description closely enough by ear/waveform-inspection.
   - Recommendation: Implement per Code Examples' shape, then have a human listen/compare against the design doc's Web Audio API reference implementation description during verification (this is inherently a "does it sound calm, not alarm-like" qualitative check — appropriate for `checkpoint:human-verify`, not an automated assertion beyond byte-length/non-silence checks).

2. **Whether the blurred scrim (Pitfall 3) survives real-device testing**
   - What we know: The `BackdropFilter` pattern is the standard way to blur behind a Flutter bottom sheet, but has documented jank/flicker issues on some renderer configurations.
   - What's unclear: Whether this specific app (already established as running smoothly per Phase 3 D-03) will hit those issues on the target test device(s).
   - Recommendation: Plan should include an explicit real-device check of the sheet's open/close animation, with the flat-scrim fallback pre-agreed rather than discovered mid-implementation.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Flutter SDK | Entire phase | Yes (existing project) | 3.18.0-18.0.pre.54+ (per `.claude/CLAUDE.md`) | — |
| `audioplayers` pub package | CTRL-03 chime playback | Not yet installed — to be added via `flutter pub add audioplayers` | 6.8.1 (latest as of 2026-06-27) | None needed; standard `pub` install, no native/NDK prerequisite |
| Android device/emulator with a speaker | Manual verification of chime + silent-mode/mute behavior (Pitfall 4) | Assumed available (existing Android build target) | — | — |

**Missing dependencies with no fallback:** none blocking — `audioplayers` is a standard `pub` add with no special native toolchain requirement (unlike `flutter_soloud`, which was rejected partly for this reason).
**Missing dependencies with fallback:** none applicable.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | `flutter_test` (bundled with Flutter SDK, already used throughout `test/`) |
| Config file | none dedicated (no `dart_test.yaml`; conventions live in existing `test/*_test.dart` files) |
| Quick run command | `flutter test test/screens/running_screen_test.dart` (new file) and `flutter test test/scenes/scene_renderer_test.dart` (extended) |
| Full suite command | `flutter test` |

### Phase Requirements -> Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| CTRL-01 | 850ms long-press on the running screen opens the sheet; a shorter press does nothing | widget | `flutter test test/screens/running_screen_test.dart -N "long-press"` | ❌ Wave 0 |
| CTRL-02 | Sheet's Pause/Resume/End timer/Keep watching/mute buttons call the right `TimerController`/persistence methods | widget | `flutter test test/screens/running_screen_test.dart -N "parent controls"` | ❌ Wave 0 |
| CTRL-03 | On `phase == done` (including already-done-on-foreground-resume), chime plays exactly once (via injected fake `ChimePlayer`) unless muted; scene renders its end visual | widget + unit | `flutter test test/screens/running_screen_test.dart -N "chime"` and `flutter test test/audio/chime_synth_test.dart` | ❌ Wave 0 (both files) |
| CTRL-04 | Breathing pill appears at `done`, tapping it calls `endTimer()` and pops to Setup | widget | `flutter test test/screens/running_screen_test.dart -N "all done pill"` | ❌ Wave 0 |
| D-10 (carried defect) | `loopPhase()` continues (does not reset to 0) across a pause -> resume ticker stop/start cycle | widget (extends existing suite) | `flutter test test/scenes/scene_renderer_test.dart -N "resume"` | ❌ Wave 0 (new test case in existing file) |

### Sampling Rate
- **Per task commit:** the single most relevant `flutter test <file> -N "<case>"` quick command above.
- **Per wave merge:** `flutter test`
- **Phase gate:** Full suite green before `/gsd-verify-work`, plus the human-verify checkpoints noted in Open Questions (chime sound quality, blurred-sheet smoothness, media-volume vs. ringer-silent behavior).

### Wave 0 Gaps
- [ ] `test/screens/running_screen_test.dart` — new file; needs a test harness analogous to `test/screens/setup_screen_test.dart`'s `_harness`/`_pumpPastTransition` helpers (note: this suite will ALSO need a fake `ChimePlayer` injected into `RunningScreen`, since the real `audioplayers` plugin cannot run under `flutter_test` — see Common Pitfalls §5)
- [ ] `test/audio/chime_synth_test.dart` — new file; pure-Dart unit tests asserting the synthesized WAV byte buffer is well-formed (correct RIFF header fields, non-empty PCM payload, no platform dependency needed)
- [ ] Extend `test/scenes/scene_renderer_test.dart` with a pause -> resume -> pause loop-phase-continuity assertion (D-10)
- [ ] Framework install: none — `flutter_test` already present; no new test framework needed

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V2 Authentication | No | Single-device, no accounts (per REQUIREMENTS.md Out of Scope) |
| V3 Session Management | No | No sessions/backend |
| V4 Access Control | No | No multi-user access boundaries |
| V5 Input Validation | Yes | Extend `SetupPreferences`'s existing validate-on-every-read pattern to the new `soundOn` bool (a tampered/wrong-typed stored value must fall back to the D-04 default, exactly like `durationMin`/`theme` already do — T-02-02 precedent) |
| V6 Cryptography | No | No secrets/crypto in this phase |

### Known Threat Patterns for this stack

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Tampered/corrupted `shared_preferences` value for the new `soundOn` key (rooted device edit, or a future app version storing a different type under the same key) | Tampering | Same defense already established for `durationMin`/`theme` in `SetupPreferences.load()`: wrap the read in try/catch, fall back to the D-04 default (`true`) on any type mismatch or missing value — do not trust the stored value's type or presence |
| Child accidentally discovering the long-press gesture through repeated random touching | Tampering (of intended UX boundary, not a data-security threat) | D-08's fully-silent/invisible hold (no build-up affordance) is itself the mitigation — already locked, no additional control needed |

## Sources

### Primary (HIGH confidence)
- Direct codebase reads this session: `lib/screens/running_screen.dart`, `lib/scenes/scene_renderer.dart`, `lib/timer/timer_controller.dart`, `lib/timer/timer_lifecycle_binder.dart`, `lib/settings/setup_preferences.dart`, `lib/theme/app_tokens.dart`, `lib/main.dart`, `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/AndroidManifest.xml`, `design/README.md` §§G-H, "Interactions & Behavior", "Design Tokens" — all VERIFIED by direct file read, not inference.

### Secondary (MEDIUM confidence — CITED)
- Context7 `/bluefireteam/audioplayers` — `BytesSource`/`AudioContextAndroid`/`respectSilence` behavior
- Context7 `/ryanheise/just_audio` — `StreamAudioSource` (`@experimental`) API shape
- Context7 `/alnitak/flutter_soloud` — waveform-generation example structure, native-engine framing
- `api.flutter.dev` (via WebFetch) — `LongPressGestureRecognizer.duration` parameter, `showModalBottomSheet` full parameter list and dismiss mechanism
- `pub.dev` API/pages (via WebFetch) — version, publish date, likes, downloads for `audioplayers`, `flutter_soloud`, `just_audio`
- WebSearch cross-checked (2+ independent queries) — Android ringer-silent-mode vs. `STREAM_MUSIC` behavior; `BackdropFilter`+bottom-sheet blur pattern and known jank/flicker issues (flutter/flutter GitHub issues #78356, #160963, #162006)

### Tertiary (LOW confidence)
- Single-source WebSearch result (Medium article on raw-PCM-to-WAV conversion in Flutter) — used only to corroborate the general `BytesSource`-with-hand-built-WAV-header pattern, not as the sole basis for any locked recommendation.

## Metadata

**Confidence breakdown:**
- Standard stack (audio package choice): MEDIUM — package identity is training/WebSearch-derived (`[ASSUMED]` per provenance rule) though registry metadata (version, publisher, popularity) was independently verified via `pub.dev` this session.
- Architecture (gesture/sheet/animation patterns): HIGH — SDK APIs confirmed via Context7/official docs, cross-checked with WebFetch of the actual API reference pages.
- Pitfalls: HIGH for D-10 (directly reproduced from codebase read + prior documented defect) and the silent-mode nuance (cross-checked 2+ sources); MEDIUM for the `BackdropFilter` blur caveat (based on documented but possibly version-specific Flutter engine issues).

**Research date:** 2026-07-08
**Valid until:** 30 days (stable Flutter SDK APIs + established packages; re-verify `audioplayers` version if planning is delayed significantly, as it ships frequent patch releases)
