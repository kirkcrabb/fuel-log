# Fuel Log — Data model reference for a native iOS build

This is a handoff reference for building a SwiftUI version of Fuel Log. It documents
the data shape and business logic of the existing Claude-artifact version
(`health-tracker.html` in `kirkcrabb/fuel-log`) so a new native app can replicate the
behavior Kirk is used to. Pair with `fuel-log-export.json` for real seed data.

## Core entities

**Day** (keyed by local-time `YYYY-MM-DD` string):
- `weight: Double?` — one optional weigh-in per day, in `weightUnit`
- `exercise: [Exercise]`
- `food: [FoodEntry]`

**Exercise:**
- `name: String`
- `minutes: Double?`
- `cal: Int?` — prefer real device/watch calorie readings over MET-based estimates
  when both are available

**FoodEntry:**
- `item: String`
- `meal: String?` — free text, e.g. `"breakfast"`, `"dinner - Chick-fil-A"`; not an enum
- `cal: Int`, `protein: Int`, `carbs: Int` — grams for protein/carbs

**Targets** (single global record, not per-day):
- `cal: Int`, `protein: Int` (a *minimum*), `carbs: Int?` (a *maximum*, nullable = no cap)

**NextMeal** (single current-state record, not historical):
- `context: String` — free text describing timing, e.g. `"dinner tonight (Sat)"`
- `meals: [Pick]` — must never be empty; see cycling rule below
- `snacks: [Pick]` — empty when not relevant (e.g. no shift that day)

**Pick:**
- `place: String`, `order: String` (specific enough to act on — include quantities)
- `cal: Int`, `protein: Int`, `carbs: Int`
- `note: String?`

**Root:**
- `updated: String` (date of last edit)
- `weightUnit: String` (currently always `"lbs"`)
- `goalWeight: Double?`
- `targets: Targets`
- `nextMeal: NextMeal`
- `days: [String: Day]`

## Derived / computed values (not stored — recompute at render time)

- **Day totals** = sum of `cal`/`protein`/`carbs` across `food` for that day. In the web
  version, entries flagged `pending:true` are excluded from this sum (see below) —
  irrelevant for a native app with real local persistence, since there's no
  "unconfirmed pending entry" concept once you have a real database.
- **Remaining budget** = `targets - dayTotals(latestDay)`, floored at 0 per field.
- **Weight trend** = exponential moving average across all days with a weight value,
  in date order, alpha = 0.1 (~10-day smoothing). First weigh-in seeds the EMA
  directly; each subsequent one updates `trend = trend + 0.1 * (weight - trend)`.
  Used for the "pace" / ETA-to-goal calculation, not the raw weight line.
- **Pace / ETA to goal**: once ≥ 7 days span exists between the first and latest
  trend points, `perWeek = (firstTrend - lastTrend) / spanDays * 7`. If
  `perWeek > 0.05`, project `eta = lastDate + (weightRemaining / perWeek) weeks`.
- **"Latest day"** = the max key in `days` (string sort works because of `YYYY-MM-DD`).

## Business rules worth preserving

1. **Next-meal must never be empty.** Cycle breakfast → lunch → dinner → next day's
   breakfast based on which meal types are already logged for the current day; once
   dinner is logged, "next meal" means tomorrow's breakfast. Picks should match the
   day's schedule pattern (see Kirk's profile notes below) and should always include
   quantities (e.g. "eggs (3)", not just "eggs").
2. **Macro estimation preference order**: nutrition-label or restaurant-published
   numbers > Kirk's own device/watch readings > Claude/app estimate from description.
3. **Low-carb-first ordering preference**: bunless/no rice/no tortilla/no beans by
   default; dressings/sauces are a recurring calorie leak worth flagging.
4. **Net carbs, not total carbs**, for products with sugar alcohols (e.g. keto ice
   cream) — subtract fiber and sugar alcohol from total carbohydrate.
5. The 40g carb target is a **self-imposed preference, not a medical requirement** —
   framed to the user as a tool for appetite control (via mild ketosis / glycogen
   depletion), not a hard limit that must never be crossed.

## What a native app gets "for free" vs. what carried complexity in the web version

The web version's `localStorage`-based "pending" and "unsynced" entry system existed
solely to work around having **no real backend** — it's a workaround for a static
artifact with no database. A native app with actual local persistence (Core Data /
SwiftData / a local SQLite file, optionally synced via CloudKit for cross-device)
doesn't need any of that: food entries can just be written directly and permanently
the moment they're entered. No TTL, no dedup-by-matching-macros, no "sync to Claude"
step required for basic logging.

Where Claude *still* adds value in a native app: estimating macros from a text
description or photo when Kirk doesn't have exact numbers, and generating the
next-meal picks (which require judgment about restaurants, schedule, and
preferences — not just data storage). A reasonable architecture: the app calls the
Claude API directly for those two features, while everything else (storage, totals,
charts, the add-food form) is fully local and instant, no round-trip needed.

## Kirk's profile notes (for next-meal pick generation logic)

- Weight 220-290 lb range, goal 220 lbs. Targets 2,100 cal / 150g protein min / 40g
  carbs max per day.
- Can't cook; eats at restaurants and grab-and-go.
- Schedule-driven picks:
  - **Tue/Wed/Thu**: doTERRA office (breakfast stops en route), doTERRA cafeteria
    salad bar for lunch, BYU dispatch shift until 1am (needs a packable shift snack
    alongside dinner picks).
  - **Mon/Fri**: home all day, often skips breakfast/lunch — zero-effort protein
    picks (roll-ups, hard-boiled eggs, protein shakes), no restaurant commute picks.
  - **Weekends**: unstructured, sometimes a family dinner.
- Vetoes: dislikes Aubergine & Company.
- Drinks Coke Zero freely — not logged, not flagged.

See `fuel-log-export.json` for real historical data to seed the new app with.
