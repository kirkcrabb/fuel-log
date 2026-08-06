# Fuel Log — Claude Instructions

<!-- This file governs how Claude maintains Fuel Log; see the Environment & workflow section below for the logging vs. feature-change split. -->
You are maintaining **Fuel Log**, Kirk's personal food / exercise / weight tracker.
Kirk reports meals (text or photos), workouts, and weigh-ins in chat; you estimate
calories, protein, and carbs, update the data, and republish the dashboard artifact.

## Environment & workflow

Sessions normally run as **claude.ai/code cloud sessions on Kirk's personal account
with this repo selected** (often from his phone).

**At session start, read `health-tracker.html`'s `DATA` block straight from this
repo — that's the reliable source of current data.** Do NOT rely on WebFetching the
live app artifact to reconcile: a session that didn't publish a given private
artifact cannot read it back (confirmed 2026-08-05, not a one-off glitch), so a new
session trying to "fetch the artifact first" gets nothing and silently works from
stale/missing data. Git is up to date because every publish also gets committed
straight to this branch (see step 6 below) - no separate reconciliation step needed.

- **Routine logging** (meals, workouts, weigh-ins): merge into DATA, republish the app
  artifact via the `url` parameter, AND commit `health-tracker.html` directly to this
  branch (no PR, no merge needed - see Logging procedure step 6). The commit is what
  makes the data recoverable by the next session; the artifact is just the live
  dashboard Kirk looks at.
- **Feature changes** (new sections, behavior, targets structure) or an explicit
  "back up to git" request: also update the spec changelog and open a PR for Kirk to
  merge. If git write is unavailable (403), say so and give Kirk the full changed
  files so he can apply them from his PC, which has push access.

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

ALWAYS republish to these URLs via the Artifact tool's `url` parameter, and try
**`force: true`** first on any republish that fails (see note below):

- App 🌿 (SOURCE OF TRUTH, migrated 2026-08-05): https://claude.ai/code/artifact/e83a6198-f289-41da-849e-0369720c16f8
- Spec 📋 (migrated 2026-08-05): https://claude.ai/code/artifact/e2197981-3b7b-4b0a-adbb-db03d1f5a8b7
- Old/broken URLs (do not use - permanently stuck, unfixable even with
  `force: true`, confirmed via A/B testing with byte-identical content that
  publishes fine elsewhere):
  - de2ff8ee-e117-4021-8a5a-c18b9e7edd9d (original app, broken as of 2026-08-04)
  - 6016fa31-707b-42fa-aa9b-cf403ef39ed7 (app, broken within hours of going live)
  - db2a2f5b-7e27-44db-8bf3-723e32fca327 (spec, stable most of the session, broke
    2026-08-05)
  - Old work-account copies (deprecated 2026-07-16): app
    90920e4c-d0a6-4309-8cad-d868b7860463, spec 43da555f-6a93-41c1-9a30-edc9a77ff019

**On `force: true`:** a routine republish to a healthy artifact URL intermittently
fails with "could not verify the target page is not a review page (transient read
failure: artifact content fetch failed (HTTP 403))." This is a pre-publish safety
check re-fetching the artifact's current content before allowing an overwrite - that
internal fetch, not the publish itself, is what's flaking. `force: true` skips the
check and often succeeds where a plain republish won't - try it first. It is NOT a
guaranteed fix, though (confirmed 2026-08-05: it failed 3/3 tries against a URL that
had been stable all session). Confirmed safe to use here regardless: single-user
session, no risk of clobbering a concurrent edit. If `force: true` also fails after
2-3 tries, publish fresh (omit `url` entirely) to get a working link immediately,
then migrate: update this section and the spec's "Live app" line, republish the
spec to itself, and note the dead URL above. Don't burn more than a few retries
chasing one URL - minting fresh is instant and always works.

## Logging procedure (every time Kirk reports something)

1. Merge into `DATA.days["YYYY-MM-DD"]`:
   `{weight, exercise:[{name,minutes,cal}], food:[{item,meal,cal,protein,carbs}]}`
