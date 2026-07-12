---
status: complete
phase: 05-play-store-readiness
source: [05-VERIFICATION.md]
started: 2026-07-10T13:15:00Z
updated: 2026-07-12T00:00:00Z
---

## Tests

### 1. Re-confirm the corrected adaptive icon on a real device launcher
expected: Install the current signed release build (post `260710-keg` fix) on a real Android
  device and look at the launcher icon under both circle and squircle masks. The sun disc should
  read as a clearly legible, appropriately-sized shape at 48dp, not the shrunken ~43%-diameter
  rendering WR-01 identified. The only prior on-device visual confirmation (05-05-SUMMARY.md,
  Samsung A25) happened BEFORE this fix, so it hasn't been re-checked on real hardware.
result: issue
reported: "The icon changed from before, now it just the sun with a yellow background, looking very bad. Return to the previous version and generate the appstore icon from that as well."
severity: major

### 2. Final screenshot quality pass before Play Console upload
expected: Open each of the 5 committed screenshots (screenshots/*.png) and confirm they are
  full-bleed (no added marketing device-frame graphic — the OS status bar/gesture-nav indicator
  in the raw capture are expected and normal), free of any caption overlay, and representative of
  their named scene.
result: pass

### 3. Re-confirm the reverted adaptive launcher icon on a real device launcher
expected: |
  Install the current signed release build (built from the post-05-06 config) on a real Android
  device and view the launcher icon under both circle and squircle masks. The sun disc should read
  as a clearly legible, balanced sunrise (sun within sky gradient and hill silhouette) — matching
  the appearance already approved on the Samsung A25 in 05-05-SUMMARY.md, before the
  since-reverted 260710-keg regression was ever introduced. It should NOT reproduce Test 1's
  "just the sun with a yellow background" report.
result: pass
reported: "Confirmed correct on real device — reads as a balanced sunrise, not the flat-yellow regression."

## Summary

total: 3
passed: 2
issues: 1
pending: 0
skipped: 0
blocked: 0

## Gaps

- truth: "The sun disc reads as a clearly legible, appropriately-sized shape at 48dp (the intended ~64% diameter), not the shrunken ~43%-diameter rendering that 05-REVIEW.md WR-01 identified."
  status: failed
  reason: "User reported: The icon changed from before, now it just the sun with a yellow background, looking very bad. Return to the previous version and generate the appstore icon from that as well."
  severity: major
  test: 1
  root_cause: "260710-keg's WR-01 fix (adaptive_icon_foreground_inset: 0) overcorrected. Android's adaptive-icon system independently crops every foreground/background layer to a ~72dp/108dp (66.7%) visible viewport regardless of app-level inset -- this crop stacks with whatever inset flutter_launcher_icons bakes in. At the pre-fix 16% tool inset, the sun disc rendered at ~43.5% of the full canvas (~65% fill of the 72dp visible viewport), leaving margin for the sky gradient and hill silhouette -- this was the state already verified acceptable on a real Samsung A25 in 05-05-SUMMARY.md. At 0% inset, the sun (64% of canvas, unshrunk) exceeds the 66dp guaranteed-safe zone and fills ~96% of the visible viewport, rendering nearly edge-to-edge, crowding out the sky gradient and clipping the hill silhouette -- the residual sliver is dominated by the gradient's warm bottom stop and the sun's glow halo, reading as a flat 'yellow background' rather than a two-tone sunrise. WR-01's percentage-only calculation never accounted for Android's own independent mask crop, and the fix was never re-verified on-device before being marked resolved."
  artifacts:
    - path: "pubspec.yaml"
      issue: "adaptive_icon_foreground_inset: 0 (line ~78) is the regression -- removing this line restores the tool's default 16% inset, matching the pre-260710-keg, on-device-verified state"
    - path: "android/app/src/main/res/mipmap-anydpi-v26/ic_launcher.xml"
      issue: "currently android:inset=\"0%\", needs regeneration back to 16% once pubspec.yaml is reverted"
    - path: "store_assets/icon_512.png"
      issue: "should be regenerated after the launcher fix is reverted per user's explicit request (expected byte-identical since compositing doesn't consult the XML inset value, but rerun for pipeline consistency)"
  missing:
    - "Remove adaptive_icon_foreground_inset: 0 from pubspec.yaml's flutter_launcher_icons block (revert to tool default of 16)"
    - "Rerun dart run flutter_launcher_icons to regenerate ic_launcher.xml back to android:inset=\"16%\" and legacy mipmap fallbacks"
    - "Rerun flutter test test/tool/generate_store_icon_test.dart to regenerate store_assets/icon_512.png"
    - "Do not modify test/tool/icon_painters.dart art (sun radius, gradient) -- only the inset config is the regression"
