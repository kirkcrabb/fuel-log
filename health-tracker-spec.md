# Fuel Log — Spec & Changelog

A personal food, exercise, and weight tracker that runs as a private Claude artifact.
This document is the living spec: it is updated every time a change is requested,
and the changelog at the bottom records each revision.

**Live app:** https://claude.ai/code/artifact/de2ff8ee-e117-4021-8a5a-c18b9e7edd9d

---

## How it works (v2 architecture)

Logging happens **in chat with Claude**, not in the page:

1. Kirk tells Claude what he ate ("had a turkey sandwich and an apple"), pastes a
   **photo of a meal**, or reports a workout or weigh-in.
2. Claude estimates **calories, protein, and carbs** for each food item (and optional
   calories burned for exercise).
3. Claude updates the data block inside the app's HTML and republishes the artifact.
   The page is a read-only dashboard of Claude-maintained data.

Source of truth lives on Kirk's machine at `C:\Users\kcrabb\Documents\daybook-health\health-tracker.html`
(the `const DATA = {...}` block near the top of the script). No localStorage, no network calls.

## What's tracked

| Metric | How it's logged | Fields |
|--------|----------------|--------|
| Food | Described in chat or via meal photo | item, meal (optional), calories, protein g, carbs g |
| Exercise | Reported in chat | name, minutes (optional), estimated calories (optional) |
| Weight | Reported in chat | one value per day, lbs |

## Dashboard sections

- **Latest day** — stat tiles for calories, protein, carbs, and weight for the most
  recent logged day.
- **Next meal** — remaining calorie/protein/carb budget for the day (computed against
  `DATA.targets`, currently 2,100 cal / 150 g protein / max 40 g carbs) plus
  Claude-curated picks along Kirk's Pleasant Grove → Provo commute, split into two
  labeled groups, **Meal** and **Snack**, three picks each, each with a specific order,
  estimated macros, and a note. Claude refreshes the picks when logging meals. On BYU
  nights (Tue/Wed/Thu, dispatch shift until 1am) the snack picks are packable
  shift-snack options.
- **Goal & pace** — `DATA.goalWeight` (220 lbs) renders under the weight chart as
  "N lbs to goal · pace X lbs/wk · on track for <month>" once a week of weigh-ins exists.
- **Weight progress** — dedicated line chart with **7d / 30d / 1y** range toggles,
  current weight, and change over the selected window (green when down, amber when up).
- **Food log** — itemized table for the latest day with a totals row.
- **Exercise** — the latest day's workouts with duration and estimated burn.
- **Last 14 days** — bar charts for calories (green), protein (blue), carbs (amber),
  each with a running average.
- **History** — one row per logged day (up to 30), most recent first, with daily
  totals, weight, and exercise summary.
- **How to log** — an in-page reminder of the chat workflow.

## Data model

Inside the HTML, between the `===== DATA =====` marker comments:

```js
const DATA = {
  updated: "2026-07-14",      // date of last update
  weightUnit: "lbs",
  days: {
    "2026-07-14": {
      weight: 178.4,
      exercise: [ { name: "Morning run", minutes: 30, cal: 320 } ],
      food: [
        { item: "Scrambled eggs, 2 slices toast", meal: "breakfast",
          cal: 420, protein: 22, carbs: 34 }
      ]
    }
  }
};
```

- Date keys are local-time `YYYY-MM-DD`.
- Daily calorie/protein/carb totals are computed from food items at render time.
- Macro numbers are Claude's estimates — close, not lab-grade (noted in the page footer).

## Update procedure (for Claude)

**On Kirk's PC (normal case):**
1. First, reconcile: WebFetch the live app artifact (URL above) and compare its `DATA`
   block against the local file — a phone/cloud session may have logged entries the
   local file doesn't have. Merge the newer entries into
   `C:\Users\kcrabb\Documents\daybook-health\health-tracker.html`.
