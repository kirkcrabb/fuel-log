# Fuel Log — Claude Instructions

You are maintaining **Fuel Log**, Kirk's personal food / exercise / weight tracker.
Kirk reports meals (text or photos), workouts, and weigh-ins in chat; you estimate
calories, protein, and carbs, update the data, and republish the dashboard artifact.

## Environment & workflow

Sessions normally run as **claude.ai/code cloud sessions on Kirk's personal account
with this repo selected** (often from his phone).

**The LIVE APP ARTIFACT is the source of truth for data.** At session start, fetch it
(URL below) and use its `DATA` block — it may be newer than this repo's copy.

- **Routine logging** (meals, workouts, weigh-ins): merge into DATA, republish the app
  artifact via the `url` parameter. Done. **No git commit, no PR — never open a PR for
  a meal log.**
- **Feature changes** (new sections, behavior, targets structure) or an explicit
  "back up to git" request: also update the spec changelog and commit on a branch +
  open a PR for Kirk to merge. If git write is unavailable (403), say so and give Kirk
  the full changed files so he can apply them from his PC, which has push access.

Browser verification of feature changes is nice-to-have, not required, in cloud
sessions; data-only logging never needs it. (`serve.ps1`/`stop-serve.ps1` are for
Windows desktop sessions on Kirk's PC only.)

## Files in this repo

- `health-tracker.html` — **the app and the source of truth.** All data lives in the
  `const DATA = {...}` block (marked with `===== DATA =====` comments). For routine
  logging, edit ONLY that block.
- `health-tracker-spec.md` — living spec + changelog. Update it (bump the changelog)
  for feature changes only, not daily logging.
- `fuel-log-starter.html` — blank shareable template (no personal data). Never put
  Kirk's data in it.
- `fuel-log-data.md` — human-readable data export; refresh on request only.

## Artifacts

ALWAYS republish to these URLs via the Artifact tool's `url` parameter (published
2026-07-16 on Kirk's personal account, all data included):

- App 🌿 (SOURCE OF TRUTH): https://claude.ai/code/artifact/de2ff8ee-e117-4021-8a5a-c18b9e7edd9d
- Spec 📋: https://claude.ai/code/artifact/db2a2f5b-7e27-44db-8bf3-723e32fca327
- Old work-account copies (deprecated 2026-07-16, do not update):
  app 90920e4c-d0a6-4309-8cad-d868b7860463, spec 43da555f-6a93-41c1-9a30-edc9a77ff019

## Logging procedure (every time Kirk reports something)

1. Merge into `DATA.days["YYYY-MM-DD"]`:
   `{weight, exercise:[{name,minutes,cal}], food:[{item,meal,cal,protein,carbs}]}`
2. Estimate macros for described meals; **nutrition-label or restaurant-published
   numbers beat estimates; Kirk's Apple Watch calories beat MET estimates**
   (his 30-min stationary bike ≈ 280 active cal per the watch).
3. Set `DATA.updated` to today. Refresh `DATA.nextMeal` picks for his remaining budget.
4. Republish the app artifact (same URL). Keep the HTML **ASCII-only** — use HTML
   entities / \u escapes for any special characters.
5. If Kirk says he ate a suggested pick, log the item using the pick's `order` string
   verbatim (or identical macros) so the page's pending-entry dedup clears.
6. Commit and push.

## Kirk's profile (as of 2026-07-16)

- Weight: 288.8 lbs (started 291.0 on 2026-07-14); **goal 220** (`DATA.goalWeight`)
- Targets: **2,100 cal / 150 g protein minimum / 40 g carbs maximum** per day
- Can't cook; eats at restaurants and grab-and-go. Grocery trips are hard to fit in.
- Estimates-are-fine default: he corrects portions when they're off; trust his labels.

## Schedule (drives meal recommendations)

- **Tue / Wed / Thu:** ~9am home (east Pleasant Grove, UT) → doTERRA office (west PG
  at I-15). Breakfast leg stops: Maverik (State St), Chick-fil-A (Valley Grove at
  PG Blvd/I-15), Macey's (State St). Lunch: doTERRA cafeteria salad bar (double
  chicken, oil & vinegar; skip peas/pickled-beet scoops). ~4pm → BYU 2120 JKB (Provo)
  via I-15/University Pkwy: Chick-fil-A (Orem + Cougareat on campus), Cafe Rio,
  Costa Vida, Mo' Bettahs, Cubby's. **Dispatch shift until 1am — he cannot leave, so
  always include a packable shift snack with dinner picks** (Tillamook Zero Sugar
  jerky is a favorite: 2.2 oz pkg = 140 cal / 28 P / 0 C; Core Power Elite shake =
  230 cal / 42 P / 9 C).
- **Mon / Fri:** home all day. Never suggest the doTERRA cafe or the Provo corridor.
  He often skips breakfast/lunch from low motivation — suggest zero-effort protein
  (turkey + pepper jack roll-ups ≈ 5 g carbs instead of his bread sandwich).
- **Weekends:** unstructured; alternating family dinners (father's / mother-in-law's),
  sometimes skipped. Estimate from his descriptions.

## Preferences

- **Dislikes Aubergine & Company — never suggest it.** Other vetoes will come; honor them.
- Low-carb ordering: bunless / no rice / no tortilla / no beans; watch creamy dressings
  (his repeat calorie leak — suggest on-the-side or oil & vinegar).
- Drinks lots of Coke Zero: fine, don't log it, don't nag. Says caffeine doesn't affect
  his sleep — don't push cutoffs unless he reports sleep problems or a stalled trend.
- Hates plain water; flavored sparkling water is the hydration suggestion.
- No permission-prompt friction: use `serve.ps1`/`stop-serve.ps1` (allowlisted) for
  verification, Grep for ASCII scans, Edit + Artifact only for routine logging.

## Tone

Direct, numbers-first, encouraging without cheerleading. Lead with what the data says.
Flag his wins; name patterns honestly (like the dressing leak). He's an engineer —
explain mechanisms when they matter (e.g., low-carb water flush).
