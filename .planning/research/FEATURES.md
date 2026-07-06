# Feature Research

**Domain:** Visual/wordless countdown timer apps for young children (2–6 y/o), incl. autism/ADHD/classroom "visual timer" category
**Researched:** 2026-07-06
**Confidence:** MEDIUM (web survey of competitor apps, reviews, and special-education literature; no primary user testing)

## Feature Landscape

### Table Stakes (Users Expect These)

Features users assume exist in this category. Missing these makes the product feel incomplete or, worse, unsuitable for the sensory-sensitive kids this category often serves.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Genuinely visual, shrinking/depleting display (not digits) | This *is* the category — every credible competitor (Time Timer's red disk, wedge/pie timers, shrinking-bar timers) and the special-ed literature agree: mapping time onto a shrinking shape converts an internally-hard temporal judgment into an easy spatial one. Zual's Shrinking Disc theme already nails this. | MEDIUM | Already in scope (Shrinking Disc theme). Treat as the reference/"hero" theme — validated by research as the single most evidence-backed pattern in this category. |
| Calm, non-alarming end signal, not a jarring alarm | Reviewers explicitly criticize competitor apps for loud/harsh default sounds; the calm two-tone chime is a genuine strength already in Zual's spec. | LOW | Already in scope. Confirms the "calm-only chime, no alarm" decision in PROJECT.md Out of Scope is correct, not a gap. |
| A mute/sound-off control | Design doc mentions `soundOn` as "toggleable" in the interaction spec, but it is **not present** in Zual's `state` model, Setup screen layout, or Parent Controls sheet — no UI surface is specified for where a parent actually flips it. Competitor teardown explicitly flags "loud ticking, no easy way to turn it down" as a top complaint. | LOW | **Gap.** Recommend adding a mute/sound toggle — most natural home is the Parent Controls bottom sheet (alongside Pause/Resume, End timer) or a small icon on the Setup screen. Low complexity, high expectation. |
| Nothing tappable/reachable by the child during running state | Standard in the "kid-safe" sub-category (avoids accidental resets, avoids ad-clicks in free competitor apps). Already Zual's explicit design (long-press-only controls). | LOW | Already in scope — validated as correct, not just a nice-to-have. |
| A visible "how much time is set for" cue before starting | Parents need to glance at the setup screen and instantly know the chosen duration/scene before tapping Start (all competitor apps have this). | LOW | Already in scope (preset grid + custom stepper + Start button label "Start · {N} min"). |
| Remembering the last-used duration + scene | Reduces setup friction on repeat use (a parent doing bedtime nightly doesn't want to re-pick 10 min + Night-to-Sunrise every time). Currently framed in PROJECT.md as merely an "optional nicety" / listed under Out of Scope alongside "no persistence." | LOW | **Recommend promoting to MVP scope**, not deferring. It's explicitly called out as compatible with the "no backend/no accounts" constraint (pure local storage, e.g. `shared_preferences`), it's low complexity, and its absence is a common irritant noted in competitor reviews (re-configuring every session). Does not conflict with the "no persistence/accounts/network" architectural constraint — this is local device state only. |
| Fine-enough duration granularity | A competitor app was specifically dinged for only allowing 10-second increment adjustments where finer control was wanted. | LOW | Zual's 1–120 min stepper (1-minute increments) already clears this bar for its target age range; no action needed, just confirms current spec is adequate — do not over-engineer to sub-minute precision, it's not needed for this age group's task granularity. |

### Differentiators (Competitive Advantage)

Features that set Zual apart from the bulk of existing visual timer apps. Not required, but align with and reinforce the Core Value.

| Feature | Value Proposition | Complexity | Notes |
|---------|--------------------|------------|-------|
| Multiple narrative scene themes (Sunrise, Walking Home, Car on a Road) beyond a single disc | Most competitors ship exactly one visual metaphor (a disc or wedge). Offering a small, curated set of equally wordless metaphors lets a parent match the scene to context (bedtime → Sunrise, "we're leaving soon" → Walking Home / Car) without breaking the number-free, calm design language. | HIGH | Already in scope for all 4 themes. This is Zual's clearest differentiator vs. the shrinking-disc-only category leaders (Time Timer) — keep the visual language consistent across themes (same color-zone logic, same calm tone) so it reads as one coherent product, not four disconnected mini-apps. |
| Hidden long-press (≈850ms) parent-controls gate, rather than a visible settings/pause icon | Nearly all competitor kids-timer apps put a visible pause/settings icon on screen (reachable and temptingly tappable by a toddler). A deliberately hidden gesture is a genuine, uncommon UX differentiator that protects the "nothing tappable by the child" promise better than a merely small icon would. | MEDIUM | Already in scope. Worth defending in the roadmap — do not cave to a "just add a small gear icon" simplification; the whole value proposition rests on the child being unable to interfere. |
| Pixel-level calm design system (warm palette, soft radii, Baloo 2 / Quicksand typography) applied consistently across setup, running, and completed states | Most competitor timer apps are functional but visually utilitarian (default OS widgets, clip-art). A cohesive, considered visual identity is itself a differentiator for a product parents will look at daily. | MEDIUM | Already in scope via design tokens. This is a "taste" differentiator, not a functional one — valuable primarily for parent perception/App Store presentation, not for the child's comprehension task. |
| Distance-based metaphors (Walking Home, Car on a Road) where remaining distance == remaining time | Not seen in reviewed competitor set — most alternative-to-disc timers use generic countdown bars or gamified "reward" reveals (e.g., an egg hatching). A spatial "getting closer to a destination" metaphor is a fresh, screen-legible mental model with the same shrinking-signal property research validates for the disc. | HIGH | Already in scope. Genuinely novel within the surveyed competitor set — flag as a phase needing careful visual/motion QA since it's the least-precedented of the four themes. |

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem good for this category but create problems, or that PROJECT.md already correctly excludes — validated against research so the exclusions can be defended with evidence, not just intuition.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|------------------|-------------|
| Gamified reward/end-state (e.g., an egg hatching into an animal, points, stickers, unlockables) | Seen in real competitor apps (e.g., "Little Timer Hatch Countdown"); makes the end-of-timer moment feel like a payoff, which some parents find motivating for compliance. | Directly conflicts with Zual's explicit "calm, not celebratory" design goal — a timer that becomes an anticipated reward machine encourages kids to watch *for* the payoff rather than absorb the passage of time, and it opens the door to nagging for more timers ("run it again!"). Also expands scope (asset variety, progression state) with no bearing on Core Value. | Keep the calm settle-into-end-state behavior already speced (disc gone / full sunrise / character or car arrived) — the arrival itself is satisfying without being a "reward." |
| Chore lists / routine checklists / multi-step schedules | Common in adjacent products (Brili, Time Timer MOD Education Edition) and explicitly requested by parents wanting an all-in-one routines tool. | This is a different product category (task/schedule management) with different information architecture, state, and UI needs; bolting it onto a single-timer app doubles scope and dilutes the "one glanceable thing" simplicity that is Zual's core value. | Correctly already listed in PROJECT.md Out of Scope ("Tasks/routines and task lists") — validated by research as the right call, not a missed opportunity. |
| Accounts / cloud sync / multi-device family profiles | Requested in "family organizer" style apps so multiple caregivers/devices share settings. | Adds real backend complexity, privacy/COPPA surface area (this app is used by/for children), and account-creation friction, for a single-device parent/child use case with no stated multi-caregiver requirement. | Correctly already Out of Scope. Local "remember last used" (see Table Stakes) captures most of the convenience value without any account system. |
| Ads / in-app purchases in the free tier | Common competitor monetization; several reviewed apps gate customization (extra pictures, themes) behind ads or paywalls. | Directly undermines the "calm" positioning (ads are inherently attention-grabbing/interruptive) and PROJECT.md's stated "no revenue model for v1" business context; also a common source of the exact user complaints (clutter, forced interstitials) seen in competitor reviews. | Ship all 4 themes free and ad-free for v1, consistent with current PROJECT.md scope. |
| Configurable/uploadable custom photos or a photo library for the child's "reward" | Seen as a differentiator in some apps (upload a photo of a favorite toy that gets revealed). | Requires camera/photo-library permissions, image storage, and content moderation concerns (parents uploading arbitrary images) — disproportionate complexity and privacy surface for a wordless-shape-based product whose whole premise is that no personalization is needed for legibility. | The four built-in, professionally designed scene themes already provide variety without any user-generated content. |
| Alarm-style / celebratory / looping end sounds | Some competitor apps use an "explosion" of sound/visuals when the timer ends, framed as satisfying. | Startling sounds are explicitly counter to the target audience — visual timers are heavily used for anxiety-prone/sensory-sensitive kids (autism/ADHD), where a sudden loud/looping alarm can cause exactly the distress the tool is meant to prevent. | Already correctly excluded; the two-tone, non-looping, decaying-envelope chime already speced is the evidence-aligned choice. |
| Landscape / multi-orientation support | Nice-to-have polish requested by some users wanting to prop a tablet sideways. | Doubles layout/testing surface for all 4 themes for a v1 whose target placement (bedroom nightstand, kitchen counter, portrait phone/tablet) doesn't need it. | Already correctly Out of Scope for v1; revisit only if tablet/kitchen-mount usage data justifies it later. |

## Feature Dependencies

```
Shrinking Disc theme (color-zone logic)
    └──requires──> Shared countdown/progress state machine (setup → running → done, paused)

Night-to-Sunrise / Walking Home / Car on a Road themes
    └──requires──> Shared countdown/progress state machine
    └──shares-visual-language-with──> Shrinking Disc theme (calm palette, easing, chime)

Parent Controls overlay (hidden long-press)
    └──requires──> Shared countdown/progress state machine (needs Pause/Resume/End hooks)

Mute / sound-off toggle (recommended addition)
    └──best-placed-in──> Parent Controls overlay OR Setup screen
    └──enhances──> Completed state (chime), Running state (any theme's ambient sound if added later)

Remember last-used duration + theme (recommended promotion to MVP)
    └──requires──> Local storage (e.g. shared_preferences) — no network/accounts needed
    └──enhances──> Setup screen (pre-fills last choice instead of always defaulting to 5 min / Disc)

Gamified reward end-states ──conflicts──> Completed state's "calm, not celebratory" design goal
Chore lists / routines ──conflicts──> single-timer simplicity (Core Value)
Accounts / cloud sync ──conflicts──> "no backend, fully local" architectural decision
```

### Dependency Notes

- **All 4 themes require the shared state machine first:** the `setup → running → done` / `paused` state machine and progress-driven color-zone logic are shared infrastructure — build/verify this once, then implement the 4 visual themes against it (matches the Key Decision already logged in PROJECT.md to build all 4 themes in one phase rather than disc-first).
- **The mute toggle enhances but does not block the Completed state:** it can be added to the Parent Controls sheet without touching the chime implementation itself — recommend sequencing it alongside the Parent Controls overlay phase, not as a separate late addition.
- **"Remember last used" enhances the Setup screen** and has no dependency on anything except local storage — it's a small, independent addition that can slot into the Setup screen phase or ship as a fast-follow immediately after, without needing accounts/network (does not conflict with the "no persistence" constraint since it is local-only, single-device state).
- **Anti-features conflict with the Core Value directly:** gamification/rewards conflict with "calm, not celebratory"; chore lists conflict with "one glanceable thing"; accounts conflict with the explicit "no backend" architecture decision. Use this as the standing rationale if any of these get re-proposed later.

## MVP Definition

### Launch With (v1)

Minimum viable product — matches PROJECT.md's Active requirements, with two research-backed additions.

- [ ] Setup screen (duration presets + custom stepper, 4-theme picker, Start button) — core flow, no credible competitor ships without an equivalent
- [ ] Running screen for all 4 themes (Disc, Sunrise, Walking Home, Car) — the wordless, number-free visual is the entire value proposition
- [ ] Shared countdown/progress state machine driving all themes — required infrastructure
- [ ] Completed state with calm two-tone chime and "All done" return affordance — validated as the correct (non-alarming) pattern for this audience
- [ ] Parent Controls overlay via hidden 850ms long-press (Pause/Resume, End timer, Keep watching) — validated as a genuine differentiator and required for the "nothing tappable by child" guarantee
- [ ] **Sound on/off (mute) control** — why essential: explicitly named in the design doc's behavior spec (`soundOn`) but missing a UI location; top-cited competitor complaint is unmuteable/uncontrollable sound; low complexity, should not be deferred
- [ ] **Remember last-used duration + theme locally** — why essential: low complexity (local storage only, no architecture conflict), directly reduces the repeat-use friction that is a real competitor pain point, and was already anticipated as a "nicety" in the design doc — worth doing now rather than as a fast-follow

### Add After Validation (v1.x)

Features to add once the core v1 is shipped and being used.

- [ ] Chime/ambient volume slider (beyond simple on/off) — trigger: if real usage shows parents wanting the chime softer rather than fully muted (bedroom use case)
- [ ] Explicit colorblind-safe secondary cue audit for the Shrinking Disc's green→yellow→red zones — trigger: before any accessibility-focused marketing push; size-based shrinking already provides a non-color-dependent primary signal, so this is a lower-urgency polish item, not a launch blocker
- [ ] Additional scene themes beyond the initial 4 — trigger: once usage data shows which of the 4 existing themes is most/least used, to inform what a 5th theme should be

### Future Consideration (v2+)

Features to defer until product-market fit (i.e., "does a Play Store audience beyond personal/family use want this") is established.

- [ ] iOS and Web platform support — already flagged in PROJECT.md as a possible future milestone, not a v1 concern
- [ ] Landscape orientation — defer until real tablet/counter-mount usage patterns are observed
- [ ] Any routines/schedule layer — only revisit if strong, repeated user demand emerges, and even then treat as a distinct product surface, not a bolt-on

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|----------------------|----------|
| Shrinking Disc theme | HIGH | MEDIUM | P1 |
| Shared state machine (setup/running/done/paused) | HIGH | MEDIUM | P1 |
| Sunrise / Walking Home / Car themes | HIGH | HIGH | P1 |
| Completed state + calm chime | HIGH | LOW | P1 |
| Parent Controls (hidden long-press) | HIGH | MEDIUM | P1 |
| Sound on/off control | MEDIUM | LOW | P1 (add to current scope) |
| Remember last-used duration + theme | MEDIUM | LOW | P1 (promote from "optional") |
| Chime volume slider | LOW | LOW | P2 |
| Colorblind-safe secondary-cue audit | LOW | LOW | P2 |
| Additional scene themes | MEDIUM | HIGH | P3 |
| iOS / Web support | MEDIUM | HIGH | P3 |
| Gamified rewards / chore lists / accounts / ads | N/A (anti-feature) | N/A | Excluded |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

## Competitor Feature Analysis

| Feature | Time Timer (app + physical) | Generic "Visual Countdown Timer" apps | Little Timer / gamified competitors | Zual's Approach |
|---------|------------------------------|----------------------------------------|--------------------------------------|-----------------|
| Core visual | Single red disk shrinks over up to 60 min | Shrinking bar or wedge, sometimes reveals a picture | Shrinking shape + "hatching egg"/reward reveal at end | Choice of 4 wordless scene metaphors (disc + 3 narrative themes), all sharing the same shrinking/progress logic |
| End sound | Simple beep/chime | Reported as often too loud, no easy volume control; some "explode" sound+visual at zero | Reward-oriented sound (celebratory) | Deliberately calm two-tone decaying chime, no alarm, no celebration |
| Sound control | Basic on device volume | Frequently cited as a pain point (no in-app control) | Usually present since app is customization-heavy | **Gap identified** — recommend explicit mute toggle in Parent Controls |
| Child-proofing | Physical dial is inherently hands-off in classrooms; app versions vary | Usually a visible on-screen settings/reset icon reachable by the child | Usually kid-facing with visible tap targets by design (interactive reward) | Hidden 850ms long-press gate — nothing tappable by the child at all |
| Customization/reward system | None (physical simplicity is the point); MOD Education Edition adds colored covers, sold separately | Some allow custom photos (paid tier) | Central feature — hatching animals, points, unlockables | None — deliberately excluded as anti-feature, replaced by curated built-in scene variety |
| Settings persistence | N/A / device-level | Varies by app | Typically yes, tied to child profiles | Recommended: remember last-used duration + theme locally, no profiles/accounts |
| Monetization | Physical product sale; app has free tier | Often ad-supported free tier, paywalled customization | Often ad-supported or freemium | Free, ad-free, no IAP (per PROJECT.md business context) |

## Sources

- [Teaching Kids Responsible Tech Use with Timers | Time Timer](https://www.timetimer.com/blogs/news/beyond-screen-time-limits-teaching-kids-responsible-tech-use-with-timers) — MEDIUM confidence (vendor content, cross-checked against independent reviews)
- [Best Visual Timers For Kids: Apps, Physical Timers, And Classroom Strategies](https://adayinourshoes.com/10-free-visual-timers-for-kids-and-autism/) — MEDIUM confidence
- [Time Timer MOD® | Countdown Timer For Kids](https://www.timetimer.com/pages/time-timer-mod) — MEDIUM confidence (vendor)
- [Visual Countdown Timer - App Store](https://apps.apple.com/us/app/visual-countdown-timer/id541364004) — MEDIUM confidence (app listing + aggregated review commentary)
- [Comparative Guide: 7 Best Visual Timers for Your Child - Forbrain](https://www.forbrain.com/adhd-learning/visual-timers-for-adhd/) — MEDIUM confidence
- [6 Best Kids Timer Apps in 2025 - AirDroid](https://www.airdroid.com/parent-control/kids-timer-app/) — MEDIUM confidence
- [Best Kids Timer Apps for Routines, Chores, and Screen Time (2026) - NexSpy](https://nexspy.com/blog/best-kids-timer-apps-2026) — MEDIUM confidence
- [How to make your App colorblind friendly - Medium/AppSoGreat](https://medium.com/@appsogreat/how-to-make-your-app-colorblind-friendly-resources-and-experience-sharing-b46615c5a007) — MEDIUM confidence
- [The Role of Visual Timers in Managing Transitions in ABA Therapy - Magnet ABA](https://www.magnetaba.com/blog/the-role-of-visual-timers-in-managing-transitions-in-aba-therapy) — MEDIUM confidence (practitioner-authored, cites broader special-ed literature)
- [Visual Timers for Autism: All You Need to Know - Autism Parenting Magazine](https://www.autismparentingmagazine.com/visual-timer-benefits/) — MEDIUM confidence
- [Transition Time: Helping Individuals on the Autism Spectrum - Indiana Resource Center for Autism](https://iidc.indiana.edu/irca/articles/transition-time-helping-individuals-on-the-autism-spectrum-move-successfully-from-one-activity-to-another.html) — MEDIUM confidence (academic-affiliated resource center)
- Internal: `.planning/PROJECT.md`, `design/README.md` (Zual's own spec, used as the baseline to compare against)

---
*Feature research for: Visual/wordless kids countdown timer apps*
*Researched: 2026-07-06*
