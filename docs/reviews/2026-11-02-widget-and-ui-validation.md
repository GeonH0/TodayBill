# Widget and UI validation — 2026-11-02

## Scope

- Medium and large tracked-bill widgets, shared App Group snapshot storage, and app deep links.
- A fixed full-width tab bar with centered icon/label groups, separate layout/navigation responsibilities, and a selection pulse that respects Reduce Motion.
- Warm-white/charcoal app and widget themes matching the icon, including light/dark assets.
- Search filter improvements remain a separate branch; the diagnostic tests document existing incorrect search behavior.

## Verification

Environment: iPhone 17 Pro, iOS 26.3.1 Simulator, arm64, Debug.

The app and embedded widget extension built successfully, and the app launched. The final full suite executed **120 tests: 120 passed, 0 expected failures, 0 failures, 0 skipped**. The previous seven expected-failure cases now assert correct behavior directly. Existing Core Data duplicate BillEntity model warnings remain in test logs.

Coverage includes persistence/corruption/write failure, row ordering and limits, partial refresh with failed favorites preserved, actual repository removal/read mutations writing to the App Group, cache/source freshness, legacy cache migration, unknown versus confirmed-zero counts, proposal date rollover, malformed URLs, root restoration on repeated deep links, real window-hosted nonzero safe-area layout, touch sizing, and light/dark contrast including muted text.

API fixtures exercise the real API client → Repository → dashboard → widget update path. A 14-proposal response keeps the widget count at 14 while the dashboard preview remains limited to 10. Empty successful responses confirm zero; offline/unverified responses remain unknown. A law-section failure does not invalidate a separately successful proposal fetch.

`SearchFilterInspectionTests` still contains three diagnostic tests that assert observed incorrect behavior and a menu-structure test. Their passing result does **not** establish correct search behavior. Conversion to desired-behavior assertions belongs to the separate filter plan.

## Review fixes

| Area | Result |
| --- | --- |
| Partial refresh | Always project all current favorite snapshots; only successfully refreshed IDs receive new source timestamps. Ten favorites remain ten when three refreshes fail. |
| Favorite mutations | Add/remove/read changes write immediately without advancing network freshness. |
| Freshness | File generation, per-favorite refresh dates, and proposal source dates/times are separate. Local edits, cached reads, and count-only writes cannot make old favorites look fresh. Older proposal responses cannot overwrite newer source data. |
| Today's count | Count verified raw proposal records independently of the ten-row preview. Preserve the source date; never substitute an earlier day's bills. |
| Unknown data | Missing favorites/counts are distinct from confirmed empty/zero. No snapshot hides the status/footer and asks the user to open the app. Version-1 snapshots are read conservatively until refreshed. |
| Timeline | Entries at source-staleness and midnight boundaries preserve the date semantics; stale age uses a live relative date. |
| Storage | Decode failure leaves the path intact, avoiding deletion of a concurrent atomic replacement. In-app read/modify/write operations share a lock. |
| Deep links | Reject invalid ages, additional/encoded path segments, duplicate age parameters, and ambiguous authorities. Home/favorites restore their roots, and detail routing replaces the stack atomically. |
| UI/docs | Muted text contrast improved and tested; real window safe-area layout and reset-action style verified; repeat-test destination is portable. |

Of the 18 CodeRabbit issues on the previous head, 17 are addressed. The remaining suggestion to force a 40pt bar when the bottom safe inset is zero is deliberately not applied: the bar uses a 40pt base plus the bottom inset, with a 44pt total minimum to preserve touch targets. Its content stays centered in portrait. This is an intentional layout decision, not an unresolved data defect. All three additional nitpicks are addressed.

## Second CodeRabbit pass

CodeRabbit completed its review of `52efc1e` on 2026-11-02: six new Minor issues, two Minor follow-up comments, and one Trivial test-coverage comment. These are separate from the earlier 18 issues. The following changes address this pass:

