---
status: resolved
trigger: "On tablets (not phones), the Setup screen's responsive layout breaks in two ways: (1) the \"How long\" duration preset squares are too large and their text is too small relative to the square size, and (2) on the \"Pick a scene\" grid, the scene preview artwork inside each selectable scene card only fills about 2/3 or half of the card's square area (the exact fraction varies depending on screen size) instead of filling it proportionally like it does on phones — the card itself still highlights correctly when selected, but the scene preview art doesn't scale to match the card. This looks fine on mobile devices; it's specifically a tablet/larger-screen regression."
created: 2026-07-12
updated: 2026-07-12
---

## Symptoms

- **Expected behavior:** On tablet screen sizes, the "How long" duration preset squares should scale proportionally (square size and internal label text should scale together, matching the visual balance seen on phones), and each scene-card's preview artwork should fill its selectable card's square area proportionally (as it does on phones), regardless of screen size.
- **Actual behavior:** On tablets, the "How long" preset squares are oversized relative to their label text (text reads too small inside an oversized square). On the "Pick a scene" grid, the scene preview artwork inside each card only fills roughly 2/3 to 1/2 of the card's square area (fraction varies by screen size) — leaving visible empty margin inside the card — even though card selection highlighting still renders correctly at the full card bounds.
- **Error messages:** None — this is a purely visual/layout defect, no exceptions or console errors reported.
- **Timeline:** Always broken on tablets, per user confirmation — this is the first time tablet screen sizes have really been tested/looked at, not a regression from a specific recent change. (Quick task 260710-frr made the Setup screen responsive for a phone form factor — Samsung A25 — and may not have accounted for tablet breakpoints, but the user believes tablets have never looked right, so treat this as a pre-existing gap rather than assuming 260710-frr caused it.)
- **Reproduction:** Run the app on an Android Studio tablet emulator profile (e.g. Pixel Tablet / Nexus 10 class device) and open the Setup screen. Observe the "How long" duration presets (square + text) and the "Pick a scene" grid (SceneCard squares with ScenePreviewPainter artwork inside).

## Relevant code (from prior context, not yet verified this session)

- Setup screen: `lib/` SetupScreen widget
- "How long" duration presets: preset square / HoldRepeatButton area
- Scene picker: SceneGrid → SceneCard → ScenePreviewPainter abstraction (SceneCard depends only on ScenePreviewPainter per design decision D-06, phase 2)
- Prior related fix: quick task `260710-frr` — "Fix Setup screen layout overflow on real device (Samsung A25) — How-long presets and scene picker overflow viewport by ~1cm; make responsive so it fits without clipping" (see `.planning/quick/260710-frr-fix-setup-screen-layout-overflow-on-real/`)

## Current Focus

hypothesis: Both tablet symptoms share one root cause — the Setup layout stretches its grids to the full screen width (contentWidth = screenWidth - 44), so grid CELLS grow on wide screens, but the INTERIOR content of those cells is fixed-size (74px scene thumbnail; 30/12pt preset fonts). On phones (design reference 402px wide) the cells happen to match the fixed content; on tablets the cells outgrow it.
test: Apply two surgical fixes: (1) cap the layout column to a phone-class max width and center it, so preset squares stay phone-proportioned (fixes symptom 1); (2) make the scene thumbnail fill the card (Expanded) instead of a fixed 74px box, so artwork fills the card at any cell size (fixes symptom 2). Verify existing widget tests + flutter analyze pass, then human-verify on a tablet emulator.
expecting: Presets read phone-proportioned; scene artwork fills each card.
next_action: implement the two edits, run flutter test + flutter analyze, then request human verification on a tablet emulator

reasoning_checkpoint:
  hypothesis: "The layout scales cell DIMENSIONS to fill full screen width, but cell INTERIOR content is fixed-size. On tablets cells grow past their fixed content → oversized preset squares with small text (symptom 1) and scene artwork that fills only a fraction of the card (symptom 2)."
  confirming_evidence:
    - "setup_screen.dart:155 contentWidth = MediaQuery width - 44 (full-bleed); duration cell width = (contentWidth-24)/3 and scene cell width = (contentWidth-12)/2 both grow with screen width."
    - "Preset text is fixed pt (AppTokens.presetNumber 30, presetUnit 12) — never scaled with cell. On an ~800px tablet the preset cell is ~244x222px with 30pt text → text looks tiny in an oversized square."
    - "scene_grid.dart:62-66 thumbnail is SizedBox(height: 74) — a hardcoded height. On tablets the scene cell is much taller (fit-to-space aspect ratio floors at 1.35), so the 74px thumbnail fills only ~30-64% of the card while the selection ring (Positioned.fill) still spans the full cell — exactly matching 'artwork fills 1/2 to 2/3, card highlights at full bounds'."
    - "design/README.md:18 states the design reference frame is 402x874 (phone-class) — the layout was only ever tuned for phone width; tablet is an untested gap, matching the reported 'always broken on tablets'."
  falsification_test: "If, after capping the layout width to phone-class and centering, the preset squares still render oversized with tiny text — OR the scene thumbnail (now Expanded) still leaves empty card margin on a tablet — the hypothesis is wrong."
  fix_rationale: "Capping width keeps the preset cells at phone dimensions so text/square balance matches phones (addresses root cause of symptom 1, not a symptom). Making the thumbnail Expanded makes artwork proportionally fill the card at any cell height (addresses root cause of symptom 2). Both target the fixed-content-vs-growing-cell mismatch directly."
  blind_spots: "Cannot run a tablet emulator here — verification of the visual result on a real tablet profile must be done by the user. Chosen max width (440) is a judgement call; if it reads too narrow/wide on the target tablet the constant may need tuning."

