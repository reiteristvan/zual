---
quick_id: 260819-dsg
description: Rewrite README.md to describe the real Zual app and refresh the stale scaffold-era sections of .claude/CLAUDE.md plus their .planning/codebase/ source files
date: 2026-08-19
mode: quick
---

# Quick Task 260819-dsg: Refresh README.md and CLAUDE.md to match the v1.0 codebase

## Problem

Two docs still describe the pre-Zual Flutter scaffold, not the shipped v1.0 app:

1. **`README.md`** — verbatim `flutter create` output ("A new Flutter project.", links to
   the Flutter codelab). Says nothing about what Zual is, how to run it, or how it is
   structured.

2. **`.claude/CLAUDE.md`** — the `stack`, `conventions`, and `architecture` sections were
   generated on 2026-07-06 against the Hello World scaffold. They are now actively wrong:
   - Names `MyHomePage` as the main screen (does not exist).
   - "No state management library (GetX, Riverpod, Provider) currently used" — the app
     uses `provider` + `ChangeNotifier`.
   - "All widgets are `StatelessWidget` — no local state" — false.
   - "All code in single file" listed as an anti-pattern to fix — already fixed;
     `lib/` has 29 files across `audio/ scenes/ screens/ settings/ theme/ timer/ widgets/`.
   - "Hardcoded Theme" anti-pattern — already fixed by `lib/theme/app_tokens.dart`.
   - Key Dependencies omits `provider`, `wakelock_plus`, `shared_preferences`,
     `audioplayers`, `flutter_launcher_icons`; lists transitive test packages instead.
   - "Web (primary target)" — v1 is Android-only per PROJECT.md constraints.

   Those three sections are GSD-generated blocks (`<!-- GSD:stack-start source:codebase/STACK.md -->`
   etc.). Editing CLAUDE.md alone would be reverted on the next regeneration, so their
   source files must be updated too.

## Scope

