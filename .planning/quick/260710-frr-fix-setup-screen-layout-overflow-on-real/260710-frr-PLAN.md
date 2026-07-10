---
phase: quick
plan: 260710-frr
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/screens/setup_screen.dart
  - lib/widgets/scene_grid.dart
  - test/screens/setup_screen_test.dart
autonomous: true
requirements: [QUICK-FRR-SETUP-OVERFLOW]
must_haves:
  truths:
    - "On a Samsung A25-sized viewport (~393x851 dp) the Setup screen shows the wordmark, both 'How long?' presets and the 'Pick a scene' picker fully, with the Start footer visible, and requires no scrolling to reach the scene cards."
    - "The layout adapts across screen sizes (short/narrow/tall) via LayoutBuilder/MediaQuery-driven sizing, not a single magic number tuned to one device."
    - "A SingleChildScrollView safety net still prevents hard clipping on extremely short screens."
  artifacts:
    - lib/screens/setup_screen.dart
    - lib/widgets/scene_grid.dart
    - test/screens/setup_screen_test.dart
  key_links:
    - "LayoutBuilder available height -> computed scene-grid childAspectRatio (fit-to-space)."
    - "Adaptive header top padding + inter-section gap driven by MediaQuery / available height."
---

<objective>
Fix the Setup screen vertical overflow reported from on-device testing on a Samsung A25: the "How long?" duration presets plus the scene picker exceed the viewport by ~1cm, clipping the bottom scene row and forcing an unintended scroll on a screen the design intends to read at a glance.

Purpose: Make the Setup screen genuinely responsive so its content fits within the viewport across real device sizes, not just the A25, while keeping the existing scroll safety net for extreme cases.

Output: Responsive sizing in `SetupScreen` (adaptive header padding, adaptive inter-section gap, fit-to-space scene-grid sizing) plus a regression widget test at A25-like dimensions. Layout-only change — no interaction, state, or persistence logic is touched.
</objective>

<context>
@.planning/STATE.md
@./CLAUDE.md
@lib/screens/setup_screen.dart
@lib/widgets/scene_grid.dart
@lib/theme/app_tokens.dart
@test/screens/setup_screen_test.dart

Current structure (already read): `Scaffold > SafeArea > Column` with a fixed `_buildHeader()` (top padding 52), an `Expanded > SingleChildScrollView` holding the "How long?" `GridView.count` (3-col, `childAspectRatio: 1.1`) + optional custom stepper + "Pick a scene" `SceneGrid` (2-col, `childAspectRatio: 1.35`), and a fixed `_buildFooter()` (Start button). The middle region already scrolls, so there is no RenderFlex crash — the defect is that the natural content height slightly exceeds the A25 viewport, so the last scene row sits below the fold.

Constraints (from the task):
- Layout-only. Do NOT change interaction logic, state, persistence, or the 850ms long-press threshold in HoldRepeatButton.
- All existing tests in `test/screens/setup_screen_test.dart` MUST still pass unchanged. They rely on `SingleChildScrollView` staying scrollable (they call `ensureVisible` before tapping scene/custom cells at the 800x600 test surface) — keep the scroll view.
- Prefer LayoutBuilder/MediaQuery-driven sizing, Flexible/Expanded, and the SingleChildScrollView safety net over a fixed magic-number tweak.
- Do not alter the SceneGrid theme->label / theme->painter mappings or the selection-ring keys (widget tests assert on `scene-ring-*`, `preset-ring-*`, `custom-ring`, `stepper-*`, `start-button`).
</context>

<tasks>

<task type="auto">
  <name>Task 1: Make the Setup screen content fit responsively</name>
  <files>lib/screens/setup_screen.dart, lib/widgets/scene_grid.dart</files>
  <action>
Make the middle region fit the available viewport instead of overflowing ~1cm on the A25, using measured space rather than one hardcoded device tweak.

1. In `SceneGrid` (lib/widgets/scene_grid.dart): add an optional constructor parameter `double childAspectRatio` defaulting to `1.35` (its current value), stored as a final field and passed to the internal `GridView.count(childAspectRatio: ...)`. Keep the default so every other caller and existing test behaves identically. Do not touch the `_labels`/`_painters` maps, the `onSelect` wiring, or the selection-ring key. This is purely a sizing hook.

2. In `_SetupScreenState.build` (lib/screens/setup_screen.dart): wrap the current `SingleChildScrollView` body inside a `LayoutBuilder` placed under the existing `Expanded`. Use `constraints.maxHeight` as the available height for the scroll region. Add `key: const ValueKey('setup-scroll')` to the `SingleChildScrollView` so tests can target the outer scrollable (the two inner grids are also Scrollables and must not be confused with it). Keep the SingleChildScrollView as the safety net — do not remove it.

3. Replace the fixed `const SizedBox(height: 26)` gap between the duration section and the "Pick a scene" section with a responsive gap computed from available height: gap = `(constraints.maxHeight * 0.03).clamp(12.0, 26.0)`. This tightens spacing on short screens and preserves the design's 26 on tall ones.

4. Make the "How long?" duration grid slightly shorter on short screens: compute its `childAspectRatio` as `(constraints.maxHeight >= 640 ? 1.1 : 1.2)` (flatter cards reclaim height without changing the design on normal/tall screens). Keep `crossAxisCount: 3`, spacing 12, shrinkWrap, NeverScrollableScrollPhysics.

