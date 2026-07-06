# Pitfalls Research

**Domain:** Flutter kids' countdown-timer app — long-running full-screen `CustomPainter` animation, continuous audio-free-until-completion, Play Store (Android, Families-adjacent audience)
**Researched:** 2026-07-06
**Confidence:** MEDIUM (Flutter framework mechanics verified against official docs via Context7; Play Store policy and package-ecosystem claims are WebSearch-sourced — treat as directionally correct, re-verify exact policy wording in Play Console before submission)

## Critical Pitfalls

### Pitfall 1: Driving the countdown off `AnimationController.duration` instead of wall-clock time

**What goes wrong:**
Building the countdown as a single `AnimationController(duration: totalMinutes)` that runs continuously produces a timer that silently loses accuracy over long durations (up to 120 min here), and makes pause/resume awkward — `controller.stop()` mid-flight doesn't cleanly account for "time already spent," and `Ticker` timing has drift under system load (GC pauses, thermal throttling, low-end device scheduling jitter).

**Why it happens:**
`AnimationController` is the obvious first tool reached for in Flutter for "progress 0→1 over a duration," and it works fine for short (sub-minute) transitions. Nobody thinks about drift until they test a real multi-minute run against a wall clock.

**How to avoid:**
Match the design's own architecture note (`design/README.md`): record `startTs` (wall-clock) and `totalMs` on Start; derive `progress = clamp((now - startTs - pausedTotal) / totalMs, 0, 1)` from `DateTime.now()` on every tick, driven by a lightweight `Ticker`/periodic callback (e.g. every 16–33ms) rather than trusting an `AnimationController`'s internal duration bookkeeping for the full countdown. Use `AnimationController`s only for the *short, local* looping decorations (bob, spin, twinkle, breathe — all sub-second/few-second loops per the design tokens), never for the multi-minute master countdown.

**Warning signs:**
A 1-minute test run measured against a stopwatch drifts by more than ~1 frame; pause→resume produces a visible jump in the visualized progress; resuming after backgrounding the app snaps to the wrong position.

**Phase to address:**
Timer/state-machine foundation phase (before any scene is built) — this is the core engine all four themes and the parent-controls pause/resume depend on.

---

### Pitfall 2: No `AppLifecycleState` handling — timer desyncs from wall clock on background/foreground

**What goes wrong:**
If the app is backgrounded (parent switches apps, phone locks, an incoming call interrupts) and the countdown state isn't explicitly reconciled against real elapsed time on resume, the child sees the visual "jump" — either frozen at the pre-background position (feels broken) or snapping ahead unexpectedly on resume (breaks the "smooth countdown" illusion that is the entire point of the app).

**Why it happens:**
Flutter continues to run the widget tree while backgrounded unless the OS suspends it, so animations *appear* to keep working in dev testing (foreground-only manual testing), but real Android devices throttle or pause rendering/timers while backgrounded, and elapsed real time still passes regardless of whether frames were drawn.

**How to avoid:**
Mix the running-screen's state with `WidgetsBindingObserver`, register in `initState()` via `WidgetsBinding.instance.addObserver(this)`, unregister in `dispose()`. In `didChangeAppLifecycleState`, on `paused`/`hidden`/`inactive` note the wall-clock instant; on `resumed`, recompute `progress` fresh from `startTs`/`pausedTotal`/`now` (per Pitfall 1's model) rather than resuming a paused animation from where it "left off" internally. Since Flutter 3.13, `AppLifecycleState` has a `hidden` value between `inactive` and `paused` — any switch statement over this enum must handle it explicitly or it will fail to compile exhaustively on SDK upgrade.

**Warning signs:**
Countdown looks correct when tested by pressing pause/play in the emulator, but drifts or jumps when tested by pressing the physical Home button and returning after a real delay.

**Phase to address:**
Timer/state-machine foundation phase, verified again in the Parent Controls phase (pause/resume UI sits on top of this same mechanism).

---

### Pitfall 3: Building animated scenes with deep widget trees (`Transform`/`Opacity`/`AnimatedContainer` per element) instead of `CustomPainter`

