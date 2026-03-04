import XCTest
@testable import TodayBill

final class CoreDataManagerTests: XCTestCase {
    func testSaveAllDeduplicatesByID() throws {
        let manager = CoreDataManager.makeInMemory()

        let row1 = try makeRow(id: "A1", date: "2025-01-01")
        let row2 = try makeRow(id: "A1", date: "2025-01-01")

        manager.saveAll([row1])
        manager.saveAll([row2])

        let bills = manager.fetchBills(for: "2025-01-01")
        XCTAssertEqual(bills.count, 1)
        XCTAssertEqual(bills.first?.ID, "A1")
    }

    private func makeRow(id: String, date: String) throws -> Row {
        let json = """
        {
          "BILL_ID": "\(id)",
          "BILL_NO": "123",
          "BILL_NAME": "Test Bill",
          "PROPOSE_DT": "\(date)",
          "AGE": "22",
          "DETAIL_LINK": "https://example.com",
          "PROPOSER": "Tester",
          "MEMBER_LIST": "Tester"
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        return try JSONDecoder().decode(Row.self, from: data)
    }
}
