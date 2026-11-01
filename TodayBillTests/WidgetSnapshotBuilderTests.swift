import XCTest
import UIKit
@testable import TodayBill

final class WidgetSnapshotBuilderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testPutsChangedBillsFirstAndFillsTheRestWithRecentFavorites() {
        let favorites = [
            makeUnchanged(id: "U1", savedDaysAgo: 1),
            makeChanged(id: "C1"),
            makeUnchanged(id: "U2", savedDaysAgo: 3),
            makeChanged(id: "C2")
        ]

        let snapshot = WidgetSnapshotBuilder.make(
            previous: nil, favorites: favorites, todayProposalCount: 37, now: now
        )

        XCTAssertEqual(snapshot.rows.map(\.billID), ["C1", "C2", "U1", "U2"])
        XCTAssertEqual(snapshot.rows.map(\.hasChange), [true, true, false, false])
        XCTAssertEqual(snapshot.changeCount, 2)
        XCTAssertEqual(snapshot.favoriteCount, 4)
    }

    func testSortsUnchangedBillsByMostRecentlySavedAndPutsUndatedLast() {
        let favorites = [
            makeUnchanged(id: "OLD", savedDaysAgo: 10),
            makeUnchanged(id: "NONE", savedDaysAgo: nil),
            makeUnchanged(id: "NEW", savedDaysAgo: 1)
        ]

        let snapshot = WidgetSnapshotBuilder.make(
            previous: nil, favorites: favorites, todayProposalCount: 0, now: now
        )

        XCTAssertEqual(snapshot.rows.map(\.billID), ["NEW", "OLD", "NONE"])
    }

    func testCapsRowsAtMaxRowsButReportsTheFullChangeCount() {
        let favorites = (1...7).map { makeChanged(id: "C\($0)") }

        let snapshot = WidgetSnapshotBuilder.make(
            previous: nil, favorites: favorites, todayProposalCount: 0, now: now
        )

        XCTAssertEqual(snapshot.rows.count, BillWidgetSnapshot.maxRows)
        XCTAssertEqual(snapshot.rows.map(\.billID), ["C1", "C2", "C3", "C4", "C5"])
        XCTAssertEqual(snapshot.changeCount, 7)
        XCTAssertEqual(snapshot.favoriteCount, 7)
    }

    func testCarriesTheFieldsNeededToOpenTheDetailScreen() throws {
        let snapshot = WidgetSnapshotBuilder.make(
            previous: nil, favorites: [makeChanged(id: "A1")], todayProposalCount: 0, now: now
        )

        let row = try XCTUnwrap(snapshot.rows.first)
        XCTAssertEqual(row.billID, "A1")
        XCTAssertEqual(row.age, 22)
        XCTAssertEqual(row.stageTitle, "위원회")
    }

    func testSeparatesNoFavoritesFromNoChanges() {
        let noFavorites = WidgetSnapshotBuilder.make(
            previous: nil, favorites: [], todayProposalCount: 1, now: now
        )
        let noChanges = WidgetSnapshotBuilder.make(
            previous: nil, favorites: [makeUnchanged(id: "B1", savedDaysAgo: 1)], todayProposalCount: 1, now: now
        )

        XCTAssertEqual(noFavorites.favoriteCount, 0)
        XCTAssertTrue(noFavorites.rows.isEmpty)
        XCTAssertEqual(noFavorites.changeCount, 0)

        XCTAssertEqual(noChanges.favoriteCount, 1)
        XCTAssertEqual(noChanges.rows.map(\.billID), ["B1"])
        XCTAssertEqual(noChanges.changeCount, 0)
    }

    func testKeepsTheProposalCountWhenOnlyFavoritesRefreshed() {
        let previous = BillWidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1), favoriteCount: 0,
            rows: [], changeCount: 0, todayProposalCount: 37
        )

        let snapshot = WidgetSnapshotBuilder.make(
            previous: previous, favorites: [makeChanged(id: "A1")], todayProposalCount: nil, now: now
        )

        XCTAssertEqual(snapshot.todayProposalCount, 37)
        XCTAssertEqual(snapshot.changeCount, 1)
        XCTAssertEqual(snapshot.generatedAt, now)
    }

    func testKeepsTheRowsWhenOnlyTheDashboardRefreshed() {
        let previous = BillWidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1), favoriteCount: 1,
            rows: [BillWidgetSnapshot.Row(
                billID: "A1", age: 22, title: "테스트 법안 A1", stageTitle: "위원회", hasChange: true
            )],
            changeCount: 1, todayProposalCount: 1
        )

        let snapshot = WidgetSnapshotBuilder.make(
            previous: previous, favorites: nil, todayProposalCount: 42, now: now
        )

        XCTAssertEqual(snapshot.rows.map(\.billID), ["A1"])
        XCTAssertEqual(snapshot.changeCount, 1)
        XCTAssertEqual(snapshot.favoriteCount, 1)
        XCTAssertEqual(snapshot.todayProposalCount, 42)
        XCTAssertEqual(snapshot.generatedAt, now)
    }

    func testClearsRowsWhenTheLastFavoriteIsRemoved() {
        let previous = BillWidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1), favoriteCount: 1,
            rows: [BillWidgetSnapshot.Row(
                billID: "A1", age: 22, title: "테스트 법안 A1", stageTitle: "위원회", hasChange: true
            )],
            changeCount: 1, todayProposalCount: 5
        )

        let snapshot = WidgetSnapshotBuilder.make(
            previous: previous, favorites: [], todayProposalCount: nil, now: now
        )

        XCTAssertTrue(snapshot.rows.isEmpty)
        XCTAssertEqual(snapshot.favoriteCount, 0)
        XCTAssertEqual(snapshot.changeCount, 0)
        XCTAssertEqual(snapshot.todayProposalCount, 5)
    }

    func testFallsBackToZeroWithNoPreviousSnapshotAndNoInput() {
        let snapshot = WidgetSnapshotBuilder.make(
            previous: nil, favorites: nil, todayProposalCount: nil, now: now
        )

        XCTAssertTrue(snapshot.rows.isEmpty)
        XCTAssertEqual(snapshot.changeCount, 0)
        XCTAssertEqual(snapshot.favoriteCount, 0)
        XCTAssertEqual(snapshot.todayProposalCount, 0)
    }

    // stageKey는 `stage.rawValue`로 시작한다 (Bills.swift:967). committeeDate만 채우면
    // stage는 .committee가 되고 stageKey는 "committee|<날짜>"가 된다.
    private func makeChanged(id: String) -> BillSnapshot {
        BillSnapshot(
            billID: id,
            age: 22,
            title: "테스트 법안 \(id)",
            committeeDate: "2026-02-01",
            isFavorite: true,
            lastSeenStageKey: "committee|2026-01-01"
        )
    }

    private func makeUnchanged(id: String, savedDaysAgo: Int?) -> BillSnapshot {
        BillSnapshot(
            billID: id,
            age: 22,
            title: "테스트 법안 \(id)",
            committeeDate: "2026-01-01",
            isFavorite: true,
            favoriteCreatedAt: savedDaysAgo.map { now.addingTimeInterval(-Double($0) * 86_400) },
            lastSeenStageKey: "committee|2026-01-01"
        )
    }
}

