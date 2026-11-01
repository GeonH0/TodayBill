# Widget and UI validation — 2026-11-02

## Scope

- Medium and large tracked-bill widgets, shared App Group snapshot storage, and app deep links.
- A fixed full-width tab bar, centered icon/label groups, separate layout and navigation responsibilities, 40pt visual height with at least 44pt touch targets, and a small selection pulse that respects Reduce Motion.
- Matching app icon, warm-white/charcoal theme, widget theme, and light/dark color assets.
- Search filter improvements are planned for a separate branch; their search behavior is unchanged here.

## Verification

Environment: iPhone 17 Pro, iOS 26.3.1 Simulator, arm64, Debug.

The app and embedded widget extension built successfully. The final full test run executed **92 tests: 85 passed, 7 expected failures, 0 unexpected failures, 0 skipped**. The expected failures reproduce unresolved defects; the green test run does not mean these behaviors are correct. Existing Core Data duplicate BillEntity model warnings remain.

Coverage includes snapshot persistence/corruption/write failure, mixed-row ordering and limits, App Group writes after favorite/read/removal changes, total/partial refresh failure, deep-link navigation and repeated selection, tab-bar layout/touch sizing, detail hide/restore, and light/dark text/action contrast.

`SearchFilterInspectionTests` contains three diagnostic tests that intentionally assert observed incorrect behavior and one menu-structure test. They are **not** regression tests proving correct search behavior. Their conversion to desired-behavior assertions is part of the separate filter plan.

## Unresolved widget/deep-link defects

| Area | Reproduction / impact |
| --- | --- |
| Partial refresh | With 10 favorites and 3 refresh failures, the snapshot reports 7 favorites with a new generation timestamp. |
| Today proposal count | The widget receives a dashboard preview capped at 10 items, so 14 cached proposals become 10. |
| Proposal date | No proposals today falls back to the latest earlier date, presenting older bills as today's count. |
| Unknown data | Missing proposal data is represented as 0; a missing snapshot also shows no changes / 0 proposals. |
| Freshness | Refreshing only the dashboard resets the single snapshot timestamp while old favorite rows are retained. |
| URL validation | Non-positive assembly ages and additional bill path segments are accepted. |

The seven expected-failure test cases cover these paths (proposal count/date and unknown/freshness are separate cases). The invalid-age test includes both 0 and -1, so eight expected-failure assertions appear across seven cases.

These issues are explicitly disclosed for review. No claim of merge readiness is made by this validation note. Resolve or explicitly triage them before merging.

## Search-filter follow-up

- Reset omits the committee filter.
- An in-flight search causes new filter requests to be dropped.
- Late responses can repopulate results after clearing the query.
- A page with no matches after client filtering incorrectly terminates pagination, hiding matches on later pages.
- The action sheet mixes 14 actions without sections or selected-state markers.

See [the follow-up implementation plan](../plans/2026-11-02-search-filter-improvements.md).

## Limits

- Actual home-screen widget placement and widget tap behavior are not visually verified. Simulator UI automation did not complete placement.
- The temporary app-host renders from earlier QA are not equivalent to actual WidgetKit home-screen rendering.
- Real six-hour timeline transitions, actual background refresh scheduling, iOS 16.4 runtime behavior, and physical-device provisioning remain unverified.
- Final simulator result bundle is local at `/tmp/todaybill-pr-2026-11-02.xcresult`; it is not included in the repository.

## Repeat the tests

```sh
xcodebuild -project TodayBill.xcodeproj -scheme TodayBill \
  -destination 'id=AFDD5BBC-06ED-4362-B2E4-7F42EA91575C' \
  -parallel-testing-enabled NO test
```
