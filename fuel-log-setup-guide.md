# Fuel Log — Setup Guide (share this + `fuel-log-starter.html`)

Fuel Log is a food / exercise / weight tracker you run through chat with Claude.
You describe what you ate or how you worked out in plain language; Claude estimates
calories and macros, updates your data, and keeps a dashboard (a Claude artifact)
up to date for you to check any time. No app to install, no account, no manual data
entry beyond talking to Claude.

This guide is the **instructions file** Claude reads to know how to run your tracker.
Pair it with `fuel-log-starter.html`, the blank dashboard template (no one's personal
data in it). Together they're everything you need to run your own copy.

## Quick start

1. Create a new **private** GitHub repo (or just a folder) and put both files in it:
   `fuel-log-starter.html` and this file, renamed to `CLAUDE.md`.
2. Open a Claude Code / claude.ai session pointed at that repo (or just paste both
   files into a chat) and say: **"Set up my Fuel Log."**
3. Claude will ask you a handful of questions (see below) and fill in your **Your
   profile / Targets / Schedule / Preferences** sections at the bottom of this file.
4. Claude publishes `fuel-log-starter.html` as a new Claude artifact — that's your
   live dashboard from now on. Save the URL.
5. From then on, just tell Claude what you ate, how you worked out, or your weight,
   whenever you think of it. Claude updates the dashboard.

---

## First-run onboarding (Claude: do this before anything else)

If the **Your profile**, **Targets**, **Schedule**, and **Preferences** sections
below still contain bracketed placeholders like `[...]`, this file hasn't been
personalized yet. Interview the user conversationally (don't dump this as a giant
form) to fill them in:

1. **Goal.** What are they tracking toward — losing weight, gaining, maintaining,
   building muscle, something else? Starting point and target, if there is one.
2. **Daily targets.** Calories, protein, carbs — or whatever metrics actually matter
   to them (some people don't care about carbs; some care about fiber or sodium
   instead). Don't assume — ask what they want tracked and what "good" looks like
   per metric.
3. **Eating style / constraints.** Can they cook or are they mostly eating out /
   grab-and-go? Any dietary pattern (low-carb, keto, vegetarian, vegan, allergies)?
   Do they want Claude to estimate portions/macros, or will they mostly give exact
   numbers (nutrition labels, restaurant sites)?
4. **Weekly schedule**, in their own words — whatever affects when/where/what they
   eat. Commute, work hours, gym time, shift work, days that look different from
   others. This drives Claude's meal suggestions, so more detail here = better
   suggestions later. Totally fine if it's simple ("I'm home all day, I just forget
   to eat").
5. **Food preferences.** Favorite go-to places or meals, anything they never want
   suggested, any ordering habits worth knowing (e.g. "I always get the dressing on
   the side").
6. **Tone.** How direct vs. encouraging should Claude be? Should it flag patterns
   proactively (e.g. "your dressing choice keeps costing you 300 cal") or just log
   quietly and answer when asked?

Once you have answers, rewrite the four sections below in this same file (keep the
structure, replace the placeholders), delete this onboarding section, and publish
`fuel-log-starter.html` as a new artifact to get started. Everything else in this
file — the workflow, file roles, and logging procedure — is generic and doesn't
need to change.

---

## Environment & workflow

**The live app artifact is the source of truth for data.** At the start of a
session, fetch it and use its `DATA` block — it may be newer than the local copy.

- **Routine logging** (meals, workouts, weigh-ins): merge into `DATA`, republish the
  app artifact via the `url` parameter. Done. No git commit needed for this.
- **Feature changes** (new sections, behavior, different targets structure): if
  this project is backed by a git repo, commit on a branch and open a PR; otherwise
  just make the change and republish. Update this file's changelog (add one at the
  bottom) for feature changes only, not daily logging.

## Files

- The dashboard HTML (started from `fuel-log-starter.html`) — **the app and the
  source of truth.** All data lives in a `const DATA = {...}` block near the top of
  the script, marked with `===== DATA =====` comments. For routine logging, edit
  ONLY that block.
- This file — living instructions + profile + changelog.

## Artifacts

Record the published dashboard URL here once you have one, so every session
republishes to the same address instead of minting a new one each time:

- App: `[fill in after first publish]`

## Logging procedure (every time something gets reported)

1. Merge into `DATA.days["YYYY-MM-DD"]`:
   `{weight, exercise:[{name,minutes,cal}], food:[{item,meal,cal,protein,carbs}]}`
   (adjust the field list to whatever metrics this user's Targets section tracks).
2. Estimate macros for described meals. Nutrition-label or restaurant-published
   numbers beat estimates; a fitness tracker's calorie burn beats generic exercise
   estimates, if they use one.
3. Set `DATA.updated` to today. If the dashboard has a next-meal/suggestion feature,
   refresh it based on remaining daily budget and the Schedule section below —
   actually rotate suggestions, don't reuse the same few every time.
4. Republish the app artifact (same URL). Keep the HTML **ASCII-only** — use HTML
   entities / `\u` escapes for any special characters.
5. Check the actual clock/date (don't infer "today" from conversation flow) before
   logging a new day's entry — sessions can run in a different timezone than the
   user.

---

## Your profile

- Goal: `[what they're tracking toward and any target]`
- Starting point: `[starting weight/metric and date, if relevant]`

## Targets

- `[e.g. 2,000 cal / 150 g protein minimum / 50 g carbs maximum per day]`

## Schedule

`[describe a typical week in their own words — whatever affects when/where/what
they eat]`

## Preferences

`[favorites, vetoes, ordering habits, hydration, anything else worth remembering]`

## Tone

`[how direct vs. encouraging Claude should be, and whether to proactively flag
patterns]`

---

## Changelog

### v1.0
- Initial template, generalized from Fuel Log's personal-instance instructions.