/// Exercises the real UIKit router, including its tab highlight and navigation stack.
@MainActor
final class WidgetDeepLinkIntegrationTests: XCTestCase {
    private var window: UIWindow!
    private var root: MainTabBarViewController!

    override func setUp() {
        super.setUp()
        UIView.setAnimationsEnabled(false)
        window = UIWindow(frame: CGRect(x: 0, y: 0, width: 402, height: 874))
        AppInitializer.setupRootViewController(for: window)
        root = window.rootViewController as? MainTabBarViewController
        root.loadViewIfNeeded()
    }

    override func tearDown() {
        window.isHidden = true
        window.rootViewController = nil
        root = nil
        window = nil
        UIView.setAnimationsEnabled(true)
        super.tearDown()
    }

    private func route(_ value: String) -> Bool {
        AppInitializer.handle(url: URL(string: value)!)
    }

    private var tabBar: MainTabBarView {
        root.view.subviews.compactMap { $0 as? MainTabBarView }.first!
    }

    private func selectedLabels(in view: UIView) -> [String] {
        let own = view.accessibilityTraits.contains(.selected) ? [view.accessibilityLabel ?? ""] : []
        return own + view.subviews.flatMap { selectedLabels(in: $0) }
    }

    func testHomeAndFavoritesKeepHighlightInSyncIncludingRepeatedRoute() {
        XCTAssertTrue(route("todaybill://favorites"))
        XCTAssertTrue((root.selectedViewController as? UINavigationController)?.topViewController is StarBillViewController)
        XCTAssertEqual(root.selectedIndex, 2)
        XCTAssertEqual(selectedLabels(in: tabBar), ["관심"])
        XCTAssertTrue(route("todaybill://favorites"))
        XCTAssertEqual(root.selectedIndex, 2)
        XCTAssertEqual(selectedLabels(in: tabBar), ["관심"])
        XCTAssertEqual(root.viewControllers.count, 3)
        func controls(in view: UIView) -> [UIControl] {
            view.subviews.flatMap { child in
                (child as? UIControl).map { [$0] } ?? controls(in: child)
            }
        }
        controls(in: tabBar).first { $0.accessibilityLabel == "검색" }?.sendActions(for: .touchUpInside)
        XCTAssertEqual(root.selectedIndex, 1)
        XCTAssertEqual(selectedLabels(in: tabBar), ["검색"])
        XCTAssertTrue(route("todaybill://home"))
        XCTAssertTrue((root.selectedViewController as? UINavigationController)?.topViewController is CalenderViewController)
        XCTAssertEqual(root.selectedIndex, 0)
        XCTAssertEqual(selectedLabels(in: tabBar), ["홈"])
    }

