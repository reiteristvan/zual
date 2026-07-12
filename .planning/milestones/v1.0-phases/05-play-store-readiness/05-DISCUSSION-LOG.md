# Phase 5: Play Store Readiness - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-07-09
**Phase:** 5-Play Store Readiness
**Areas discussed:** App icon & visual identity, App identity — package ID & display name, Target audience & content rating declaration, Store listing assets — screenshots & description

---

## App icon & visual identity

| Option | Description | Selected |
|--------|-------------|----------|
| Shrinking Disc motif | Reuses the simplest scene, echoes core visual language | |
| Abstract time mark | New non-numeric shape, invented fresh for the icon | |
| One of the other 3 scenes | Night to Sunrise, Walking Home, or Car on a Road | ✓ |

**Follow-up — which scene:**

| Option | Description | Selected |
|--------|-------------|----------|
| Night to Sunrise | Sky gradient night→day, strong "time passing" read even small | ✓ |
| Walking Home | Character on a path; small figure may lose detail at launcher size | |
| Car on a Road | Similar tradeoff to Walking Home | |

**Background:**

| Option | Description | Selected |
|--------|-------------|----------|
| Warm cream/sand solid | Matches app's flat UI background token | |
| Scene-matched gradient | Pulled from the chosen scene's own palette | ✓ |
| Other | — | |

**Foreground style:**

| Option | Description | Selected |
|--------|-------------|----------|
| Big and simple (recommended) | One dominant shape, survives masking/small size | ✓ |
| Closer to in-app detail | More faithful, riskier at small sizes | |

**Asset source:**

| Option | Description | Selected |
|--------|-------------|----------|
| Claude generates in Flutter/Dart (recommended) | Reuses existing CustomPainter scene code | ✓ |
| User provides finished icon file | Hand-off of a designed asset | |

**User's choice:** Night to Sunrise motif, scene-matched gradient background, big/simple adaptive foreground, Claude-generated via Dart.
**Notes:** None.

---

## App identity — package ID & display name

| Option | Description | Selected |
|--------|-------------|----------|
| I own a domain — use it | Derive applicationId from an owned domain | |
| No domain — use a personal/dev namespace | e.g. com.reiteristvan.zual | (initially, then overridden) |
| Other | Specify exact applicationId | ✓ (free text) |

**Confirmation round:** Proposed `com.reiteristvan.zual` (derived from git identity) was declined; user provided `com.ireiter.zual` directly via plain text.

**Display name:**

| Option | Description | Selected |
|--------|-------------|----------|
| Zual | No rebrand | |
| Zual — [tagline] | Zual plus a short descriptive suffix | ✓ |
| Other | Different name entirely | |

**Tagline follow-up:**

| Option | Description | Selected |
|--------|-------------|----------|
| Visual Timer for Kids | Plain, descriptive, matches PROJECT.md framing | ✓ |
| Calm Countdown Timer | Leans into calm/non-alarm positioning | |
| Other | Custom tagline | |

**User's choice:** `applicationId = com.ireiter.zual`; display name = "Zual — Visual Timer for Kids".
**Notes:** User declined the git-identity-derived namespace suggestion in favor of their own chosen domain-style ID.

---

## Target audience & content rating declaration

| Option | Description | Selected |
|--------|-------------|----------|
| Primarily for children (Designed for Families) | Strictest review track, matches actual usage | |
| General audience, also appeals to children | Lighter review track, common for parent-operated tools | ✓ |
| Other | Different framing | |

**Privacy policy provision:**

| Option | Description | Selected |
|--------|-------------|----------|
| Simple static page Claude drafts | Short no-data-collection policy text | ✓ |
| I'll write/host it myself | User provides their own | |
| Other | Different approach | |

**Privacy policy hosting:**

| Option | Description | Selected |
|--------|-------------|----------|
| GitHub Pages from this repo | Free, no new accounts | ✓ |
| I'll host it myself elsewhere | User's own hosting | |
| Other | Different hosting | |

**Content rating:**

| Option | Description | Selected |
|--------|-------------|----------|
| Everyone / lowest rating (recommended) | No violence/text/UGC/ads | ✓ |
| I'll fill out the questionnaire myself | User completes it directly at submission | |

**User's choice:** General audience (not Designed for Families); Claude drafts a short privacy policy hosted on GitHub Pages; aim for Everyone/lowest content rating.
**Notes:** STATE.md's existing blocker note (Families Policy wording must be re-verified at actual submission time) still applies — these are best-effort decisions now, not a guarantee of Play Console's exact wording at submission.

---

## Store listing assets — screenshots & description

| Option | Description | Selected |
|--------|-------------|----------|
| All 4 scenes, one each | Full visual variety | ✓ |
| Night to Sunrise + Setup screen only | Curated, fewer shots | |
| Other | Different selection | |

**Description tone:**

| Option | Description | Selected |
|--------|-------------|----------|
| Short & parent-practical (recommended) | Leads with the practical problem solved | ✓ |
| Warm/storytelling | More narrative | |
| Other | Different tone | |

**Screenshot capture method:**

| Option | Description | Selected |
|--------|-------------|----------|
| Real device/emulator captures (recommended) | Actual app screenshots | ✓ |
| Staged/mocked captures | Screenshot-harness screen | |

**Screenshot framing:**

| Option | Description | Selected |
|--------|-------------|----------|
| Plain full-bleed captures (recommended) | No bezel, no text overlay | ✓ |
| Add a short caption per screenshot | Text banner per shot | |

**User's choice:** All 4 scenes, one screenshot each, captured live from a real device/emulator, plain full-bleed with no frame or caption; short parent-practical description tone.
**Notes:** None.

---

## Claude's Discretion

- Exact PNG export sizes and adaptive-icon XML wiring (`mipmap-anydpi-v26`, foreground/background layer split).
- Exact progress point captured per scene for screenshots.
- Exact wording of the short/full store description beyond the "parent-practical" tone lock.
- Production keystore generation/storage mechanics (standard Flutter/Android release-signing practice).
- Play App Signing (Google-managed) vs. locally-held upload key — follows Google's recommended default.
- `pubspec.yaml`'s `description:` and `version:` fields — likely need updating alongside the applicationId change.

## Deferred Ideas

None — discussion stayed within phase scope. Actual Play Console account creation and final submission click-through are left to the human at execution time.