**In scope**
- `README.md` — full rewrite.
- `.planning/codebase/STACK.md`, `ARCHITECTURE.md`, `CONVENTIONS.md` — rewrite to match
  the real codebase (these are the `source:` files for CLAUDE.md's stale blocks).
- `.claude/CLAUDE.md` — regenerate the `stack`, `conventions`, `architecture` block bodies
  from those sources, preserving every `<!-- GSD:*-start/end -->` marker exactly.

**Out of scope** (flag, do not change)
- `.planning/codebase/STRUCTURE.md`, `TESTING.md`, `CONCERNS.md`, `INTEGRATIONS.md` — also
  dated 2026-07-06 and stale, but they do not feed CLAUDE.md; refreshing them is a
  separate `/gsd-map-codebase` run.
- The `project`, `skills`, `workflow`, `profile` blocks in CLAUDE.md — already accurate.
- Any `lib/` or `test/` source change. Documentation only.

## Ground truth (verified against the repo, 2026-08-19)

| Fact | Source |
|---|---|
| 29 Dart files, 3,874 LOC in `lib/` | `find lib -name '*.dart' \| xargs wc -l` |
| 25 test files, 2,846 LOC, ~129 `test`/`testWidgets` calls | `find test`, `grep -c` |
| Runtime deps: `provider ^6.1.5+1`, `wakelock_plus ^1.6.1`, `shared_preferences ^2.5.5`, `audioplayers ^6.8.1`, `cupertino_icons ^1.0.8` | `pubspec.yaml` |
| Dev deps: `flutter_test`, `flutter_lints ^6.0.0`, `flutter_launcher_icons ^0.14.4` | `pubspec.yaml` |
| Bundled fonts: Baloo 2 Bold; Quicksand 400/500/600/700 | `pubspec.yaml` |
| `applicationId = "com.ireiter.zual"`, version `1.0.0+1` | `android/app/build.gradle.kts`, `pubspec.yaml` |
| State: `TimerController extends ChangeNotifier`, provided via `ChangeNotifierProvider.value` in `MyApp` | `lib/main.dart`, `lib/timer/timer_controller.dart` |
| Phases: `enum TimerPhase { setup, running, paused, done }` | `lib/timer/timer_phase.dart` |
| Scenes: `enum SceneTheme { disc, sunrise, walk, car }`, dispatched by `sceneFor()` | `lib/scenes/scene_theme.dart`, `scene_registry.dart` |
| Progress is wall-clock derived with a monotonic high-water mark | `lib/timer/timer_controller.dart` |
| Plugin isolation: `ScreenWake`/`WakelockScreenWake`, `ChimePlayer`/`AudioplayersChimePlayer`/`NoopChimePlayer` | `lib/timer/`, `lib/audio/` |
| Chime is synthesized WAV bytes in pure Dart, no audio asset | `lib/audio/chime_synth.dart` |
| Scenes are `CustomPainter`s driven by `SceneRenderer`/`SceneRendererState` (per-scene `Ticker`) | `lib/scenes/scene_renderer.dart` |
| Design tokens centralized in `abstract class AppTokens` | `lib/theme/app_tokens.dart` |
| Store icon + feature graphic rendered headlessly from real painters | `test/tool/` |
| `key.properties` / `upload-keystore.jks` are gitignored | `.gitignore:65,66,129,130` |
| Privacy policy page | `docs/index.html` |
| No LICENSE file present | `ls LICENSE*` |
| `lib/screens/placeholder_running_screen.dart` is unreferenced dead code | `grep -rn PlaceholderRunningScreen lib test` |

## Tasks

### Task 1 — Rewrite `README.md`

**Files:** `README.md`

**Action:** Replace the scaffold text with a real project README covering: what Zual is and
its core value; the four scenes; a screenshot row from `screenshots/`; requirements and
run/test/build commands (including the release-signing prerequisite that `android/key.properties`
and `android/upload-keystore.jks` are gitignored and must be supplied locally); a repo layout
table; a short "how it works" section (wall-clock timer, painter-per-scene, plugin-isolation
interfaces, generated store assets); pointers to `design/README.md`, `.planning/`, and
`docs/index.html`; and a licensing note stating no LICENSE file is present.

**Verify:** Every command, path, dependency, and version named in the README resolves in
the repo. Screenshot filenames match `screenshots/`.

**Done:** `README.md` contains no `flutter create` boilerplate and no claim contradicted by
the ground-truth table above.

### Task 2 — Rewrite the three `.planning/codebase/` source docs

**Files:** `.planning/codebase/STACK.md`, `.planning/codebase/ARCHITECTURE.md`,
`.planning/codebase/CONVENTIONS.md`

**Action:**
- `STACK.md` — real dependency list (direct deps, not transitive test packages), Android-only
  v1 platform posture, bundled font/asset config, signing config, `flutter_launcher_icons`.
- `ARCHITECTURE.md` — replace the `MyApp → MyHomePage` diagram with the actual layering
  (composition root → screens → scene renderers/painters → timer core → platform adapters);
  document the `ChangeNotifier` + `provider` state model, the `TimerPhase` machine, the
  `SceneRenderer` contract, the plugin-isolation interface pattern, and lifecycle
  reconciliation via `TimerLifecycleBinder`. Replace the three obsolete "Anti-Patterns"
  (single file / no state management / hardcoded theme — all resolved) with the real
  standing issues from PROJECT.md's tech-debt note plus the dead `PlaceholderRunningScreen`.
- `CONVENTIONS.md` — describe conventions actually observed in `lib/`: relative imports
  within `lib/` (not `package:`), heavy `///` dartdoc citing decision/threat IDs, `abstract
  class AppTokens` as the token namespace, tests mirroring `lib/` structure, injected clocks
  and interfaces for testability.

Bump each file's `**Analysis Date:**` / footer to 2026-08-19.

**Verify:** No occurrence of `MyHomePage` remains in any of the three files; each states
`provider` + `ChangeNotifier` as the state model.

**Done:** All three describe the v1.0 codebase.

### Task 3 — Regenerate the stale CLAUDE.md blocks

**Files:** `.claude/CLAUDE.md`

**Action:** Replace the body of the `stack`, `conventions`, and `architecture` blocks with
content derived from the Task 2 rewrites, keeping the surrounding
`<!-- GSD:<name>-start source:... -->` / `<!-- GSD:<name>-end -->` markers byte-identical and
leaving the `project`, `skills`, `workflow`, and `profile` blocks untouched.

**Verify:** `grep -c 'GSD:' .claude/CLAUDE.md` still returns 14 (7 start + 7 end markers);
`grep -n 'MyHomePage\|MyApp\|deep purple' .claude/CLAUDE.md` returns only accurate `MyApp`
references (it is the real root widget class name).

**Done:** CLAUDE.md's technical sections match the codebase.

### Task 4 — Sanity-check the docs against a clean analyze

**Files:** none

**Action:** Run `flutter analyze` and `flutter test` to confirm the documented commands work
and the documented test count is accurate. Correct the README/docs if the numbers differ.

**Verify:** Both commands run; README's stated test count matches actual output.

**Done:** Documented commands verified against real output.

## Must-haves

**Truths**
- `README.md` describes Zual, not a Flutter scaffold.
- CLAUDE.md's stack/conventions/architecture sections agree with `lib/`, `pubspec.yaml`,
  and `android/app/build.gradle.kts`.
- CLAUDE.md's GSD block markers are preserved so the next regeneration is a no-op, not a
  revert.
- No source file under `lib/` or `test/` is modified.

**Artifacts**
- `README.md`
- `.planning/codebase/STACK.md`, `ARCHITECTURE.md`, `CONVENTIONS.md`
- `.claude/CLAUDE.md`
