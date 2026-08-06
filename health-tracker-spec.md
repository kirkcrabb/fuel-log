# Fuel Log — Spec & Changelog

A personal food, exercise, and weight tracker that runs as a private Claude artifact.
This document is the living spec: it is updated every time a change is requested,
and the changelog at the bottom records each revision.

**Live app:** https://claude.ai/code/artifact/2502cec8-4fd4-4e06-b1f5-7872ad867da0

---

## How it works (v2 architecture)

Logging happens **in chat with Claude**, not in the page:

1. Kirk tells Claude what he ate ("had a turkey sandwich and an apple"), pastes a
   **photo of a meal**, or reports a workout or weigh-in.
2. Claude estimates **calories, protein, and carbs** for each food item (and optional
   calories burned for exercise).
3. Claude updates the data block inside the app's HTML and republishes the artifact.
   The page is a read-only dashboard of Claude-maintained data.

Source of truth is Kirk's local copy at `C:\Users\kcrabb\Downloads\fuel-log\
health-tracker.html` (the `const DATA = {...}` block near the top of the script).
No git commits/pushes for this, ever, unless Kirk explicitly asks in the moment -
see Environment & workflow in CLAUDE.md. No localStorage, no network calls from the
page itself.

## What's tracked

| Metric | How it's logged | Fields |
|--------|----------------|--------|
| Food | Described in chat or via meal photo | item, meal (optional), calories, protein g, carbs g |
| Exercise | Reported in chat | name, minutes (optional), estimated calories (optional) |
| Weight | Reported in chat | one value per day, lbs |

## Dashboard sections

- **Latest day** — stat tiles for the most recent logged day. Calories, protein, and
  carbs render as progress tiles (consumed / target, percentage, and a fill bar) against
  `DATA.targets`; weight renders as a plain number (no daily target to progress
  toward). Color coding is direction-aware: protein is a floor (bad below 70%, warn
  70-99%, good at/above 100% — more is fine), calories and carbs are caps (good below
  the warn threshold, warn approaching target, bad at/above 100% — carbs' warn
  threshold is stricter at 75% since it's a stricter self-imposed cap; calories warns
  at 90%). The fill bar visually caps at 100% width even when the percentage exceeds
  it (e.g. carbs at 163%), so the text is the source of truth for overages.
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
- **Food log** — itemized table for the latest day with a totals row. Includes an
  **"+ Add food" form** (item, meal/notes, calories, protein g, carbs g - Kirk's own
  numbers, no Claude estimate needed) for logging without a chat round-trip; entries
  stage in `localStorage` as **unsynced** (tagged, counted in totals, kept up to 7
  days) until a **"Copy for Claude"** sync bar batches them into one message to paste
  into a Claude session, which bakes them into `DATA` and clears the tag. Distinct
  from the quick-pick "I ate this" **pending** flow (tagged, excluded from totals,
  10-min TTL) - see Data model below for both shapes.
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
- Daily calorie/protein/carb totals are computed from food items at render time,
  skipping any item flagged `pending:true` (see below).
- Macro numbers are Claude's estimates — close, not lab-grade (noted in the page footer).

### Client-side pending entries (not part of `DATA`, lives in `localStorage`)

Two flows stage food items locally before Claude bakes them into `DATA`, both keyed
`fuellog-pending-v1`, deduped against real `DATA` by item text or matching macros:

| Flow | Trigger | `source` | TTL | Counted in totals? | Row tag |
|---|---|---|---|---|---|
| Quick-pick | "I ate this" on a next-meal pick | `'pick'` | 10 min | No (`pending:true`) | "pending" |
| Manual entry | "+ Add food" form | `'manual'` | 7 days | Yes (`unsynced:true`) | "not yet saved" |

Manual entries count toward totals immediately (Kirk supplies his own numbers, no
estimate needed) so the running budget stays accurate through the day even before a
sync. The sync bar's "Copy for Claude" button batches all outstanding `'manual'`
entries (any date) into one message for a single end-of-day paste, instead of one
round-trip per item.

