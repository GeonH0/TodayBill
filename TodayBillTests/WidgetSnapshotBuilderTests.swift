import XCTest
@testable import TodayBill

final class WidgetSnapshotBuilderTests: XCTestCase {
    private let now = Date(timeIntervalSince1970: 1_700_000_000)

    func testKeepsTwoChangesButReportsTheFullCount() {
        let favorites = [makeChanged(id: "A1"), makeChanged(id: "A2"), makeChanged(id: "A3")]

        let snapshot = WidgetSnapshotBuilder.make(
            previous: nil, favorites: favorites, todayProposalCount: 37, now: now
        )

        XCTAssertEqual(snapshot.changes.map(\.billID), ["A1", "A2"])
        XCTAssertEqual(snapshot.changeCount, 3)
        XCTAssertEqual(snapshot.favoriteCount, 3)
        XCTAssertEqual(snapshot.todayProposalCount, 37)
        XCTAssertEqual(snapshot.generatedAt, now)
    }

    func testCarriesTheFieldsNeededToOpenTheDetailScreen() throws {
        let snapshot = WidgetSnapshotBuilder.make(
            previous: nil, favorites: [makeChanged(id: "A1")], todayProposalCount: 0, now: now
        )

        let change = try XCTUnwrap(snapshot.changes.first)
        XCTAssertEqual(change.billID, "A1")
        XCTAssertEqual(change.age, 22)
        XCTAssertEqual(change.stageTitle, "위원회")
    }

    func testSeparatesNoFavoritesFromNoChanges() {
        let noFavorites = WidgetSnapshotBuilder.make(
            previous: nil, favorites: [], todayProposalCount: 1, now: now
        )
        let noChanges = WidgetSnapshotBuilder.make(
            previous: nil, favorites: [makeUnchanged(id: "B1")], todayProposalCount: 1, now: now
        )

        XCTAssertEqual(noFavorites.favoriteCount, 0)
        XCTAssertEqual(noChanges.favoriteCount, 1)
        XCTAssertTrue(noFavorites.changes.isEmpty)
        XCTAssertTrue(noChanges.changes.isEmpty)
    }

    func testKeepsTheProposalCountWhenOnlyFavoritesRefreshed() {
        let previous = WidgetSnapshotBuilder.make(
            previous: nil, favorites: [], todayProposalCount: 37, now: now
        )

        let snapshot = WidgetSnapshotBuilder.make(
            previous: previous, favorites: [makeChanged(id: "A1")], todayProposalCount: nil, now: now
        )

        XCTAssertEqual(snapshot.todayProposalCount, 37)
        XCTAssertEqual(snapshot.changeCount, 1)
    }

    func testKeepsTheChangesWhenOnlyTheDashboardRefreshed() {
        let previous = WidgetSnapshotBuilder.make(
            previous: nil, favorites: [makeChanged(id: "A1")], todayProposalCount: 1, now: now
        )

        let snapshot = WidgetSnapshotBuilder.make(
            previous: previous, favorites: nil, todayProposalCount: 42, now: now
        )

        XCTAssertEqual(snapshot.changes.map(\.billID), ["A1"])
        XCTAssertEqual(snapshot.changeCount, 1)
        XCTAssertEqual(snapshot.favoriteCount, 1)
        XCTAssertEqual(snapshot.todayProposalCount, 42)
    }

    func testFallsBackToZeroWithNoPreviousSnapshotAndNoInput() {
        let snapshot = WidgetSnapshotBuilder.make(
            previous: nil, favorites: nil, todayProposalCount: nil, now: now
        )

        XCTAssertTrue(snapshot.changes.isEmpty)
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

    private func makeUnchanged(id: String) -> BillSnapshot {
        BillSnapshot(
            billID: id,
            age: 22,
            title: "테스트 법안 \(id)",
            committeeDate: "2026-01-01",
            isFavorite: true,
            lastSeenStageKey: "committee|2026-01-01"
        )
    }
}
