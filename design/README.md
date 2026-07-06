# Handoff: Zual — Visual Timer for Young Children

## Overview
**Zual** is a visual countdown timer for children roughly ages 2–6 who don't yet understand
minutes and hours. A parent sets a duration and picks a "scene"; the child then watches a
full-screen, wordless, number-free visualization that makes *time remaining* readable at a
glance from across a room. When the timer ends, a soft chime plays and the visual settles
into a calm finished state.

The app is deliberately **not** a productivity tool: playful but calm, soft rounded shapes,
a warm palette, suitable for a bedroom or kitchen counter.

There are three phases:
1. **Setup** (parent-facing) — one screen, three steps: pick a duration, pick a scene, tap Start.
2. **Running** (child-facing) — full-screen, zero text, zero numbers, nothing tappable by the child.
3. **Completed** — soft beep, the visual rests in its end state, a calm return affordance for the parent.

Target form factor: **portrait phone / tablet** (design reference frame 402 × 874, iPhone-class).

---

## About the Design Files
The files in this bundle are **design references created in HTML** — prototypes that show the
intended look and behavior. They are **not production code to copy line-for-line**.

The task is to **recreate these designs in your target codebase's environment** (React Native,
SwiftUI, Flutter, Jetpack Compose, a web PWA, etc.) using its established patterns, component
library, and animation primitives. If no environment exists yet, choose the most appropriate
framework for a calm, full-screen, animation-heavy kids' app (React Native / Expo or SwiftUI
are both good fits) and implement the designs there.

The prototype's internal architecture (a small state machine + a `requestAnimationFrame`
progress loop + inline styles) is a faithful description of the *logic* to reproduce, but the
*rendering* should use your platform's idioms (e.g. `Animated`/Reanimated, SwiftUI animations,
`CustomPainter`, SVG/Canvas).

---

## Fidelity
**High-fidelity (hifi).** Colors, typography, spacing, radii, easing, and interaction timings
below are final and exact. Recreate the UI pixel-accurately using your codebase's libraries.

---

## Screens / Views