5. Compute a fit-to-space `childAspectRatio` for the `SceneGrid` so the scene picker consumes only the vertical space that remains after the duration grid, labels, gaps, paddings, and (when shown) the custom stepper row. Approach: estimate the non-scene fixed cost inside the scroll region (top padding, both section-label blocks, the responsive gap, bottom padding, duration-grid height derived from its own aspect ratio, plus the stepper row height when `_showCustom`), subtract from `constraints.maxHeight` to get the space available for the 2-row scene grid, derive the per-cell height from that (accounting for the 12 mainAxisSpacing between the two rows), convert to an aspect ratio from the known 2-column cell width (`(contentWidth - 12) / 2`, where `contentWidth = MediaQuery.sizeOf(context).width - 44` for the 22+22 horizontal scroll padding), and `clamp` the result to `[1.35, 2.4]`. Clamping at 1.35 guarantees the scene cards are never taller than the design; the 2.4 upper bound prevents ultra-flat cards on tiny screens (where the SingleChildScrollView then handles any residual overflow). Pass this value to `SceneGrid(childAspectRatio: ...)`.

6. Make the header vertical space adaptive so it stops eating fixed height on short devices. In `_buildHeader`, change the top padding from the fixed `52` to `(MediaQuery.sizeOf(context).height * 0.055).clamp(24.0, 52.0)` (keep the 24/24 horizontal and 8 bottom paddings, the centered Column, the wordmark, and the tagline exactly as-is). This recovers ~10dp on the A25 while preserving the design on tall screens.

Do not change any colors, radii, fonts, the footer, the custom stepper internals, the 850ms long-press button, `_handleStart`, persistence, or any selection-ring/value keys. Every change above is spacing/sizing only.
  </action>
  <verify>
    <automated>cd D:/Projects/zual && flutter analyze lib/screens/setup_screen.dart lib/widgets/scene_grid.dart</automated>
  </verify>
  <done>SceneGrid accepts an optional childAspectRatio (default 1.35). SetupScreen's scroll body is wrapped in a LayoutBuilder that drives an adaptive inter-section gap, an adaptive duration-grid aspect ratio, a fit-to-space clamped scene-grid aspect ratio, and an adaptive header top padding; the SingleChildScrollView (now keyed 'setup-scroll') is preserved. flutter analyze reports no new issues.</done>
</task>

<task type="auto">
  <name>Task 2: Add A25-size regression test and prove existing tests still pass</name>
  <files>test/screens/setup_screen_test.dart</files>
  <action>
Add one new `testWidgets` case (in a new group, e.g. `'SetupScreen responsive layout'`) that reproduces the A25 viewport and asserts the content now fits without scrolling:

1. Set the surface to A25-like logical dimensions before pumping: `tester.view.physicalSize = const Size(1080, 2340); tester.view.devicePixelRatio = 2.75;` and register `addTearDown(tester.view.reset);` so the surface change does not leak into other tests. This yields roughly 393x851 dp.

2. Pump the existing `_harness(controller)` (reuse the helper already in this file; use the injected-clock TimerController pattern the other tests use, and dispose it at the end).

3. Assert no layout overflow was thrown: `expect(tester.takeException(), isNull);`.

4. Assert the scene picker fits without scrolling: locate the outer scroll view via `find.byKey(const ValueKey('setup-scroll'))`, get its Scrollable position (e.g. `tester.state<ScrollableState>(find.descendant(of: find.byKey(const ValueKey('setup-scroll')), matching: find.byType(Scrollable)))`), and assert `position.maxScrollExtent == 0.0` — i.e. all content fits in the A25 viewport with zero scroll extent. Use a tolerance-free equality on 0.0 (the fit-to-space sizing targets exact fit; if this proves flaky by sub-pixel amounts, assert `lessThanOrEqualTo(0.5)` instead).

5. Assert both section labels and all four scene labels are present and rendered without needing `ensureVisible`: `expect(find.text('How long?'), findsOneWidget);`, `expect(find.text('Pick a scene'), findsOneWidget);`, and each of 'Shrinking disc', 'Night to sunrise', 'Walking home', 'Car on a road' `findsOneWidget`.

Do not modify any existing test. The existing suite runs at the default 800x600 surface where the scene grid legitimately still scrolls (those tests call `ensureVisible`); the new test is the only one that fixes an A25-sized surface.
  </action>
  <verify>
    <automated>cd D:/Projects/zual && flutter test test/screens/setup_screen_test.dart</automated>
  </verify>
  <done>The new A25-size test passes: no overflow exception, outer scroll view maxScrollExtent is 0 (content fits without scrolling), both section labels and all four scene cards render. All pre-existing tests in setup_screen_test.dart continue to pass unchanged.</done>
</task>

</tasks>

<verification>
- `flutter analyze` reports no new issues in the two changed source files.
- `flutter test test/screens/setup_screen_test.dart` passes fully, including the new A25-size regression test and all pre-existing SETUP-01..04 / SETUP-02 / SETUP-03 / persistence / navigation tests unchanged.
- Manual on-device sanity (developer, out of automated scope): on a Samsung A25 the wordmark, presets, and scene picker fit with the Start button visible and no ~1cm clipping.
</verification>

<success_criteria>
- Setup screen content fits within the A25 viewport (maxScrollExtent 0 at ~393x851 dp) without clipping the bottom scene row.
- Sizing is responsive (LayoutBuilder available-height + MediaQuery-driven), not a single device-specific constant; SingleChildScrollView remains as the safety net for extreme screens.
- Zero changes to interaction logic, state, persistence, the 850ms long-press threshold, colors/radii/fonts, or any widget-test keys; all existing tests pass unchanged.
</success_criteria>

<output>
Create `.planning/quick/260710-frr-fix-setup-screen-layout-overflow-on-real/260710-frr-SUMMARY.md` when done.
</output>