**What goes wrong:**
The four running scenes (Shrinking Disc, Night→Sunrise with ~28 stars, Walking Home, Car on Road) each have many simultaneously-animating primitives. Building each star/cloud/wheel as a separate widget wrapped in `Transform`/`AnimatedBuilder` creates a wide, frequently-rebuilding widget tree. On a low-end Android tablet (a realistic device for a young child's household), this produces visible jank — dropped frames, stutter in the "smooth shrinking disc" that is the app's entire value proposition.

**Why it happens:**
Widget-based animation is the path of least resistance in Flutter tutorials; `CustomPainter` has a steeper learning curve and the project's own scaffold (per `CONCERNS.md`) currently has zero animation or painting infrastructure, so there's a real risk of defaulting to whatever is fastest to prototype.

**How to avoid:**
Use `CustomPainter` for every scene's visual body (disc, sky+stars+sun+moon, path+character, road+car+wheels) with a single `AnimationController`-or-Ticker-driven `progress` value passed into `paint()`; implement `shouldRepaint` to compare only the fields that matter (usually just `progress`, `paused`) so the framework can skip redundant paints. Wrap only the parts of the screen that *don't* need to repaint every frame (e.g. a static background layer, if one exists) in `RepaintBoundary` — but note each `RepaintBoundary` costs an extra compositor layer/canvas, so don't scatter them everywhere; for a full-bleed continuously-repainting scene the "boundary" pattern buys little.

**Warning signs:**
Enable DevTools' "Highlight repaints" overlay — if large swaths of the screen (or unrelated widgets like the parent-controls trigger area) flash on every animation tick, the tree is repainting more than necessary. Frame times consistently above 16.6ms (60fps budget) in DevTools' Performance view during a running scene.

**Phase to address:**
Each running-scene implementation phase (Shrinking Disc first as the reference implementation, since it's simplest and is the "hero" scene per the design doc) — establish the `CustomPainter` + single-progress-input pattern once, then reuse for the other three scenes.

---

### Pitfall 4: Undisposed `AnimationController`s, `Ticker`s, and forgotten `WakelockPlus.disable()` calls leaking battery drain

**What goes wrong:**
Any `AnimationController` or repeating `Ticker` not disposed when its owning widget leaves the tree keeps ticking indefinitely — draining battery and CPU even after the child has navigated back to Setup or closed the running screen. Similarly, calling `WakelockPlus.enable()` on timer start but missing the corresponding `disable()` on every exit path (natural completion, "End timer," app backgrounded then killed) leaves the screen forced on indefinitely, which is a severe and easily-missed battery bug for an app whose core feature is running unattended for up to 2 hours.

**Why it happens:**
Multiple exit paths exist for the running screen (natural completion → done state, parent "End timer," parent long-press → dismiss, OS-level app kill) and it's easy to wire disposal into only the "happy path" (natural `dispose()`), missing edge cases like abrupt navigation or process death.

**How to avoid:**
Centralize wakelock and controller lifecycle in one place tied to the running-phase's `State.dispose()` (which Flutter guarantees runs on any widget removal), not to specific button handlers. Treat `WakelockPlus.enable()`/`disable()` as strictly paired with "entering/leaving the running phase," never "app-wide." Add a debug assertion or test that fails if wakelock is left enabled after leaving the running screen.

**Warning signs:**
Device stays at full brightness / screen-on indefinitely after backing out of the app; DevTools memory profiler shows `Ticker`/`AnimationController` instances accumulating across repeated Setup→Running→Setup cycles (a leak, not garbage collected).

**Phase to address:**
Timer/state-machine foundation phase for controller disposal discipline; wakelock specifically wherever the running-phase enter/exit is implemented (likely the same phase as Pitfall 1/2).

---

### Pitfall 5: Testing looping/"infinite" animations with `tester.pumpAndSettle()`

**What goes wrong:**
The design specifies several genuinely infinite looping animations — `bob` (0.62s ease-in-out infinite), `spin` (0.7s linear infinite), `twinkle` (3s ease-in-out infinite), `breathe` (2.8s ease-in-out infinite). Widget/golden tests that call `tester.pumpAndSettle()` on a screen containing any of these will hang or time out, because `pumpAndSettle` waits for animations to stop scheduling frames — which an infinite loop never does.

**Why it happens:**
`pumpAndSettle()` is the default reflex for "wait until the UI is done animating" in most Flutter test tutorials, and works fine for finite transitions; it's a common trap the first time a codebase introduces a genuinely infinite/looping animation.

**How to avoid:**
For any screen with looping decorations, use `tester.pump(fixedDuration)` (pumping specific durations) instead of `pumpAndSettle()`, and capture golden images at deliberately chosen `progress` checkpoints (0%, 25%, 50%, 100%) rather than "settled" states.

**Warning signs:**
CI test runs for running-scene widget tests hang or fail with a `pumpAndSettle timed out` exception the moment any scene test is added.

**Phase to address:**
Testing/verification work within each running-scene phase, and explicitly whenever a test-generation pass (`gsd-add-tests`) is run against these scenes.

---

### Pitfall 6: Golden tests that flake across machines/CI because of platform-dependent rendering

**What goes wrong:**
Golden (screenshot) tests are the only practical way to verify `CustomPainter` output pixel-for-pixel, but rendered images differ subtly across operating systems (font hinting, anti-aliasing, and — increasingly — whether Impeller or Skia is the active rendering backend) and even across Flutter engine versions. A goldens suite generated on a developer's Windows machine will likely fail on a Linux CI runner (or vice versa) for reasons unrelated to any real visual regression.

**Why it happens:**
Golden test tooling doesn't warn about this by default; the failure only surfaces once CI is wired up, often well after the tests were written and "passing" locally.

**How to avoid:**
Pin golden test generation and verification to a single environment (typically the CI Linux runner, generating goldens via `flutter test --update-goldens` inside that same CI image/container) rather than trusting locally-generated goldens. Alternatively use a tolerance-based comparison package (e.g. `alchemist`) instead of Flutter's strict pixel-diff `matchesGoldenFile`, if cross-platform contributor golden generation is required.

**Warning signs:**
Goldens pass locally but fail in CI (or vice versa) with diffs concentrated in anti-aliased edges/gradients rather than obvious layout breaks.

**Phase to address:**
Whenever CI/testing infrastructure is set up (likely early, and revisited when `gsd-add-tests` runs against each scene phase).

---

### Pitfall 7: Misdeclaring — or under-declaring — the Play Store "target audience" for a mixed parent/child app

**What goes wrong:**
Zual is *operated* by a parent (Setup screen, parent controls) but *watched* by a young child (Running screen) with zero interactivity for the child. Google Play's Families Policy triggers a specific, stricter bundle of requirements (COPPA/GDPR-K compliance, no device/advertising identifiers for child users, restricted ad/analytics SDKs, additional content-rating and "Kids tab" eligibility review) the moment "children" is selected as part of the target audience in Play Console's "Target audience and content" section — even if the app has no ads and no network calls. Declaring the wrong audience (e.g. omitting children when the primary viewer is a child, or over-declaring in a way that invites "Teacher Approved"/Kids-tab review the app isn't ready for) can cause store rejection or a policy strike after publication.

**Why it happens:**
The distinction between "an app children use" and "an app whose target audience is children" is genuinely subtle in Play Console's own UI, and teams building children's apps for the first time often don't discover the Families Policy implications until a store listing is rejected.

**How to avoid:**
Since Zual has no ads, no accounts, no network, and no persistent identifiers (per `PROJECT.md`'s explicit "Out of Scope"), it is already in a strong position for Families Policy compliance — but this should be a deliberate, explicit decision recorded when filling out the Play Console content-rating (IARC) questionnaire and target-audience declaration, not an afterthought at submission time. Confirm during store-readiness work whether to declare "Children" as (one of) the target audiences, and if so, avoid adding any future analytics/crash-reporting SDK that isn't Families-Policy-compliant (no persistent device identifiers for child users).

**Warning signs:**
Store listing submission rejected or flagged for review with Families Policy violations; realizing post-launch that an added SDK (crash reporting, analytics) transmits an advertising ID.

**Phase to address:**
Play Store publish-readiness phase (final phase) — but the "no network, no accounts, no ads" constraint should be protected throughout implementation so this phase is a formality, not a redesign.

---

## Technical Debt Patterns

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|-----------------|-----------------|
| Driving progress with `Timer.periodic` + `setState()` instead of a dedicated `Ticker`/`AnimationController` architecture | Fastest to prototype a single scene | Harder to retrofit pause/resume + lifecycle handling later; tends to rebuild the whole widget tree every tick instead of just repainting a `CustomPainter` | Acceptable only for a disposable spike to validate one visual, never for the shipped scene implementation |
| Tracking `paused` as a plain boolean without `pausedTotal`/`pauseStart` timestamps | Simple to reason about in isolation | Breaks the moment pause/resume needs to compose with backgrounding (Pitfall 1/2) — the two features silently conflict if built independently | Never — build the full `totalMs`/`startTs`/`pausedTotal` model from the start, per the design's own state model |
| Deferring golden/CustomPainter tests until "the scene looks right" | Faster initial visual iteration | Visual regressions on later refactors (e.g. adjusting color-zone thresholds) go undetected without a pixel baseline | Acceptable to defer golden-test *authoring* until the visual is stable, but do not skip it entirely before phase completion |
| Using `audioplayers`' `PlayerMode.lowLatency` for the completion chime | Marginally lower playback latency | Known bug: combined with `ReleaseMode.stop` on Android, the sound plays only once (edge case only matters if this chime were ever triggered repeatedly, which per design it isn't) | Acceptable given single-shot playback per timer cycle, but verify replay-ability if "Keep watching" / multiple cycles per session are exercised in testing |

## Integration Gotchas

| Integration | Common Mistake | Correct Approach |
|-------------|-----------------|-------------------|
| `wakelock_plus` | Enabling app-wide at startup and never disabling, or enabling/disabling from multiple uncoordinated call sites | Enable only on entering the running phase, disable in that phase's `dispose()` (guaranteed to run on any exit path) — treat as tightly scoped to running-phase lifetime |
| Audio package (`audioplayers`/`just_audio`) | Reaching for `PlayerMode.lowLatency` reflexively "for performance" without checking it disables seek/duration/replay support | For a single non-looping two-tone chime, default playback mode is sufficient; only consider low-latency mode if profiling shows an audible delay, and test replay behavior with the exact `ReleaseMode` used |
| Google Play Console — Target audience & content rating | Filling out the IARC content-rating questionnaire generically without considering that "target audience includes children" changes technical requirements (not just content labels) | Treat the audience declaration as an architectural decision made early (it constrains "no ads/analytics with persistent identifiers"), not a form filled out at the last minute during submission |

## Performance Traps

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|-----------------|
| Rebuilding the entire widget subtree every animation tick instead of repainting a `CustomPainter` | Frame times >16.6ms in DevTools during running scenes; visible stutter especially on the Sunrise scene (28 stars + sun + moon + gradient, all progress-driven) | Single `CustomPainter` per scene, `progress` as its only meaningful repaint-triggering input, `shouldRepaint` comparing just that value | Becomes visible almost immediately on a mid/low-end Android tablet; may look fine on a dev's high-end phone |
| Recreating `Paint`/`Shader`/`Gradient` objects inside `paint()` on every frame instead of caching them | Gradual frame-time creep over a long-running (up to 120 min) session; increased GC pauses | Cache `Paint`/gradient/shader objects as fields, only reconstruct when the *values* that affect them (e.g. color-zone thresholds) actually change | Most visible in the two full-screen gradient scenes (Sunrise sky, and disc color-zone lerp) run continuously over a long duration |
| Overusing `RepaintBoundary` around many small elements in a scene that's mostly full-bleed and continuously repainting anyway | Increased memory (each boundary allocates its own compositor layer) without a matching frame-time improvement | Reserve `RepaintBoundary` for genuinely static regions that coexist with animated ones (e.g. a fixed doneable static UI outside the scene, not the scene's own primitives) | Noticeable on memory-constrained/low-end devices once several boundaries are added without measured benefit |
| First-run "shader compilation jank" on complex custom-painted scenes | A visible stutter the *first* time a given draw call (gradient, blur, path) is executed on-device, then smooth afterward | Keep painter draw operations simple/consistent across scenes where possible (fewer distinct shader variants); test cold-start of each scene, not just warm re-runs during dev | Most likely to show up on the very first frame of each of the four scenes on a real (non-emulator) low/mid-end Android device |

## Security Mistakes

| Mistake | Risk | Prevention |
|---------|------|------------|
| Adding an analytics/crash-reporting SDK later without checking Families Policy compatibility | Store rejection or policy strike if the SDK transmits advertising ID/device identifiers for an app whose audience includes children | Treat "no network, no persistent identifiers" as an architectural constraint (already true for v1 per `PROJECT.md`), and audit any future dependency addition against Play's Families-Policy SDK requirements before adding it |
| Shipping with the placeholder Android `applicationId` (`com.example.zual`) or debug-key release signing (both flagged in `CONCERNS.md`) | Cannot submit to Play Store at all; if accidentally shipped, ID collisions with other `com.example.*` apps on a device | Change `applicationId` to a real reverse-domain identifier and configure a production keystore/signing config before the first release build — treat as a hard gate in the publish-readiness phase, not a "nice to have" |

## UX Pitfalls

| Pitfall | User Impact | Better Approach |
|---------|-------------|-------------------|
| Any incidental tappable/gesture-reactive element appearing on the running screen | Breaks the deliberate "nothing tappable by the child" design intent — a curious child's normal tap could accidentally trigger something (e.g. a `GestureDetector` added for the long-press-to-parent-controls feature that also fires on short taps) | Ensure the long-press detector distinguishes short taps (no-op) from the ≈850ms hold (opens parent sheet); verify with a widget test that a quick tap produces zero visible effect |
| Countdown that doesn't actually reflect real elapsed time after backgrounding (Pitfall 2) | Undermines the core value proposition — "look at the screen and know how much longer," if the visual is wrong relative to real time, the whole app fails its purpose | Wall-clock-based progress calculation reconciled on every lifecycle resume, not internal animation-frame counting |
| A chime that sounds abrupt/harsh due to default player behavior rather than the specified soft envelope (ramp to ~0.16 gain over 60ms, exponential decay over ~1.1s) | Breaks the "calm, not alarm" design intent explicitly called out in the design doc | Implement the chime with an actual amplitude envelope (either a bundled WAV authored with that envelope, or programmatic tone generation with gain shaping), not a default "beep" asset or unshaped sine playback |

## "Looks Done But Isn't" Checklist

- [ ] **Pause/Resume:** Looks correct when tested by tapping pause/resume buttons in quick succession on an emulator — verify it also stays correct after genuinely backgrounding the app (Home button, real delay, return) and after an OS-level low-memory app restart.
- [ ] **Running scenes at 60fps:** Looks smooth on a dev's high-end phone/emulator — verify with DevTools' Performance view and, ideally, a real low/mid-end Android device or throttled profile, not just a fast desktop-class emulator.
- [ ] **Battery/wakelock discipline:** App appears to work fine in a 5-minute demo — verify wakelock is actually released after every exit path (natural completion, "End timer," navigating away, backgrounding) not just the happy path, and that a full 120-minute run doesn't leave the screen locked on afterward.
- [ ] **Audio playback:** Chime "works" the first time it's manually tested — verify cold-start playback latency/reliability (first play after app launch, not just repeated plays during a dev session) and confirm the envelope/tone actually matches spec, not a default click/beep.
- [ ] **Play Store submission readiness:** App builds and installs locally — verify `applicationId` is a real reverse-domain string (not `com.example.zual`), release signing uses a real keystore (not debug keys), app icon/adaptive icon/feature graphic/screenshots are supplied, target audience & content rating questionnaire is completed deliberately (not left at defaults), and `targetSdkVersion` meets Play's current minimum API level requirement (Play enforces an annually-updated minimum targetSdkVersion — check the current requirement at submission time, not against what the scaffold's pre-release Flutter version defaults to).
- [ ] **Golden/animation tests:** Test suite "passes" locally — verify it doesn't rely on `pumpAndSettle()` against the looping (bob/spin/twinkle/breathe) animations, and that goldens are generated/verified in the same environment used by CI.

## Recovery Strategies

| Pitfall | Recovery Cost | Recovery Steps |
|---------|----------------|------------------|
| Countdown built on `AnimationController.duration` instead of wall-clock elapsed time | MEDIUM | Refactor the progress-calculation to a wall-clock model (`startTs`/`pausedTotal`/`now`) feeding a `Ticker`; the four scenes only consume a `progress` double so their painters shouldn't need to change, only the source of that value |
| Deep-widget-tree scene implementation causing jank discovered late | HIGH | Rewriting a scene as a `CustomPainter` after the fact touches most of that scene's code, but is isolated per-scene (doesn't cascade to the other three themes or the state machine) — budget it as a near-full redo of one scene, not the whole app |
| Wakelock/controller leaks discovered via battery complaints post-launch | LOW–MEDIUM | Centralize enable/disable calls into the running-phase's lifecycle methods (`initState`/`dispose`) if scattered; usually a contained, well-understood fix once located via DevTools memory profiling |
| Play Store rejection for Families Policy / target-audience misdeclaration | LOW–MEDIUM | Correcting the Play Console declaration and resubmitting is usually fast if the app itself has no ads/identifiers to actually remove (Zual's v1 scope already avoids the hard cases) |

## Pitfall-to-Phase Mapping

| Pitfall | Prevention Phase | Verification |
|---------|-------------------|----------------|
| Wall-clock vs. `AnimationController.duration` drift | Timer/state-machine foundation phase | Manual multi-minute run against a stopwatch; unit test asserting `progress` matches expected value at known elapsed times including a simulated pause |
| Missing `AppLifecycleState` handling | Timer/state-machine foundation phase | Manual test: background the app mid-countdown, wait, resume, confirm progress reflects real elapsed time |
| Deep widget trees instead of `CustomPainter` | Each running-scene phase (Shrinking Disc first) | DevTools "Highlight repaints" + Performance view frame-time check per scene |
| Undisposed controllers / wakelock leaks | Timer/state-machine foundation phase; re-checked in Parent Controls phase | DevTools memory profiler across repeated Setup→Running→Setup cycles; manual check that screen unlocks after exiting running phase |
| `pumpAndSettle()` hangs on infinite animations | Testing pass within each running-scene phase | CI test run must complete without timeout; use `tester.pump(duration)` explicitly in test code review |
| Golden test platform flakiness | CI/testing setup (early), revisited whenever `gsd-add-tests` runs | CI green on the pinned environment; no discrepancy between CI-generated and locally-generated goldens |
| Play Store target-audience/Families Policy misdeclaration | Play Store publish-readiness phase | Play Console submission accepted without Families Policy rejection; explicit written decision on target-audience declaration recorded before submission |
| Placeholder `applicationId` / debug signing | Play Store publish-readiness phase | Release build produced with real `applicationId` and production keystore, verified via `flutter build appbundle --release` succeeding with the correct signing config |

## Sources

- [Performance best practices — docs.flutter.dev](https://docs.flutter.dev/perf/best-practices)
- [Why Flutter animations need a vsync/TickerProvider](https://dash-overflow.net/articles/why_vsync/)
- [Handling Animation Controller Leaks in Flutter](https://www.oneclickitsolution.com/centerofexcellence/flutter/handling-animation-controller-leaks-in-flutter)
- [wakelock_plus | Flutter package](https://pub.dev/packages/wakelock_plus)
- [Testing CustomPaint Widgets in Flutter using Golden Image Files](https://medium.com/flutter-community/testing-custompaint-widgets-in-flutter-using-golden-image-files-889fe3bdf9ca)
- [How to use Alchemist for Flutter golden tests](https://verygood.ventures/blog/alchemist-golden-tests-tutorial/)
- [Google Play Families Policies — Play Console Help](https://support.google.com/googleplay/android-developer/answer/9893335?hl=en)
- [Google Play streamlines policies around kids' apps as regulations tighten — TechCrunch](https://techcrunch.com/2022/11/16/google-play-streamlines-policies-around-kids-apps-as-regulations-tighten/)
- [Android Developers Blog: Helping Families Find High-Quality Apps for Kids](https://android-developers.googleblog.com/2022/11/helping-kids-and-families-find-high-quality-apps-for-kids.html)
- [Comply with Google Play's Families Policy using AdMob](https://support.google.com/admob/answer/6223431?hl=en)
- [Children's Online Privacy Protection Act (COPPA) — Publisher Policies Help](https://support.google.com/publisherpolicies/answer/10436800?hl=en)
- [Flutter. Stop using Audioplayers. Use this instead](https://medium.com/easy-flutter/flutter-stop-using-audioplayers-use-this-instead-4030800a4107)
- [audioplayers issue #1489 — PlayerMode.lowLatency + setReleaseMode bug](https://github.com/bluefireteam/audioplayers/issues/1489)
- Flutter official docs (Context7 `/flutter/website`): `AppLifecycleState`/`WidgetsBindingObserver` patterns, `AppLifecycleState.hidden` breaking-change migration, `CustomPainter`/`shouldRepaint`/`RepaintBoundary` examples
- Project-internal: `.planning/PROJECT.md`, `.planning/codebase/CONCERNS.md`, `design/README.md` (existing known concerns and design's own architecture notes)

---
*Pitfalls research for: Flutter kids' countdown-timer app (Zual)*
*Researched: 2026-07-06*