    func testDetailRouteCarriesIDAndAgeAndDoesNotStackRepeatedDetails() throws {
        XCTAssertTrue(route("todaybill://bill/QA-A?age=22"))
        let navigation = try XCTUnwrap(root.selectedViewController as? UINavigationController)
        XCTAssertEqual(navigation.viewControllers.count, 2)
        let detail = try XCTUnwrap(navigation.topViewController as? DetailViewController)
        let fields = Dictionary(uniqueKeysWithValues: Mirror(reflecting: detail).children.compactMap { child in
            child.label.map { ($0, child.value) }
        })
        XCTAssertEqual(fields["billID"] as? String, "QA-A")
        XCTAssertEqual(fields["age"] as? Int, 22)
        XCTAssertTrue(route("todaybill://bill/QA-B?age=21"))
        XCTAssertEqual(navigation.viewControllers.count, 2)
        XCTAssertFalse(navigation.topViewController === detail)
    }

    func testCustomTabBarRestoresAfterPoppingDetail() throws {
        root.selectTab(at: 2)
        let navigation = try XCTUnwrap(root.selectedViewController as? UINavigationController)
        root.view.layoutIfNeeded()
        navigation.pushViewController(DetailViewController(billID: "QA-NATIVE", age: 22), animated: false)
        root.view.layoutIfNeeded()
        XCTAssertTrue(navigation.topViewController is DetailViewController)
        XCTAssertTrue(tabBar.isHidden)
        navigation.popToRootViewController(animated: false)
        root.view.layoutIfNeeded()
        XCTAssertTrue(navigation.topViewController is StarBillViewController)
        XCTAssertFalse(tabBar.isHidden)
        XCTAssertEqual(selectedLabels(in: tabBar), ["관심"])
    }

    func testMalformedRoutesAreRejectedWithoutChangingHome() {
        for value in ["https://favorites", "todaybill://unknown", "todaybill://bill", "todaybill://bill/A", "todaybill://bill/A?age=abc", "todaybill://bill/A?age="] {
            XCTAssertFalse(route(value), value)
            XCTAssertEqual(root.selectedIndex, 0, value)
        }
    }

    func testNonPositiveAgeIsRejected() {
        for age in [0, -1] {
            XCTExpectFailure("Known router defect: non-positive assembly ages are accepted") {
                XCTAssertFalse(route("todaybill://bill/QA?age=\(age)"))
            }
        }
    }

    func testExtraPathSegmentsAreRejected() {
        XCTExpectFailure("Known router defect: lastPathComponent silently drops preceding segments") {
            XCTAssertFalse(route("todaybill://bill/unexpected/QA?age=22"))
        }
    }
}

extension WidgetSnapshotBuilderTests {
    func testMixedRowsAreSortedBeforeTheFiveRowCut() {
        let favorites = [makeUnchanged(id: "U4", savedDaysAgo: 4), makeChanged(id: "C1"),
                         makeUnchanged(id: "U3", savedDaysAgo: 3), makeChanged(id: "C2"),
                         makeUnchanged(id: "U1", savedDaysAgo: 1), makeChanged(id: "C3"),
                         makeUnchanged(id: "U2", savedDaysAgo: 2)]
        let value = WidgetSnapshotBuilder.make(previous: nil, favorites: favorites, todayProposalCount: 12, now: now)
        XCTAssertEqual(value.rows.map(\.billID), ["C1", "C2", "C3", "U1", "U2"])
        XCTAssertEqual(value.favoriteCount, 7)
        XCTAssertEqual(value.changeCount, 3)
    }

    func testFavoritesOnlyFirstWriteDoesNotInventAKnownProposalCount() {
        let value = WidgetSnapshotBuilder.make(previous: nil, favorites: [], todayProposalCount: nil, now: now)
        XCTExpectFailure("Known snapshot defect: unknown proposal count is represented as zero") {
            XCTAssertNil(value.todayProposalCount as Int?)
        }
    }

