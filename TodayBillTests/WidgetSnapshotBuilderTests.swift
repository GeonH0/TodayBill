import XCTest
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
