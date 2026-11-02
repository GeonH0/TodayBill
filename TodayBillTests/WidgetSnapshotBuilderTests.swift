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

    func testKeepsMissingInputsUnknownWithoutAPreviousSnapshot() {
        let snapshot = WidgetSnapshotBuilder.make(
            previous: nil, favorites: nil, todayProposalCount: nil, now: now
        )

        XCTAssertTrue(snapshot.rows.isEmpty)
        XCTAssertEqual(snapshot.changeCount, 0)
        XCTAssertNil(snapshot.favoriteCount)
        XCTAssertNil(snapshot.todayProposalCount)
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
            XCTAssertFalse(route("todaybill://bill/QA?age=\(age)"))
        }
    }

    func testExtraPathSegmentsAreRejected() {
        XCTAssertFalse(route("todaybill://bill/unexpected/QA?age=22"))
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
        XCTAssertNil(value.todayProposalCount)
    }

    func testDashboardOnlyRefreshDoesNotMakeOldFavoritesAppearFresh() {
        let oldDate = now.addingTimeInterval(-9 * 3600)
        let old = WidgetSnapshotBuilder.make(previous: nil, favorites: [makeChanged(id: "OLD")], todayProposalCount: 1, now: oldDate, refreshedFavoriteIDs: ["OLD"])
        let value = WidgetSnapshotBuilder.make(previous: old, favorites: nil, todayProposalCount: 2, now: now)
        XCTAssertEqual(value.rows, old.rows)
        XCTAssertEqual(value.generatedAt, now, "File-write time is independent of source freshness")
        XCTAssertEqual(value.favoritesUpdatedAt, oldDate)
    }
}


@MainActor
final class TabBarLayoutTests: XCTestCase {
    private func descendants<T: UIView>(_ type: T.Type, in view: UIView) -> [T] {
        view.subviews.flatMap { child in
            (child as? T).map { [$0] } ?? descendants(type, in: child)
        }
    }