## Update procedure (for Claude)

Kirk primarily works from his PC now, with `health-tracker.html` at
`C:\Users\kcrabb\Downloads\fuel-log\` as the working copy to edit directly.
**No git commit or push for any of this - not even to `main` - unless Kirk
explicitly asks for one in that moment** (see CLAUDE.md Environment & workflow).

1. Edit the `DATA` block directly in the local file — set `updated` to today,
   add/merge the day's entries.
2. Republish the artifact (URL above) via the `url` parameter, with `force: true`
   (see CLAUDE.md Artifacts section for why, and the fallback if it still fails).
3. For feature changes (not data logging): also update this spec and bump the
   changelog, and republish it (spec artifact URL above). Still no git push.
4. Keep the app HTML ASCII-only (HTML entities / `\u` escapes for special characters),
   verified with `node --check` before publishing.

---

## Changelog

### v2.21 — 2026-08-05
- **Reverted v2.20's git-as-backup approach at Kirk's explicit request** ("Stop
  trying to push to git... At all. Ever."). No more automatic commits/pushes for
  any change, routine or feature, without Kirk asking in the moment. Source of
  truth moves back to Kirk's local PC copy at `C:\Users\kcrabb\Downloads\fuel-log\`
  instead of the `main` branch. This was the one push Kirk authorized, specifically
  to make the "stop pushing" instruction itself stick for future sessions.

### v2.20 — 2026-08-05
- **Git (not the artifact) is now the documented recoverable source of truth.** A
  fresh session tried to reconcile via WebFetching the live artifact per the old
  procedure and got nothing - a session that didn't publish a given private artifact
  can't read it back, confirmed not a one-off glitch. Routine logging now commits
  `health-tracker.html` straight to `main` on every publish (no PR, no merge, nothing
  for Kirk to act on), so any session can recover current data straight from the repo.
  The "Update procedure" section was rewritten to a single git-first flow instead of
  the old PC-vs-cloud split that both leaned on WebFetch.
- Also caught and fixed: the CLAUDE.md fix above had been sitting on an unmerged PR
  for hours while a separate fresh session kept hitting `main`'s stale copy - merged
  it. And an accidental placeholder push briefly replaced `health-tracker.html` with
  one line on GitHub; caught within minutes and corrected via a merge favoring the
  real content (not a force-push) - no data was actually lost from `DATA` itself.
- Repo is now public at Kirk's choice (was private) after ruling out GitHub Pages as
  a way to get a permanently stable dashboard link - GitHub's Pages build
  infrastructure itself was stuck/failing that night, unrelated to this repo's
  config, so that attempt was shelved. Live app link still occasionally changes when
  the Claude artifact backend hiccups; git is the durability layer, not the artifact.
- Kirk's local clone now lives at `C:\Users\kcrabb\Downloads\fuel-log\` (was
  `C:\Users\kcrabb\Documents\daybook-health\`, never actually re-created after the
  July migration to this repo).

### v2.19 — 2026-08-05
- **Migrated the app artifact again** - the v2.18 replacement (6016fa31...) got
  permanently stuck within hours of going live, same symptom as the original. Also
  root-caused a *separate* intermittent bug hitting healthy artifacts: routine
  republishes were randomly failing the same "review page" check due to its internal
  content-fetch flaking (HTTP 403), not the publish itself. `force: true` reliably
  bypasses that check and is now used on every app republish (see CLAUDE.md
  Artifacts section). The truly-stuck-artifact failure mode is unaffected by
  `force: true` and still requires migrating to a new URL. No data was lost.

### v2.18 — 2026-08-04
- **Migrated the app artifact to a new URL** after the original personal-account
  artifact (de2ff8ee...) got permanently stuck - every publish attempt failed with
  "could not verify the target page is not a review page," confirmed via A/B testing
  (byte-identical content published successfully as a new artifact, failed every time
  to the old URL). No data was lost; the new artifact was seeded with the complete,
  up-to-date `DATA` block. See CLAUDE.md Artifacts section for the new URL.

### v2.17 — 2026-07-28
- **Codified pick rotation in CLAUDE.md** at Kirk's request, after noticing next-meal
  dinner/snack picks kept reusing the same 2-3 options as a fixed template instead of
  drawing from the full known list (Costa Vida and Mo' Bettahs were in the schedule
  notes the whole time but rarely suggested). Snack options expanded beyond
  jerky/shake to include the Pro2Go Protein Pack, string cheese, turkey roll-ups, and
  plain hard-boiled eggs. Procedural change only - no code/rendering change.

### v2.16 — 2026-07-25
- **Latest-day calorie/protein/carb tiles now show progress against target**, at
  Kirk's request, instead of a bare number. Each tile reads "consumed / target,"
  a percentage, and a color-coded fill bar (green/amber/red). Protein is treated as
  a floor (green once at/above 100%), calories and carbs as caps (red once at/above
  100%, with carbs warning earlier at 75% since it's the stricter self-imposed
  limit). Weight tile is unchanged (plain number, no daily target).

### v2.15 — 2026-07-18
- **"+ Add food" form on the dashboard**, so Kirk can log food (his own item/cal/
  protein/carbs) directly on the page without a Claude round-trip per item. New
  entries stage in `localStorage` as **unsynced** - tagged "not yet saved," counted
  toward totals immediately (unlike quick-pick pending entries, which stay excluded)
  - and persist up to 7 days instead of the quick-pick flow's 10-minute TTL.
- **New "Copy for Claude" sync bar** appears whenever unsynced manual entries exist;
  batches all of them (any date) into one paste-able message, so Kirk can log
  throughout the day and only need one Claude conversation to make it permanent,
  instead of one per item.
- Quick-pick "I ate this" flow unchanged (10-min TTL, excluded from totals) - the two
  pending flows are distinguished internally by a `source: 'pick' | 'manual'` field.

### v2.14 — 2026-07-16
- **`DATA.nextMeal.meals` must never be left empty** (codified in CLAUDE.md). Next-meal
  picks now cycle breakfast → lunch → dinner → next day's breakfast based on which
  meal types are already logged for the day, picking restaurant/at-home options that
  match the relevant day's schedule pattern (e.g. dinner logged on a Tue/Wed/Thu rolls
  to a Mon/Fri-style at-home breakfast if the next day is Mon/Fri). `snacks` stays
  populated only when relevant (e.g. the dispatch shift) and is otherwise left empty.
- Procedural change only - no code change to the rendering logic, which already
  supports an empty `snacks` array and a populated `meals` array.

### v2.13 — 2026-07-16
- **Pending entries (from "I ate this" clicks) no longer count toward totals** - stat
  tiles, remaining budget, food-table total row, 14-day charts, and history all now
  skip `pending:true` food items. They still show as a tagged row in the food log for
  visibility, but a test click (or a click Kirk hasn't confirmed yet) no longer skews
  the numbers.
- **Pending expiry shortened from 7 days to 10 minutes**, and is now based on an actual
  timestamp (`ts` on each pending entry) rather than calendar-day granularity. An
  unconfirmed click clears itself out quickly instead of lingering.

### v2.12 — 2026-07-16
- **Fixed "I ate this" losing the log message on clipboard failure.** Artifacts render
  in a sandboxed iframe that often doesn't delegate clipboard-write permission, so
  `navigator.clipboard.writeText` silently fails on many devices/browsers - but the
  page previously auto-reloaded 1.6s later regardless, wiping the toast (and the only
  copy of the order text) before Kirk could read or manually copy it.
- Toast now always shows the full log message as selectable text, stays open
  indefinitely, and only reloads when Kirk taps a "Done, refresh" button. A "Copy"
  button lets him retry the clipboard write on demand.

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
