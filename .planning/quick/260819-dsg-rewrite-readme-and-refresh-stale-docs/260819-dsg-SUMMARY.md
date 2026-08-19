---
quick_id: 260819-dsg
status: complete
date: 2026-08-19
description: Rewrite README.md to describe the real Zual app and refresh the stale scaffold-era sections of .claude/CLAUDE.md plus their .planning/codebase/ source files
---

# Quick Task 260819-dsg — Summary

## What was wrong

Two documents still described the pre-Zual Flutter scaffold, ~6 weeks after v1.0 shipped:

- `README.md` was verbatim `flutter create` output — "A new Flutter project." plus links to
  the Flutter codelab.
- `.claude/CLAUDE.md`'s `stack`, `conventions`, and `architecture` blocks were generated on
  2026-07-06 against the Hello World scaffold and had since become actively misleading:
  they named a non-existent `MyHomePage`, asserted "no state management library (GetX,
  Riverpod, Provider) currently used" and "all widgets are `StatelessWidget`", listed
  "all code in single file" and "hardcoded theme" as anti-patterns to fix (both long since
  fixed), omitted every direct runtime dependency in favour of transitive test packages,
  and called Web a "primary target" while claiming iOS config was present.

Because those three blocks are GSD-generated (`<!-- GSD:stack-start source:codebase/STACK.md -->`),
editing CLAUDE.md alone would have been reverted on the next regeneration — so the three
`source:` files were rewritten too.

## What changed

| File | Change |
|---|---|
| `README.md` | Full rewrite: what Zual is, the four scenes with a screenshot row, session walkthrough, v1.0 status, setup/test/release commands, store-asset regeneration, repo layout table, a "how it works" section, doc pointers, licensing note |
| `.planning/codebase/STACK.md` | Real direct dependencies, Android-only v1 posture, bundled fonts/icons, signing config, verified toolchain versions, "notably absent by design" list |
| `.planning/codebase/ARCHITECTURE.md` | Replaced the `MyApp → MyHomePage` diagram with the real layering; documented the `ChangeNotifier`+`provider` state model, `TimerPhase` machine, `SceneRenderer` contract, plugin-isolation pattern, lifecycle reconciliation; replaced the three obsolete anti-patterns with the three real standing issues |
| `.planning/codebase/CONVENTIONS.md` | Conventions actually observed: relative imports inside `lib/` vs `package:zual/` in `test/`, planning-ID-citing dartdoc, `AppTokens` namespace, constructor injection, dependency rules, testing conventions |
| `.claude/CLAUDE.md` | Regenerated the `stack`, `conventions`, and `architecture` block bodies from the above; all 14 GSD markers byte-identical; `project`/`skills`/`workflow`/`profile` blocks untouched |

## Verification

- `flutter analyze` — **No issues found**
- `flutter test` — **134 tests, all passed** (README's stated count corrected to match)
- `grep -c '<!-- GSD:' .claude/CLAUDE.md` → **14** (7 start + 7 end, unchanged)
- No occurrence of `MyHomePage`, `deep purple`, `A new Flutter project`, `GetX`, `Riverpod`,
  or the stale `3.18.0-18.0.pre` version string remains in any of the five files
- All five screenshot paths referenced by the README resolve in `screenshots/`
- `git status` confirms **no file under `lib/` or `test/` was modified** — documentation only

Every factual claim was checked against the repo rather than against `.planning/` prose.
Corrections found while doing so: the toolchain is Flutter 3.44.5 / Dart 3.12.2 (not the
3.18.0-18.0.pre.54 recorded in the old STACK.md); there is no `ios/` directory at all
(the old docs claimed iOS config was present); and the test-file count is 21 `_test.dart`
files plus 4 non-suffixed helpers, not 25 tests.

## Deliberately not changed

- `.planning/codebase/STRUCTURE.md`, `TESTING.md`, `CONCERNS.md`, `INTEGRATIONS.md` — also
  dated 2026-07-06 and equally stale, but they do not feed CLAUDE.md. Refreshing them is a
  `/gsd-map-codebase` run, not part of this task.
- The `project`, `skills`, `workflow`, and `profile` blocks of CLAUDE.md — already accurate.
- All source code. Three real defects were *documented* as standing anti-patterns rather
  than fixed here, since this was a docs task:
  1. `test/tool/generate_launcher_icon_test.dart` and `generate_store_icon_test.dart` rewrite
     committed PNGs on every `flutter test` run (byte-stable today, so the tree stays clean).
  2. `lib/screens/placeholder_running_screen.dart` is unreferenced dead code.
  3. `android/app/build.gradle.kts` leaks a `FileInputStream` and has no guard against a
     debug-signed release build.

  All three are pre-existing accepted debt from `05-REVIEW.md` / PROJECT.md, not regressions.

## Suggested follow-ups

- Add a `LICENSE` file — none exists, so the repo is "all rights reserved" by default, which
  is worth resolving before Play Store publication.
- Run `/gsd-map-codebase` to refresh the remaining four `.planning/codebase/` documents.
- Delete the dead `placeholder_running_screen.dart` and clear the three build/test debts above.