### A. Setup — Layout A (default) *(parent-facing)*
- **Purpose:** Parent chooses duration + scene and starts the timer in three glanceable steps.
- **Layout:** Vertical flex column filling the screen.
  - **Header** (fixed): centered. `padding: 52px 24px 8px` (52px top = status-bar safe area).
    "Zual" wordmark + tagline.
  - **Scrollable body** (`flex:1; overflow-y:auto; padding: 12px 22px 4px`), two sections, `gap: 26px`:
    - **"How long?"** — section label (16px/700), then a **3-column grid** (`gap:12px`) of six
      buttons: presets **1, 5, 10, 15, 30** min + a **Custom** button. Each button:
      `background:#FFFCF6; border-radius:22px; padding:16px 6px`, big number (30px/700) over
      "min" (12px/600, #93826F). Selected state = a 3px `#7FA87A` inset ring overlay.
    - Selecting **Custom** reveals a stepper row: **− / value / +**; big value (36px/700) + "minutes".
      Round − and + buttons (48px, `#F1E6D3`). Range **1–120**.
    - **"Pick a scene"** — section label, then a **2×2 grid** (`gap:12px`) of four theme cards.
      Each card: `#FFFCF6`, `border-radius:22px`, `padding:10px`; a 74px-tall mini preview
      (`border-radius:16px`) over a left-aligned label (13px/700). Selected = 3px `#7FA87A` ring.
  - **Footer** (fixed, `padding:14px 22px 26px`): full-width **Start** button.
- **Start button:** `background:#7FA87A; color:#FFFDF7; border-radius:26px; padding:20px;
  font-size:21px/700; box-shadow:0 8px 20px rgba(127,168,122,0.4)`. Label: `Start · {N} min`.
  Hover → `#6E9A68`.

### B. Setup — Layout B (alternate)
- Same content and handlers as A, presented as **three explicitly numbered step cards**
  (each `#FFFCF6`, `border-radius:26px`, `padding:18px`, with a 26px green numbered chip):
  1. **Choose a length** — horizontal, scrollable row of **62px circular** buttons
     (1/5/10/15/30 + "Set custom"); selected = 3px `#7FA87A` inset-ring. Same custom stepper.
  2. **Choose a scene** — 4-column row of compact scene thumbnails (58px tall) + short labels
     (Disc / Sunrise / Walk home / Car ride).
  3. **Start the timer** — full-width Start button.
- This is exposed in the prototype as a tweak (`setupLayout: 'A' | 'B'`). Ship **A** by default;
  B is an alternative to evaluate.

### C. Running — Shrinking Disc *(child-facing, the hero)*
- **Purpose:** The anchor screen. A solid disc that shrinks as time passes.
- **Layout:** Full-bleed, `background:#F6EBDD`, centered. A faint **dashed track ring**
  (310px, `2px dashed rgba(75,64,56,0.14)`) marks the full/original size for reference
  (toggleable — `showTrackRing`). The **disc** is a 300px circle, `transform: scale(remaining)`,
  where `remaining = 1 − progress` (1 → full, 0 → gone). `box-shadow:0 20px 55px rgba(0,0,0,0.10)`.
- **Color zones** (function of `remaining` r):
  - `r > 0.5` → green `#7FA87A`
  - `0.2 < r ≤ 0.5` → lerp **yellow→green** `#E8B75A`→`#7FA87A` over that range
  - `r ≤ 0.2` → lerp **red→yellow** `#DE6A4B`→`#E8B75A` (final stretch turns red)
- **Nothing is tappable** by the child.

### D. Running — Night to Sunrise
- Full-bleed sky that interpolates **night → day** by `progress` (p):
  - Sky gradient top `#182449→#8FC9EA`, bottom `#3A2F5C→#FFDBA6` (linear-gradient 180°).
  - **Stars** (~28 small white dots, gentle twinkle) fade out: `opacity = 1 − p*2.3`.
  - **Moon** (72px, `#EDE7D6`, top-right) fades out: `opacity = 1 − p*1.7`.
  - **Sun** (130px, radial `#FFE9AE→#F3AE44`) rises: `top = (86 − p*64)%`; glow grows with p.
  - **Hill** silhouette at the bottom warms: `#26314F→#6E9060`.
- Ends at full daylight (sun high, no stars/moon).

### E. Running — Walking Home
- Side-scrolling scene: soft sky gradient, green ground, a dirt **path** band, a **house**
  (triangle roof `#C98A5E`, body `#EAD7B8`, door `#B5794E`, window) on the right.
- A small rounded **character** (skin head `#F0C9A0` w/ two dot eyes, coral body `#E0805F`)
  walks left→right with a gentle vertical bob. Horizontal position `left = 6 + p*62 %`.
  **Distance remaining = time remaining**; arrives at the door at p = 1.

### F. Running — Car on a Road
- Same path mechanic as E. Warm sky, dark **road** with a dashed center line, house destination
  on the right. A rounded **car** (body `#DE6A4B`, window `#F0B49B`, two spinning wheels
  `#3A3230`/`#6B5E58` rim) drives left→right; `left = 6 + p*62 %`. Arrives at p = 1.

### G. Parent Controls (overlay, revealed on any running screen)
- **Trigger:** a **hidden long-press** anywhere on the running screen (**≈850ms**). The child
  can't reach it with a normal tap.
- **UI:** a bottom sheet over a scrim (`rgba(40,32,26,0.42)` + 3px blur). Sheet `#FBF4E8`,
  `border-radius:30px 30px 0 0`, grab handle, title "Parent controls", then two buttons:
  **Pause/Resume** (`#7FA87A`) and **End timer** (`#E0805F` → returns to Setup), plus a
  text button **"Keep watching"** to dismiss and let it keep running.

### H. Completed
- **Purpose:** Calm finish — *not* celebratory, *not* an alarm.
- On finish: play a **soft chime**; the active scene settles into its end state
  (disc fully gone / full sunrise / character at the door / car arrived).
- A gently breathing pill appears near the bottom: **"All done — tap when ready"**
  (`background: rgba(255,253,247,0.94)` + blur, `border-radius:24px`, `padding:15px 28px`,
  `animation: breathe 2.8s ease-in-out infinite`) → returns to Setup. Child ignores it; parent taps it.

---

## Interactions & Behavior
- **Phase machine:** `setup → running → done`, plus a `paused` sub-state of running.
  `End timer` returns any phase to `setup` and resets progress to 0.
- **Countdown:** on Start, record `totalMs = minutes*60000` and a start timestamp; drive
  `progress = clamp(elapsed / totalMs, 0..1)` via `requestAnimationFrame`. At `progress ≥ 1`,
  stop, play chime, enter `done`. In the reference this uses rAF; on native prefer a timed
  animation driver (Reanimated / SwiftUI `withAnimation` / a display link) for battery-friendly
  smoothness.
- **Pause / Resume:** freeze `progress`; accumulate paused time so resume continues correctly.
- **Long-press → controls:** 850ms sustained press opens the parent sheet. Release before that = nothing.
- **End chime (calm):** two soft sine notes — **D5 (587.33 Hz)** then **G5 (783.99 Hz)**, ~0.3s
  apart. Envelope per note: gain ramps to ~0.16 over 60ms, then exponential decay to ~0 over ~1.1s.
  No harsh alarm, no looping. Toggleable (`soundOn`).
- **Transitions:** progress-driven properties animate with short linear transitions
  (`transform 0.12s linear`, color `0.4s linear`, sun `top 0.12s linear`). Twinkle, walk-bob,
  wheel-spin, and the done-pill "breathe" are looping CSS keyframes:
  - `bob`: translateY 0 → −7px → 0, 0.62s ease-in-out infinite
  - `spin`: rotate 360°, 0.7s linear infinite
  - `twinkle`: opacity 0.35 → 1 → 0.35, 3s ease-in-out infinite (staggered delay)
  - `breathe`: scale 1 → 1.05 → 1, 2.8s ease-in-out infinite

## State Management
- `phase`: `'setup' | 'running' | 'done'`
- `theme`: `'disc' | 'sunrise' | 'walk' | 'car'`
- `durationMin`: selected preset (default 5); `customMin`: 1–120 (default 3); `showCustom`: boolean
- `progress`: 0..1 (derived from elapsed time while running)
- `paused`: boolean; `controlsOpen`: boolean
- Timing internals: `totalMs`, `startTs`, `pausedTotal`, `pauseStart`
- No accounts, no tasks, no persistence, no network. (Optional nicety: remember last-used
  duration + theme locally.)

## Design Tokens
**Color**
- Background (app): `#F6EBDD` · board/desk: `#EAE1D3`
- Card surfaces: `#FFFCF6`, `#FBF4E8`, `#F3E8D6`, `#F1E6D3`
- Text ink: `#4B4038` · soft/secondary: `#8A7B6B`, `#93826F`
- Primary green: `#7FA87A` (hover `#6E9A68`) · destructive/warm: `#E0805F` (hover `#D06E4C`)
- Disc zones: green `#7FA87A`, yellow `#E8B75A`, red `#DE6A4B`
- Scene: character skin `#F0C9A0`, body `#E0805F`; house roof `#C98A5E`, wall `#EAD7B8`,
  door `#B5794E`; car body `#DE6A4B`, window `#F0B49B`, wheel `#3A3230` / rim `#6B5E58`; road `#5A5048`
- Sky night→day: top `#182449`→`#8FC9EA`, bottom `#3A2F5C`→`#FFDBA6`; moon `#EDE7D6`;
  sun `#FFE9AE`→`#F3AE44`; hill `#26314F`→`#6E9060`

**Typography**
- Display / wordmark: **Baloo 2** (700) — "Zual"
- UI: **Quicksand** (400/500/600/700)
- Scale: wordmark 34–40px; section labels 16px/700; button numbers 30px/700; body/labels 12–15px

**Radius:** buttons 22px · cards 26px · pills 24–26px · scene thumbs 14–16px · circular controls 50%

**Shadow:** card `0 2px 6px rgba(75,64,56,0.05)` · Start button `0 8px 20px rgba(127,168,122,0.4)` ·
disc `0 20px 55px rgba(0,0,0,0.10)` · sheet `0 -10px 40px rgba(0,0,0,0.25)`

**Spacing:** screen gutters 22–24px · grid gap 12px · section gap 26px

**Durations:** presets 1 / 5 / 10 / 15 / 30 min; custom 1–120 min. Long-press threshold 850ms.

## Assets
- **No image assets.** All visuals (disc, sun, moon, stars, character, house, car, road) are
  built from CSS primitives (circles, rounded rectangles, gradients, CSS-border triangles for
  roofs). Reproduce with vector/shape primitives on your platform (SVG, SwiftUI Shapes, Canvas).
- **Fonts:** Quicksand + Baloo 2 (Google Fonts). Bundle equivalents on native.
- **Sound:** the chime is generated with the Web Audio API (two sine tones) — no audio file.
  Reproduce with a tone generator or bundle a matching short two-note WAV.

## Files
In this bundle:
- `Zual.dc.html` — the full working prototype (setup + all four running themes + completed +
  parent controls + chime). Open in a browser to interact. Pick **1 min** to watch a full cycle
  quickly; a hidden ~850ms long-press on the running screen opens parent controls.
- `Zual — App Screens.dc.html` — the annotated screen-flow board (every screen/state laid out
  in iPhone frames).
- `ios-frame.jsx` — the device-frame component used only by the screen board (presentation
  scaffold; **not** part of the app).
- `support.js` — runtime needed to open the two `.dc.html` files locally. Not app code.

> Note: `.dc.html` files are the design/prototype format used to author these references.
> Treat them as visual + behavioral spec, and rebuild in your codebase per the sections above.