    func testPortraitItemsStayCenteredAcrossWidthsAndBarHeights() throws {
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

    func testHostedContainerUsesRealBottomSafeAreaAndCentersItems() throws {
        let scene = try XCTUnwrap(UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.first)
        let previousKeyWindow = scene.windows.first(where: \.isKeyWindow)
        let window = UIWindow(windowScene: scene)
        let controller = UIViewController()
        let container = MainTabBarContainerView()
        controller.view = container
        window.rootViewController = controller
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
            window.rootViewController = nil
            previousKeyWindow?.makeKey()
        }
        window.layoutIfNeeded()
        container.setNeedsLayout()
        container.layoutIfNeeded()
        guard container.safeAreaInsets.bottom > 0 else {
            throw XCTSkip("This device has no home-indicator safe area")
        }
        container.tabBar.configure(symbolNames: ["house", "magnifyingglass", "star"], titles: ["홈", "검색", "관심"])
        container.tabBar.layoutIfNeeded()
        XCTAssertEqual(container.tabBar.bounds.height,
                       max(44, Theme.Metric.tabBarContentHeight + container.safeAreaInsets.bottom), accuracy: 0.5)
        XCTAssertEqual(container.contentView.frame.maxY, container.tabBar.frame.minY, accuracy: 0.5)
        XCTAssertEqual(container.tabBar.frame.maxY, container.bounds.maxY, accuracy: 0.5)
        for control in descendants(UIControl.self, in: container.tabBar) {
            XCTAssertGreaterThanOrEqual(control.bounds.height, 44)
            let image = try XCTUnwrap(descendants(UIImageView.self, in: control).first)
            let label = try XCTUnwrap(descendants(UILabel.self, in: control).first)
            let group = image.convert(image.bounds, to: container.tabBar)
                .union(label.convert(label.bounds, to: container.tabBar))
            XCTAssertEqual(group.midY, container.tabBar.bounds.midY, accuracy: 0.5)
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
            ("primary action", Theme.onAccent, Theme.accent),
            ("muted text", Theme.textMuted, Theme.cellBackgroundColor),
            ("muted on page", Theme.textMuted, Theme.backgroundColor)
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


extension WidgetSnapshotBuilderTests {
    func testPartialRefreshAndReadEditsPreserveTheOldestSourceDate() {
        let oldDate = now.addingTimeInterval(-9 * 3600)
        let bills = [makeChanged(id: "A"), makeChanged(id: "B")]
        let previous = WidgetSnapshotBuilder.make(previous: nil, favorites: bills, todayProposalCount: 37,
                                                  now: oldDate, refreshedFavoriteIDs: ["A", "B"],
                                                  proposalDate: oldDate, proposalsUpdatedAt: oldDate)
        let partial = WidgetSnapshotBuilder.make(previous: previous, favorites: bills, todayProposalCount: nil,
                                                 now: now, refreshedFavoriteIDs: ["A"])
        XCTAssertEqual(partial.favoriteCount, 2)
        XCTAssertEqual(partial.favoritesUpdatedAt, oldDate)
        XCTAssertEqual(partial.favoriteRefreshDates?["A"], now)
        XCTAssertEqual(partial.favoriteRefreshDates?["B"], oldDate)
        var readBills = bills
        readBills[0].lastSeenStageKey = readBills[0].stageKey
        let local = WidgetSnapshotBuilder.make(previous: partial, favorites: readBills, todayProposalCount: nil, now: now.addingTimeInterval(60))
        XCTAssertEqual(local.changeCount, 1)
        XCTAssertEqual(local.favoritesUpdatedAt, oldDate)
        XCTAssertEqual(local.proposalsUpdatedAt, oldDate)
    }

    func testProposalOnlyWriteLeavesFavoritesUnknown() {
        let value = WidgetSnapshotBuilder.make(previous: nil, favorites: nil, todayProposalCount: 14,
                                                now: now, proposalDate: now, proposalsUpdatedAt: now)
        XCTAssertNil(value.favoriteCount)
        XCTAssertEqual(value.proposalCount(on: now), 14)
    }

    func testCarryForwardDoesNotCallYesterdaysCountToday() throws {
        let old = WidgetSnapshotBuilder.make(previous: nil, favorites: [], todayProposalCount: 14,
                                             now: now, proposalDate: now, proposalsUpdatedAt: now)
        let tomorrow = try XCTUnwrap(Calendar.current.date(byAdding: .day, value: 1, to: now))
        let carried = WidgetSnapshotBuilder.make(previous: old, favorites: [], todayProposalCount: nil, now: tomorrow)
        XCTAssertEqual(carried.todayProposalCount, 14, "Historical value is retained")
        XCTAssertEqual(carried.proposalDate, now)
        XCTAssertNil(carried.proposalCount(on: tomorrow))
    }

    func testSourceStalenessAndMidnightHaveIndependentTimelineBoundaries() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try XCTUnwrap(TimeZone(secondsFromGMT: 9 * 3600))
        let day = calendar.startOfDay(for: now)
        let morning = day.addingTimeInterval(9 * 3600)
        let source = morning.addingTimeInterval(-3600)
        let snapshot = BillWidgetSnapshot(generatedAt: morning, favoriteCount: 1, rows: [], changeCount: 0,
                                          todayProposalCount: 14, favoritesUpdatedAt: source,
                                          proposalDate: morning, proposalsUpdatedAt: morning)
        let midnight = try XCTUnwrap(calendar.date(byAdding: .day, value: 1, to: day))
        XCTAssertEqual(snapshot.refreshBoundaries(after: morning, calendar: calendar),
                       [source.addingTimeInterval(6 * 3600), midnight])
        XCTAssertNil(snapshot.proposalCount(on: midnight, calendar: calendar))
        XCTAssertTrue(snapshot.refreshBoundaries(after: midnight, calendar: calendar).isEmpty)
    }

    func testAddingAnUnrefreshedFavoriteDoesNotInventItsFreshness() {
        let old = WidgetSnapshotBuilder.make(previous: nil, favorites: [makeChanged(id: "A")],
                                             todayProposalCount: nil, now: now, refreshedFavoriteIDs: ["A"])
        let added = WidgetSnapshotBuilder.make(previous: old, favorites: [makeChanged(id: "A"), makeChanged(id: "B")],
                                               todayProposalCount: nil, now: now.addingTimeInterval(60))
        XCTAssertEqual(added.favoriteCount, 2)
        XCTAssertNil(added.favoritesUpdatedAt)
        let removed = WidgetSnapshotBuilder.make(previous: added, favorites: [makeChanged(id: "A")],
                                                 todayProposalCount: nil, now: now.addingTimeInterval(120))
        XCTAssertEqual(removed.favoritesUpdatedAt, now)
    }
}

extension WidgetSnapshotStoreTests {
    func testLegacySnapshotLoadsWithoutTrustingItsInventedZeroOrWriteTime() throws {
        let raw = "{\"generatedAt\":100,\"favoriteCount\":0,\"rows\":[],\"changeCount\":0,\"todayProposalCount\":0}"
        let legacy = try JSONDecoder().decode(BillWidgetSnapshot.self, from: Data(raw.utf8))
        XCTAssertNil(legacy.favoriteCount)
        XCTAssertNil(legacy.favoritesUpdatedAt)
        XCTAssertNil(legacy.proposalCount(on: Date()))
        let encoded = try JSONEncoder().encode(legacy)
        XCTAssertEqual(try JSONDecoder().decode(BillWidgetSnapshot.self, from: encoded), legacy)
    }
}

extension WidgetDeepLinkIntegrationTests {
    func testHomeAndFavoritesLinksPopAlreadySelectedDetailStacks() throws {
        for (url, index) in [("todaybill://home", 0), ("todaybill://favorites", 2)] {
            root.selectTab(at: index)
            let navigation = try XCTUnwrap(root.selectedViewController as? UINavigationController)
            navigation.pushViewController(DetailViewController(billID: "QA-POP", age: 22), animated: false)
            XCTAssertTrue(route(url))
            XCTAssertEqual(root.selectedIndex, index)
            XCTAssertEqual(navigation.viewControllers.count, 1)
            XCTAssertFalse(tabBar.isHidden)
        }
    }

    func testParserRejectsAmbiguousOrMalformedRoutesWithoutUIKitSideEffects() {
        for value in ["todaybill://bill/A?age=22&age=21", "todaybill://bill/A/B?age=22",
                      "todaybill://bill/A%2FB?age=22", "todaybill://home/detail", "todaybill://favorites/detail",
                      "todaybill://user@bill/A?age=22", "todaybill://bill:123/A?age=22"] {
            XCTAssertNil(AppDeepLink(url: URL(string: value)!), value)
        }
        XCTAssertEqual(AppDeepLink(url: URL(string: "todaybill://bill/A?age=22")!), .bill(id: "A", age: 22))
    }
}
