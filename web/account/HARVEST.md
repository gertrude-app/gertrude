# web/account — harvested code tracker

Code copied into `web/account` from elsewhere in the monorepo, tracked here so we can
consolidate or delete it deliberately later (not let it rot as silent duplication).

**Not tracked here:** anything consumed from `@gertrude/ui` — that design system is a
normal `workspace:*` dependency, not copied. Everything below was copied from
`web/dashboard-v2` (Kiah's mock prototype). dashboard-v2 is an _app_, so it exports
nothing as a package — copying was the only option (the M1 "Option A: harvest" decision).

> ⚠️ These are **copies**, so edits to the dashboard-v2 originals will drift from these.
> Re-sync or consolidate before that bites.

## Components — all from `web/dashboard-v2/src/components/`

| file                              | modifications vs. source                                                                                                                                                              | eventual disposition                                           |
| --------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| `CardContainer.tsx`               | verbatim                                                                                                                                                                              | graduate into `@gertrude/ui`?                                  |
| `DashboardPage.tsx`               | verbatim                                                                                                                                                                              | graduate into `@gertrude/ui`? (page shell + `@container/main`) |
| `ActivityFeed.tsx`                | import path only (`#/lib/mock` → `#/lib/activity`)                                                                                                                                    | consolidate w/ dashboard-v2 when old dash dies                 |
| `ActivityOverviewList.tsx`        | adapted to take server day-aggregates (`DaySummary[]`) not `ActivityItem[]`; typed `<Link>` w/ route params not a `dayHref` string; `@shared/datetime` + `@gertrude/ui` Badge/inflect | consolidate w/ dashboard-v2 when old dash dies                 |
| `ActivityPersonSection.tsx`       | gated "Delete all" button on `onDeleteAll` presence                                                                                                                                   | ″                                                              |
| `ScreenshotActivityItem.tsx`      | added `width`/`height` props + `<img>` attrs (anti-jump); gated controls overlay on callbacks                                                                                         | ″ — also upstream width/height to Kiah                         |
| `KeylogActivityItem.tsx`          | gated action buttons on callbacks                                                                                                                                                     | ″                                                              |
| `unauthed/UnauthedForm.tsx`       | M1 copy                                                                                                                                                                               | graduate into `@gertrude/ui`?                                  |
| `unauthed/UnauthedPageLayout.tsx` | M1 copy                                                                                                                                                                               | graduate into `@gertrude/ui`?                                  |

## Lib

| symbol                                       | file              | source                                     | note                                                                                                         |
| -------------------------------------------- | ----------------- | ------------------------------------------ | ------------------------------------------------------------------------------------------------------------ |
| `dateFromDayParam`                           | `lib/activity.ts` | dashboard-v2 `lib/activity-helpers.ts`     | verbatim; no shared equivalent (it's a parser)                                                               |
| `chunkActivityBySuspension`, `ActivityChunk` | `lib/activity.ts` | dashboard-v2 `lib/activity-helpers.ts`     | verbatim                                                                                                     |
| `ActivityItem`                               | `lib/activity.ts` | adapted from dashboard-v2 `lib/mock` types | added `width`/`height` to screenshot variant                                                                 |
| `toActivityItems`                            | `lib/activity.ts` | **new**                                    | wire → `ActivityItem` mapper (account-specific)                                                              |
| `dayRange`                                   | `lib/activity.ts` | **new**                                    | day → `{start,end}` ISO; no shared equivalent                                                                |
| `toDaySummaries`, `DaySummary`               | `lib/activity.ts` | **new**                                    | `GetPersonActivitySummaries` wire → day cards                                                                |
| `ActivityReviewStats`                        | `lib/activity.ts` | dashboard-v2 `lib/activity-helpers.ts`     | type verbatim; stats now from server counts, not derived from items (`getActivityReviewStats` not harvested) |
| `groupBy`                                    | `lib/utils.ts`    | dashboard-v2 `lib/utils.ts`                | not in `@shared/ts-utils`; could move there                                                                  |

## Copied assets — `public/` (M1)

`bg.svg`, `dot-noise-pattern.svg`, `favicon.png`, `gertrude-am-app-icon.webp`,
`gertrude-blocker-app-icon.webp`, `logo-icon.svg`, `logo-wordmark.svg`,
`mac-app-screenshot.png` — duplicated from dashboard-v2. Brand assets (logos/favicon) are
candidates for a shared location; the 3 marketing login images are the most optional.

## Also app-local (not copied, but app-specific) — `src/styles.css`

`.bg-dots` utility was copied from dashboard-v2's `styles.css` (the shared `ui` CSS
doesn't define it, even though `ui`'s `EmptyState` uses it — arguably a `ui` bug).