2. Estimate macros for described meals; **nutrition-label or restaurant-published
   numbers beat estimates; Kirk's Apple Watch calories beat MET estimates**
   (his 30-min stationary bike ≈ 280 active cal per the watch).
3. Set `DATA.updated` to today. Refresh `DATA.nextMeal` picks for his remaining budget.
   **`DATA.nextMeal.meals` should always have picks in it — never leave it empty.**
   Cycle breakfast → lunch → dinner → next day's breakfast based on which meal types
   are already logged for the current day; once dinner is logged, "next meal" means
   tomorrow's breakfast. Pick the restaurant/at-home options per that day's schedule
   pattern (see Schedule below) — e.g. a logged dinner on a Tue/Wed/Thu rolls over to
   a Mon/Fri-style at-home breakfast if the next day is Mon/Fri. `DATA.nextMeal.snacks`
   stays populated only when relevant (e.g. the Tue/Wed/Thu dispatch shift); otherwise
   leave it empty and the snack group just won't render. **Actually rotate the picks
   each time — check what the last few days' meals/snacks were and reach for
   different options, don't reuse the same 3 as a template.**
4. Republish the app artifact (same URL, `force: true` - see Artifacts section).
   Keep the HTML **ASCII-only** — use HTML entities / \u escapes for any special
   characters. Verify with `node --check` on the extracted `<script>` before
   publishing (a syntax error here breaks the live page).
5. If Kirk says he ate a suggested pick, log the item using the pick's `order` string
   verbatim (or identical macros) so the page's pending-entry dedup clears.
6. **Commit `health-tracker.html` straight to this branch and push - no PR, no
   merge, don't ask.** This is what makes the data recoverable by the next session
   (see Environment & workflow above); it is not the "back up to git" feature-change
   path and Kirk never needs to act on it. If a git conflict/rejection happens
   because of an earlier bad push, merge favoring the correct content and push
   normally rather than force-pushing (force-push needs Kirk's explicit OK).

## Kirk's profile (as of 2026-07-16)

- Weight: 288.8 lbs (started 291.0 on 2026-07-14); **goal 220** (`DATA.goalWeight`)
- Targets: **2,100 cal / 150 g protein minimum / 40 g carbs maximum** per day
- Can't cook; eats at restaurants and grab-and-go. Grocery trips are hard to fit in.
- Estimates-are-fine default: he corrects portions when they're off; trust his labels.

## Schedule (drives meal recommendations)

- **Tue / Wed / Thu:** ~9am home (east Pleasant Grove, UT) → doTERRA office (west PG
  at I-15). Breakfast leg stops: Maverik (State St), Chick-fil-A (Valley Grove at
  PG Blvd/I-15), Macey's (State St). Lunch: doTERRA cafeteria salad bar (double
  chicken, oil & vinegar; skip peas/pickled-beet scoops) — or, since he's said he
  gets tired of salad, a change-of-pace lunch pick (Wingstop dry-rub wings, Chipotle,
  Chicken Salad Chick on greens) is equally valid; don't default to the cafeteria
  every time. ~4pm → BYU 2120 JKB (Provo) via I-15/University Pkwy: Chick-fil-A
  (Orem + Cougareat on campus), Cafe Rio, Costa Vida, Mo' Bettahs, Cubby's.
  **Rotate through this full dinner list — don't default to the same 2-3 every time;
  reach for whichever ones haven't come up recently.** **Dispatch shift until 1am —
  he cannot leave, so always include a packable shift snack with dinner picks; rotate
  the snack too, don't default to the same one.** Snack options: Tillamook Zero Sugar
  jerky (2.2 oz pkg = 140 cal / 28 P / 0 C), Core Power Elite shake (230 cal / 42 P /
  9 C), jerky + shake combo (370 cal / 70 P / 10 C), Pro2Go Protein Pack (hard-boiled
  egg + Genoa salami + pepper jack stick, 260 cal / 18 P / 0 C), string cheese,
  turkey + pepper jack roll-ups, plain hard-boiled eggs.
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