- Invalid/non-positive assembly ages now produce a widget row destination of the favorites root, preserving strict detail URL validation while avoiding dead taps.
- Favorite fetches expose a Result for widget mutations and refreshes. A failed read skips writing; a confirmed empty read clears the list. Refresh read failures propagate instead of becoming successful empty refreshes.
- A successful response with an unknown total explicitly clears an earlier count, retaining the new source timestamp so an older cached response cannot restore it. Failed proposal requests keep the prior value.
- Cached bills no longer bypass the network when today's count metadata is absent or belongs to a previous day, allowing older app caches to populate the new fields.
- An otherwise empty dashboard with yesterday's count no longer qualifies as visible content.
- The footer also displays the proposal source age after six hours; the timeline schedules that boundary independently from favorite staleness.
- Fresh proposal previews use IDs in the successful API response, so old today-dated database rows cannot contradict a newly verified zero. No stored bill is deleted; failed requests retain the cached preview.
- The home controller observes significant time changes and reloads the existing dashboard path, preserving a manually selected calendar date.
- The hosted layout test now runs even on devices with no bottom inset, checking the 44pt minimum there too.

Eight additional regression tests cover these paths. All 117 tests pass with no expected failures. A further CodeRabbit review is requested after pushing these changes; its result is not implied by this local validation.

## Third CodeRabbit pass

[Review of 5d3d2b6](https://github.com/GeonH0/TodayBill/pull/30#pullrequestreview-5731707145) completed successfully. It posted no new inline issues and raised two Minor follow-up comments plus one Trivial coverage comment:

- The pre-notification favorites recheck now uses Result and propagates read failure instead of silently skipping eligible notifications. The initial widget read also propagates failure. Tests confirm no notification is sent and the previous widget file is preserved on an initial read failure.
- Loading today's dashboard now fetches the API even when Core Data already contains today-dated bills. Historical-date cache reads remain available when today's count metadata is valid; failed requests still keep their source timestamp and cached count.
- The time-change test now selects a historical date and verifies that the notification preserves that selection, alongside the original today-date check.

Final full suite: **119 passed, 0 expected failures, 0 failures, 0 skipped**. These follow-up fixes are committed separately and submitted for another review; the latest pushed commit should be checked before merging.

## Post-registration history-read follow-up

[CodeRabbit review of d04e05e](https://github.com/GeonH0/TodayBill/pull/30#pullrequestreview-5733579635) raised one Minor follow-up: the favorites read after successful notification registration still converted a database error to an empty list. That final read now uses Result and reports failure without updating notification history. The regression test injects an error specifically after registration, confirms the old history is preserved and the run reports failure, then verifies successful recovery and suppression after history has been recorded.

Full suite after this change: **120 passed, 0 expected failures, 0 failures, 0 skipped**. Notification registration has already succeeded at this failure point; propagating the error does not retract an already delivered notification or guarantee exactly-once delivery across registration and history persistence.

## Search-filter follow-up

- Reset omits the committee filter.
- An in-flight search drops new filter requests.
- Late responses can repopulate results after clearing the query.
- A page with no matches after client filtering incorrectly terminates pagination.
- The action sheet mixes 14 actions without sections or selected-state markers.

See [the follow-up implementation plan](../plans/2026-11-02-search-filter-improvements.md).

## Limits

- The current proposal API request fetches at most 1,000 records. A full-size response does not establish the complete daily total, so it produces an unknown count rather than a potentially truncated number. Full pagination/server-count support remains future work.
- Actual home-screen widget placement and widget taps are not visually verified. Earlier app-host renders are not equivalent to WidgetKit home-screen rendering.
- Six-hour and midnight transitions are verified with deterministic model tests, not an elapsed wall-clock device run. Actual background scheduling, iOS 16.4 runtime behavior, and physical-device provisioning remain unverified.
- Local final result bundle: `/tmp/todaybill-post-notification-read-fix.xcresult` (not committed).

## Repeat the tests

```sh
xcodebuild -project TodayBill.xcodeproj -scheme TodayBill \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -parallel-testing-enabled NO test
```