2. Edit only the `DATA` block — set `updated` to today, add/merge the day's entries.
3. Republish the artifact (URL above) via the `url` parameter.
4. For feature changes (not data logging): also update this spec, bump the changelog,
   and republish it (spec artifact: https://claude.ai/code/artifact/db2a2f5b-7e27-44db-8bf3-723e32fca327).
5. Keep the app HTML ASCII-only (HTML entities / `\u` escapes for special characters).

**From a cloud session (Kirk logging from his phone, PC possibly off):**
1. Kirk reports food, exercise, or a weigh-in. Estimate calories/protein/carbs per item
   (macro estimates, clearly stated).
2. WebFetch the live app artifact (URL above) to get the current page HTML — the
   artifact is the source of truth in this mode.
3. Save the HTML to a local file, merge the new entries into the `DATA` block only
   (shape documented above; set `updated` to today), change nothing else.
4. Republish with the Artifact tool passing `url:` the app artifact URL.
5. Do not touch targets, picks, or layout unless Kirk asks. The next PC session will
   reconcile automatically (see above).

---

## Changelog

### v2.11 — 2026-07-16
- **Next-meal picks split into Meal and Snack groups**, three picks each, at Kirk's
  request. `DATA.nextMeal.picks` (one flat array) replaced with `DATA.nextMeal.meals`
  and `DATA.nextMeal.snacks` (each an array of 3 `{place, order, cal, protein, carbs,
  note}` picks). The two groups render as separate labeled lists under one shared
  remaining-budget line; each pick still has its own "I ate this" button.
- Snack picks now offer three packable shift-snack sizes (jerky + shake combo, shake
  alone, jerky alone) instead of one fixed combo.

### v2.10 — 2026-07-16
- **Migrated to Kirk's personal Claude account.** New artifacts published (URLs above);
  the doTERRA work-account copies are deprecated. Source lives in the private GitHub
  repo `kirkcrabb/fuel-log`; the live app artifact is the source of truth for data.
- Cloud-session workflow codified in CLAUDE.md: routine logging republishes the
  artifact only (no git); feature changes go through a branch + PR (or hand the diff
  to Kirk when the GitHub app lacks write access).

### v2.9.1 — 2026-07-15
- Swapped line emphasis at Kirk's request: **raw weigh-ins are the bold line + dots**,
  the EMA trend is the faint smoothed line behind them. Pace/ETA still trend-based.

### v2.9 — 2026-07-15
- **Weight trend line**: exponential moving average (alpha 0.1, ~10-day) drawn as the
  bold line; raw daily weigh-ins de-emphasized to faint dots + thin line. The endpoint
  dot rides the trend.
- **Pace/ETA now computed from the trend slope** (stable against single weird scale
  days); "lbs to goal" still uses the latest raw weigh-in. No dashed goal projection
  (offered, not requested).
- Verified against 21 days of synthetic noisy data.

### v2.8 — 2026-07-15
- **Weight chart axis markers**: horizontal gridlines with pound labels (left edge,
  auto-stepped 0.5–50 lbs to the range) and date labels along the bottom (daily for 7d,
  4 spread ticks for 30d, month names for 1y).
- **"How to log" card removed from the page** (Kirk uses it personally and won't share
  it). The logging workflow remains documented here: log in Claude chat (text or meal
  photo, or an "I ate this" click + paste); Claude estimates macros and republishes;
  reload the page to see the latest.

### v2.7 — 2026-07-15
- **Goal weight & pace readout**: `goalWeight: 220` renders "69.9 lbs to goal (220)"
  under the weight chart; pace and ETA appear after a week of weigh-ins.
- **Carb cap lowered 100 → 40 g/day** at Kirk's request.
- **Bike calories recalibrated**: Kirk rides ~3:30/mile with standing intervals —
  vigorous, ~550 cal per 30 min at his weight (was 450). Both logged days updated.
- **Shift-snack pick**: Tue/Wed/Thu dispatch shifts run until 1am; dinner picks now
  include a packable snack (jerky + almonds).
- Aubergine & Company removed from all rotations (Kirk dislikes it).

### v2.6 — 2026-07-15
- **"I ate this" buttons on next-meal picks.** Clicking adds the meal to today as a
  **pending** entry (stored in that browser's localStorage, shown tagged in the food log,
  counted in totals and the remaining budget) and copies a ready-made log message to the
  clipboard for pasting to Claude.
- Pending entries auto-clear when the master DATA contains a matching item for that date
  (same item text, or same cal/protein/carbs), or after 7 days.
- **For Claude:** when Kirk says he ate a suggested pick, log the food item with the
  pick's `order` string as the item text (or identical macros) so the pending copy clears.

### v2.5 — 2026-07-14
- **Phone logging supported via cloud sessions.** The update procedure now has a
  cloud-session variant (WebFetch the artifact → merge into DATA → republish via `url`),
  and PC sessions reconcile against the live artifact before editing, so entries logged
  from Kirk's phone are never lost.

### v2.4 — 2026-07-14
- Kirk wants low-carb: added a **daily carb cap** to targets (default 100 g — adjust on
  request). Targets are now `{cal: 2100, protein: 150, carbs: 100}`.
- The Next-meal budget line now shows remaining carb room alongside calories and protein.
- Next-meal picks must respect the carb cap (e.g. bunless/grain-free orders).

### v2.3 — 2026-07-14
- Renamed the app from **Daybook Health** to **Fuel Log** (Kirk's pick).
  Files stay at `C:\Users\kcrabb\Documents\daybook-health\` and artifact URLs are unchanged.

### v2.2 — 2026-07-14
- Added **Next meal** section: shows remaining calories/protein vs daily targets
  (default 2,100 cal / 150 g protein — adjustable on request) and restaurant
  recommendations with specific orders and macro estimates.
- Recommendations are tailored to no-cook, restaurant-only eating along the
  Pleasant Grove (doTERRA) → Provo (BYU) corridor: Chick-fil-A, Cafe Rio,
  Aubergine & Company, Mo' Bettahs, etc.
- New DATA fields: `targets: {cal, protein}` and
  `nextMeal: {context, picks:[{place, order, cal, protein, carbs, note}]}`.

### v2.1 — 2026-07-14
- Added a dedicated **Weight progress** chart with 7-day / 30-day / 1-year range
  toggles, showing current weight and the change over the selected window
  (green = down, amber = up).
- Removed the small weight chart from the 14-day grid (superseded by the new section).
- Exercise calorie estimates now account for body weight (first weigh-in: 291 lbs).

### v2.0 — 2026-07-14
- **Redesigned around chat logging.** Tracks only exercise, weight, and food.
  Kirk reports meals (text or photo), workouts, and weigh-ins in chat; Claude
  estimates calories/protein/carbs and updates the page.
- Removed water, steps, sleep, mood, daily goals, streak, in-page inputs, and
  localStorage — the page is now a read-only dashboard of Claude-maintained data
  embedded in the HTML.
- New sections: latest-day macro stat tiles, itemized food log with totals,
  exercise list, calories/protein/carbs/weight 14-day charts, 30-day history table.
- Data source of truth moved to `C:\Users\kcrabb\Documents\daybook-health\` so it
  survives across sessions.

### v1.1 — 2026-07-14
- Replaced all non-ASCII characters (em/en dashes, stepper glyphs) with HTML entities
  and `\u` escapes so the app renders correctly regardless of charset headers.
- Verified end-to-end in a browser: logging, day navigation, goal chips, streak,
  charts, and persistence — no console errors.

### v1.0 — 2026-07-14
- Initial release: water / steps / sleep / weight / mood / notes logging,
  daily goals with hit indicators, 14-day trend charts, streak counter,
  JSON export, clear-all, light + dark themes.
