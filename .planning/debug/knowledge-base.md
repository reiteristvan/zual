# GSD Debug Knowledge Base

Resolved debug sessions. Used by `gsd-debugger` to surface known-pattern hypotheses at the start of new investigations.

---

## tablet-setup-layout-scaling — Setup screen layout scaled wrong on tablet form factors
- **Date:** 2026-07-12
- **Error patterns:** tablet layout, responsive layout, Setup screen, duration preset squares oversized, small text, scene preview artwork fills fraction of card, grid cell scaling, full screen width, fixed-size interior content
- **Root cause:** Setup screen stretched its two grids to full screen width (contentWidth = screenWidth - 44) so grid cell dimensions grew on wide tablet screens, but cell interior content was fixed-size (preset number/unit fonts 30/12pt; scene-card thumbnail hardcoded SizedBox height 74). On the 402px phone design frame cells matched the fixed content; on tablets cells outgrew it — oversized preset squares with tiny text, and a 74px thumbnail filling only a fraction of the taller scene card while the full-cell selection ring still highlighted correctly.
- **Fix:** (1) lib/screens/setup_screen.dart — added _maxContentWidth = 440 and cap the layout column to it, centered; contentWidth/header measurement derive from capped layoutWidth (no-op on phones). (2) lib/widgets/scene_grid.dart — SceneCard thumbnail moved from fixed SizedBox(height: 74) into an Expanded (Column no longer forces mainAxisSize.min) so the preview fills leftover card height at any cell size.
- **Files changed:** lib/screens/setup_screen.dart, lib/widgets/scene_grid.dart
---