    func testDashboardOnlyRefreshDoesNotMakeOldFavoritesAppearFresh() {
        let oldDate = now.addingTimeInterval(-9 * 3600)
        let old = WidgetSnapshotBuilder.make(previous: nil, favorites: [makeChanged(id: "OLD")], todayProposalCount: 1, now: oldDate)
        let value = WidgetSnapshotBuilder.make(previous: old, favorites: nil, todayProposalCount: 2, now: now)
        XCTAssertEqual(value.rows, old.rows)
        XCTExpectFailure("Known freshness defect: one component refresh resets the timestamp for retained old data") {
            XCTAssertEqual(value.generatedAt, oldDate)
        }
    }
}


@MainActor
final class TabBarLayoutTests: XCTestCase {
    private func descendants<T: UIView>(_ type: T.Type, in view: UIView) -> [T] {
        view.subviews.flatMap { child in
            (child as? T).map { [$0] } ?? descendants(type, in: child)
        }
    }

    func testPortraitItemsStayCenteredAcrossWidthsAndBottomInsets() throws {
        for width: CGFloat in [320, 402, 768] {
            for bottomInset: CGFloat in [0, 21, 34] {
                let bar = MainTabBarView(frame: CGRect(x: 0, y: 0, width: width, height: max(44, Theme.Metric.tabBarContentHeight + bottomInset)))
                bar.configure(symbolNames: ["house", "magnifyingglass", "star"], titles: ["홈", "검색", "관심"])
                for selection in 0..<3 {
                    bar.select(at: selection, animated: false)
                    bar.setCompact(false)
                    bar.layoutIfNeeded()
                    let controls = descendants(UIControl.self, in: bar)
                    XCTAssertEqual(controls.count, 3)
                    for control in controls {
                        XCTAssertGreaterThanOrEqual(control.bounds.height, 44)
                        let image = try XCTUnwrap(descendants(UIImageView.self, in: control).first)
                        let label = try XCTUnwrap(descendants(UILabel.self, in: control).first)
                        let group = image.convert(image.bounds, to: bar).union(label.convert(label.bounds, to: bar))
                        XCTAssertEqual(group.midY, bar.bounds.midY, accuracy: 0.5)
                        // Comparing both margins doubles the 0.5pt center rounding tolerance.
                        XCTAssertEqual(group.minY, bar.bounds.height - group.maxY, accuracy: 1.001)
                        if bottomInset == 34 {
                            XCTAssertLessThanOrEqual(group.maxY, bar.bounds.height - 17)
                        }
                    }
                }
            }
        }
    }

    func testCompactItemsKeepTheirTouchHeightAndHideLabels() {
        let bar = MainTabBarView(frame: CGRect(x: 0, y: 0, width: 760, height: 44))
        bar.configure(symbolNames: ["house", "magnifyingglass", "star"], titles: ["홈", "검색", "관심"])
        bar.setCompact(true)
        bar.layoutIfNeeded()
        for control in descendants(UIControl.self, in: bar) {
            XCTAssertGreaterThanOrEqual(control.bounds.height, 44)
            for image in descendants(UIImageView.self, in: control) {
                XCTAssertEqual(image.convert(image.bounds, to: bar).midY, bar.bounds.midY, accuracy: 0.5)
            }
            XCTAssertTrue(descendants(UILabel.self, in: control).allSatisfy(\.isHidden))
        }
    }
}


final class ThemeContrastTests: XCTestCase {
    func testNeutralPaletteKeepsTextAndActionsReadableInBothAppearances() {
        func luminance(_ color: UIColor, traits: UITraitCollection) -> CGFloat {
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            color.resolvedColor(with: traits).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            func linear(_ value: CGFloat) -> CGFloat {
                value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
            }
            return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
        }
        let pairs: [(String, UIColor, UIColor)] = [
            ("body text", Theme.textColor, Theme.backgroundColor),
            ("secondary text", Theme.textSecondary, Theme.cellBackgroundColor),
            ("selected tab", Theme.accent, Theme.cellBackgroundColor),
            ("accent badge", Theme.accent, Theme.accentSoft),
            ("primary action", Theme.onAccent, Theme.accent)
        ]
        for style: UIUserInterfaceStyle in [.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            for (name, foreground, background) in pairs {
                let first = luminance(foreground, traits: traits)
                let second = luminance(background, traits: traits)
                let contrast = (max(first, second) + 0.05) / (min(first, second) + 0.05)
                XCTAssertGreaterThanOrEqual(contrast, 4.5, "\(name), \(style)")
            }
        }
    }
}
