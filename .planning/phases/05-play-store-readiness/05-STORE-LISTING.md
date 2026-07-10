# Play Console Listing Answer Sheet — Zual

**Status: PREPARED DRAFT — NOT A SUBMITTED DECLARATION.**

> **RE-VERIFY AT SUBMISSION.** Play Console's questionnaire wording, the exact
> content-rating/target-audience flow, and Families Policy scope all drift over time
> (see `.planning/STATE.md` Blockers/Concerns and `05-RESEARCH.md` Pitfall 5). Before
> clicking submit in Play Console, the human must re-read each live question and confirm
> the answers below still match — do not paste these blindly without checking the
> current wording on screen.

This document is the copy-paste-ready source for everything the "Store listing" and
"Target audience and content" sections of Play Console ask for. It does not submit
anything on its own.

---

## 1. App display name

```
Zual — Visual Timer for Kids
```

(D-06, locked exactly as written above.)

---

## 2. Target audience declaration

**Answer: General audience that also appeals to children.**
**NOT** the "Designed for Families" program/track.

**Rationale (D-07):** Zual is parent-operated — a parent sets the duration and picks a
scene, and the child only watches the resulting visual with nothing tappable on the
running screen. The app has zero ads, zero accounts, and collects zero data. Because of
this, the lighter "general audience that also appeals to children" review track is the
correct declaration rather than the stricter COPPA-style "Designed for Families"
program, which imposes additional restrictions not warranted by an app with no data
collection, no ads, and no in-app purchases in the first place.

A privacy policy is still required for this declaration (Families Policy + general Play
Store requirement) — see the URL in section 4 below.

---

## 3. Content rating (IARC) questionnaire — target Everyone / lowest tier

Below are the intended answers to the common IARC content-rating questions, aiming for
the lowest tier (Everyone / ESRB Everyone / PEGI 3 equivalent). Actual question wording
in Play Console may vary; treat these as the intended answer per topic, not verbatim
quoted questions.

| Topic | Answer |
|---|---|
| Violence | None |
| Sexual content / nudity | None |
| Profanity or crude humor | None |
| Text or user-generated content | None — the app displays no text and accepts no user input beyond a parent's setup choices |
| User-generated content / user interaction with other users | None — no multiplayer, no chat, no sharing |
| Ads | None — the app contains no advertising |
| In-app purchases | None — no purchases, no monetization |
| Location sharing | None — the app requests and shares no location data |
| Personal data collection / sharing | None — no data of any kind is collected, stored remotely, or shared |
| Controlled substances (drugs, alcohol, tobacco references) | None |
| Gambling / simulated gambling | None |
| Interactive elements beyond passive viewing | None on the running screen — child does not interact; only the parent interacts, on the setup screen |

**Expected outcome:** Everyone / ESRB Everyone / PEGI 3 (or the closest regional
equivalent) across all rating boards.

---

## 4. Privacy policy URL

```
https://reiteristvan.github.io/zual/
```

Served from `docs/index.html` on `main` via GitHub Pages (D-10). Must be enabled and
confirmed live (returns HTTP 200, correct content) before or during Play Console
submission — see this plan's Task 3 checkpoint.

---

## 5. Store description

### Short description (<=80 characters, D-14 parent-practical tone)

```
A wordless visual timer that helps young kids see how much longer they wait.
```

(76 characters.)

### Full description (parent-practical, matches PROJECT.md Core Value)

```
Zual is a visual countdown timer built for children who don't yet understand
minutes and hours.

Set a duration and pick a scene, and your child watches a full-screen,
wordless visual that makes the time remaining easy to read from across the
room — no numbers, no clock, nothing to tap. When time is up, a soft chime
plays and the scene settles into a calm, finished state.

Choose from four calm visual scenes: a shrinking disc that changes color as
time passes, a sky that shifts from night to sunrise, a character walking
home, or a car driving toward its destination.

Zual is not a productivity app or a task list — it's a simple, calm way to
help a young child understand "how much longer" without needing to read a
clock. It works fully offline, has no accounts, no ads, and collects no
data.
```

---

## Internal consistency check

- Target audience (section 2) says "general audience that also appeals to children,"
  explicitly not "Designed for Families" — consistent with D-07.
- Content-rating answers (section 3) all point to the lowest/Everyone tier — consistent
  with D-08, and consistent with the "no ads / no accounts / no data" rationale used in
  section 2.
- Privacy policy URL (section 4) matches the GitHub Pages URL committed in this plan's
  Task 1/Task 3 (D-09, D-10).
- Description tone (section 5) is short, parent-practical, and leads with the concrete
  problem solved, per D-14 and PROJECT.md's Core Value statement — no numbers or clock
  framing appears anywhere in either description.

---

*Prepared: 2026-07-10 as part of Phase 5 (Play Store Readiness), Plan 03.*
*This is a draft answer sheet for human use at Play Console submission time — it is not
itself a submission and must be re-verified against the live questionnaire before use.*