## Evidence

- timestamp: 2026-07-12
  checked: lib/screens/setup_screen.dart build() and sizing helpers
  found: contentWidth = MediaQuery.sizeOf(context).width - 44 (line 155). Grids are laid out at full width; duration cell width = (contentWidth-24)/3, scene cell width = (contentWidth-12)/2. Aspect-ratio helpers only control cell height:width ratio — they never scale interior text/thumbnail. On a ~800px-wide tablet the duration cell is ~244px wide.
  implication: Cell dimensions grow with screen width but nothing scales the interior content up to match.

- timestamp: 2026-07-12
  checked: lib/theme/app_tokens.dart preset text styles
  found: presetNumber = 30pt fixed, presetUnit = 12pt fixed. No responsive scaling.
  implication: Symptom 1 — on a ~244px tablet cell, fixed 30pt text looks tiny relative to the oversized square. On a ~110px phone cell (design frame 402) the same 30pt reads balanced.

- timestamp: 2026-07-12
  checked: lib/widgets/scene_grid.dart SceneCard.build()
  found: thumbnail is ClipRRect > SizedBox(height: 74, width: double.infinity) > CustomPaint — a HARDCODED 74px height. Column uses mainAxisSize.min; PressableSurface gets alignment:null so content sits top-left. Selection ring is Positioned.fill (spans full cell).
  implication: Symptom 2 — on tablets the scene cell is much taller than 74+label (fit-to-space ratio floors at 1.35), so the fixed 74px thumbnail fills only a fraction of the card while the ring highlights the full cell. The "fraction varies by screen size" because it equals 74 / actual-card-height, which varies. On phones the maxSafeSceneAspectRatio cap makes cell height ≈ 74+label, so the thumbnail fills.

- timestamp: 2026-07-12
  checked: design/README.md line 18
  found: "Target form factor: portrait phone / tablet (design reference frame 402 x 874, iPhone-class)."
  implication: The design/layout was tuned to a 402px-wide phone. Tablet width was never accounted for — consistent with "always broken on tablets", a pre-existing gap not a regression.

- timestamp: 2026-07-12
  checked: test/screens/setup_screen_test.dart
  found: No test asserts pixel dimensions, aspect ratios, or the 74px thumbnail; tests run at the default 800x600 test surface and only check presence/selection/navigation behavior.
  implication: The planned fixes are unlikely to break existing tests.

## Eliminated

- hypothesis: A recent change (quick task 260710-frr) introduced the tablet defect.
  evidence: User confirms tablets have "always" looked wrong (Timeline in Symptoms), and design/README.md:18 shows the layout was only tuned for a 402px phone frame. This is a pre-existing tablet gap, not a regression from 260710-frr.
  timestamp: 2026-07-12

## Resolution

root_cause: The Setup screen stretches its two grids to the full screen width (contentWidth = screenWidth - 44), so grid cell dimensions grow on wide (tablet) screens, but the cells' interior content is fixed-size — the preset number/unit fonts (30/12pt) and the scene-card thumbnail (hardcoded SizedBox height: 74). On the 402px-wide design reference phone the cells match this fixed content, but on tablets the cells outgrow it: preset squares become oversized with proportionally tiny text, and the 74px thumbnail fills only a fraction of the now-taller scene card (while the full-cell selection ring still highlights correctly).
fix: |
  Two surgical changes targeting the fixed-content-vs-growing-cell mismatch:
  (1) lib/screens/setup_screen.dart — added `_maxContentWidth = 440` and cap the
      layout column to it, centered (Center > SizedBox(width: layoutWidth,
      height: bodyConstraints.maxHeight)). `contentWidth` and the header
      measurement width now derive from the capped `layoutWidth` instead of the
      raw MediaQuery width. On phones (<440 wide) this is a no-op; on tablets the
      grids stay phone-proportioned so preset squares/text keep the phone balance.
  (2) lib/widgets/scene_grid.dart — the SceneCard thumbnail was a fixed
      `SizedBox(height: 74)`; it now sits in an `Expanded` (and the Column no
      longer forces mainAxisSize.min) so the preview fills all leftover card
      height at any cell size. The `_maxSafeSceneAspectRatio` cap still uses 74 as
      the minimum thumbnail height, so phones render an ~74px thumbnail as before.
verification: |
  - flutter analyze (both changed files): No issues found.
  - flutter test (full suite): 134/134 pass, including "responsive layout fits the
    A25 viewport (~393x851 dp) without overflow" — confirms no phone regression.
  - Geometry probe at 800x1280 logical (Pixel Tablet class): content column width
    capped to 440 and centered (was full 800 → preset cells ~124px, phone-class,
    not ~244px); scene thumbnails now 76-95px filling all leftover card height
    (Expanded working) instead of a fixed 74px leaving empty margin.
  - CONFIRMED: human verification on tablet emulator and phone — user reported
    "Yes, it is good on all devices" (2026-07-12).
files_changed:
  - lib/screens/setup_screen.dart
  - lib/widgets/scene_grid.dart
