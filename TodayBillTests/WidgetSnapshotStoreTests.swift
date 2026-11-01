import XCTest
@testable import TodayBill

final class WidgetSnapshotStoreTests: XCTestCase {
    private var directory: URL!

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: directory)
    }

    func testWriteThenReadReturnsTheSameSnapshot() {
        let store = WidgetSnapshotStore(directory: directory)
        let snapshot = BillWidgetSnapshot(
            generatedAt: Date(timeIntervalSince1970: 1_700_000_000),
            favoriteCount: 4,
            rows: [
                BillWidgetSnapshot.Row(
                    billID: "A1", age: 22, title: "테스트 법안", stageTitle: "위원회", hasChange: true
                )
            ],
            changeCount: 3,
            todayProposalCount: 37
        )

        XCTAssertTrue(store.write(snapshot))
        XCTAssertEqual(store.read(), snapshot)
    }

    func testReadReturnsNilWhenNothingWasWritten() {
        let store = WidgetSnapshotStore(directory: directory)

        XCTAssertNil(store.read())
    }

    func testReadDiscardsACorruptFile() throws {
        let store = WidgetSnapshotStore(directory: directory)
        let url = directory.appendingPathComponent("widget-snapshot.json")
        try Data("not json".utf8).write(to: url)

        XCTAssertNil(store.read())
        XCTAssertFalse(FileManager.default.fileExists(atPath: url.path))
    }

    func testWriteReportsFailureWhenThereIsNoDirectory() {
        let store = WidgetSnapshotStore(directory: nil)

        XCTAssertFalse(store.write(
            BillWidgetSnapshot(
                generatedAt: Date(), favoriteCount: 0, rows: [], changeCount: 0, todayProposalCount: 0
            )
        ))
        XCTAssertNil(store.read())
    }
}
