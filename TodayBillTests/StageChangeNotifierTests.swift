import XCTest
@testable import TodayBill

final class StageChangeNotifierTests: XCTestCase {
    func testBillsToNotifyIncludesOnlyUnnotifiedUnseenChanges() {
        let changed = makeSnapshot(id: "A1", committeeDate: "2025-02-01", lastSeenStageKey: "committee|2025-01-01")
        let unchanged = makeSnapshot(id: "A2", committeeDate: "2025-01-01", lastSeenStageKey: "committee|2025-01-01")
        let alreadyNotified = makeSnapshot(id: "A3", committeeDate: "2025-03-01", lastSeenStageKey: "committee|2025-01-01")

        let result = StageChangeNotifier.billsToNotify(
            from: [changed, unchanged, alreadyNotified],
            notifiedStageKeys: ["A3": alreadyNotified.stageKey]
        )

        XCTAssertEqual(result.map(\.billID), ["A1"])
    }

    func testBillsToNotifyIgnoresNonFavorites() {
        let nonFavorite = makeSnapshot(id: "B1", committeeDate: "2025-02-01", lastSeenStageKey: "committee|2025-01-01", isFavorite: false)

        let result = StageChangeNotifier.billsToNotify(from: [nonFavorite], notifiedStageKeys: [:])

        XCTAssertTrue(result.isEmpty)
    }

    func testBillsToNotifyExcludesNeverSeenBills() {
        let neverSeen = makeSnapshot(id: "C1", committeeDate: "2025-02-01", lastSeenStageKey: nil)

        let result = StageChangeNotifier.billsToNotify(from: [neverSeen], notifiedStageKeys: [:])

        XCTAssertTrue(result.isEmpty)
    }

    private func makeSnapshot(
        id: String,
        committeeDate: String,
        lastSeenStageKey: String?,
        isFavorite: Bool = true
    ) -> BillSnapshot {
        BillSnapshot(
            billID: id,
            age: 22,
            title: "테스트 법안 \(id)",
            committeeDate: committeeDate,
            isFavorite: isFavorite,
            lastSeenStageKey: lastSeenStageKey
        )
    }
}
