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

    func testSaveSnapshotsUpdatesExistingBillAndPreservesFavorite() throws {
        let manager = CoreDataManager.makeInMemory()
        let firstRow = try makeRow(id: "A2", date: "2025-01-01", committee: "교육위원회")
        manager.saveAll([firstRow])

        var snapshot = try XCTUnwrap(manager.fetchSnapshot(id: "A2"))
        snapshot.isFavorite = true
        _ = manager.setFavorite(snapshot: snapshot, isFavorite: true)

        let updatedRow = try makeRow(id: "A2", date: "2025-01-01", committee: "법제사법위원회")
        manager.saveAll([updatedRow])

        let updated = try XCTUnwrap(manager.fetchSnapshot(id: "A2"))
        XCTAssertEqual(updated.displayCommittee, "법제사법위원회")
        XCTAssertTrue(updated.isFavorite)
        XCTAssertNotNil(updated.favoriteCreatedAt)
    }

    func testMigratesUserDefaultsFavoritesIntoSnapshots() throws {
        let manager = CoreDataManager.makeInMemory()
        let legacy = StarredBill(ID: "LEGACY-1", age: 22, name: "Legacy Bill")

        manager.migrateUserDefaultsFavorites([legacy])

        let favorite = try XCTUnwrap(manager.fetchFavoriteSnapshots().first)
        XCTAssertEqual(favorite.billID, "LEGACY-1")
        XCTAssertEqual(favorite.title, "Legacy Bill")
        XCTAssertTrue(favorite.isFavorite)
    }

    func testBillStageDetectsProgressionAndUnseenChange() throws {
        let proposed = BillSnapshot(billID: "B1", age: 22, title: "제안 법안", proposedDate: "2025-01-01")
        XCTAssertEqual(proposed.stage, .proposed)

        let lawReview = BillSnapshot(
            billID: "B1",
            age: 22,
            title: "법사위 법안",
            proposedDate: "2025-01-01",
            lawProcDate: "2025-02-01",
            isFavorite: true,
            lastSeenStageKey: proposed.stageKey
        )

        XCTAssertEqual(lawReview.stage, .lawReview)
        XCTAssertTrue(lawReview.hasUnseenStageChange)
    }

    func testDetailTimelineStepsReflectCurrentStage() {
        let proposed = BillSnapshot(billID: "TL-1", age: 22, title: "제안", proposedDate: "2026-01-01")
        XCTAssertEqual(proposed.detailTimelineSteps.map(\.title), ["제안", "위원회", "법사위", "본회의", "처리 결과"])
        XCTAssertEqual(proposed.detailTimelineSteps.map(\.status), [.current, .pending, .pending, .pending, .pending])

        let committee = BillSnapshot(
            billID: "TL-2",
            age: 22,
            title: "위원회",
            proposedDate: "2026-01-01",
            committeeDate: "2026-01-10"
        )
        XCTAssertEqual(committee.detailTimelineSteps.map(\.status), [.completed, .current, .pending, .pending, .pending])
        XCTAssertEqual(committee.detailTimelineSteps[1].dateText, "2026-01-10")

        let lawReview = BillSnapshot(
            billID: "TL-3",
            age: 22,
            title: "법사위",
            proposedDate: "2026-01-01",
            lawProcDate: "2026-01-20"
        )
        XCTAssertEqual(lawReview.detailTimelineSteps.map(\.status), [.completed, .completed, .current, .pending, .pending])

        let plenary = BillSnapshot(
            billID: "TL-4",
            age: 22,
            title: "본회의",
            proposedDate: "2026-01-01",
            plenaryDate: "2026-02-01"
        )
        XCTAssertEqual(plenary.detailTimelineSteps.map(\.status), [.completed, .completed, .completed, .current, .pending])

        let completed = BillSnapshot(
            billID: "TL-5",
            age: 22,
            title: "처리",
            proposedDate: "2026-01-01",
            procResult: "가결"
        )
        XCTAssertEqual(completed.detailTimelineSteps.map(\.status), [.completed, .completed, .completed, .completed, .current])
        XCTAssertEqual(completed.detailTimelineSteps[4].dateText, "가결")
    }

    func testDetailTimelineStepsUseQuietFallbacks() {
        let unknown = BillSnapshot(billID: "TF-1", age: 22, title: "날짜 없음")
        XCTAssertEqual(unknown.detailTimelineSteps[0].dateText, "미확인")

        let committeeWithoutDate = BillSnapshot(
            billID: "TF-2",
            age: 22,
            title: "위원회 날짜 없음",
            proposedDate: "2026-01-01",
            committee: "교육위원회"
        )
        XCTAssertEqual(committeeWithoutDate.detailTimelineSteps[1].status, .current)
        XCTAssertEqual(committeeWithoutDate.detailTimelineSteps[1].dateText, "일정 미정")

        let resultOnly = BillSnapshot(
            billID: "TF-3",
            age: 22,
            title: "결과만 있음",
            procResult: "폐기"
        )
        XCTAssertEqual(resultOnly.detailTimelineSteps[0].dateText, "미확인")
        XCTAssertEqual(resultOnly.detailTimelineSteps[1].dateText, "일정 미정")
        XCTAssertEqual(resultOnly.detailTimelineSteps[4].dateText, "폐기")
        XCTAssertEqual(resultOnly.detailTimelineSteps[4].status, .current)
    }

    func testDetailInsightReasonsReturnReasonChipsWithoutScores() throws {
        let now = try XCTUnwrap(Self.dateFormatter.date(from: "2026-06-27"))
        let lawReview = BillSnapshot(
            billID: "INSIGHT-1",
            age: 22,
            title: "진행 빠른 법안",
            proposedDate: "2026-06-20",
            memberList: (1...12).map { "의원\($0)" }.joined(separator: ","),
            lawProcDate: "2026-06-24"
        )

        let lawReviewReasons = lawReview.detailInsightReasons(now: now)
        XCTAssertEqual(lawReviewReasons.count, 3)
        XCTAssertTrue(lawReviewReasons.contains(.recentlyProposed))
        XCTAssertTrue(lawReviewReasons.contains(.manyCosponsors))
        XCTAssertTrue(lawReviewReasons.contains(.fastProgress))
        XCTAssertFalse(lawReviewReasons.contains(.keywordMatch))
        XCTAssertFalse(lawReviewReasons.contains(.trackedCommittee))

        let plenary = BillSnapshot(
            billID: "INSIGHT-2",
            age: 22,
            title: "본회의 법안",
            proposedDate: "2026-05-01",
            plenaryDate: "2026-06-27"
        )
        XCTAssertEqual(plenary.detailInsightReasons(now: now), [.plenarySoon])
    }

    func testFavoriteToggleUpdatesFavoriteAndLastSeenStageKey() {
        let manager = CoreDataManager.makeInMemory()
        let snapshot = BillSnapshot(
            billID: "FAV-1",
            age: 22,
            title: "추적 법안",
            proposedDate: "2026-06-01",
            lawProcDate: "2026-06-10"
        )
        manager.saveSnapshots([snapshot])

        let favorite = manager.toggleFavorite(id: snapshot.billID)
        XCTAssertTrue(favorite?.isFavorite == true)
        XCTAssertEqual(favorite?.lastSeenStageKey, favorite?.stageKey)

        let removed = manager.toggleFavorite(id: snapshot.billID)
        XCTAssertTrue(removed?.isFavorite == false)
        XCTAssertNil(removed?.lastSeenStageKey)
    }

    func testBillFilterMatchesFavoritesStatusAndSortOrder() throws {
        let manager = CoreDataManager.makeInMemory()
        let oldRow = try makeRow(id: "OLD", date: "2025-01-01", committee: "교육위원회")
        let newRow = try makeRow(id: "NEW", date: "2025-03-01", committee: "환경노동위원회")
        manager.saveAll([oldRow, newRow])

        let newSnapshot = try XCTUnwrap(manager.fetchSnapshot(id: "NEW"))
        _ = manager.setFavorite(snapshot: newSnapshot, isFavorite: true)

        let filter = BillFilter(
            query: "Test",
            dateRange: .all,
            status: .committee,
            committee: "환경",
            favoriteOnly: true,
            sortOrder: .latest
        )

        let results = manager.searchSnapshots(filter: filter)
        XCTAssertEqual(results.map(\.billID), ["NEW"])
    }

    func testAssemblySummaryClientParsesPrntSummaryFragment() throws {
        let html = """
        <div id="prntSummary">
            제안이유 및 주요내용 이 법안은 테스트를 위한 제안이유입니다. 주요내용 주요 조항을 정비합니다.
        </div>
        """

        let summary = AssemblySummaryClient().parseFragmentSummaryHTML(html)

        XCTAssertEqual(summary?.proposalReason, "이 법안은 테스트를 위한 제안이유입니다.")
        XCTAssertEqual(summary?.keyContent, "주요 조항을 정비합니다.")
    }

    func testBillSummarySplitsSpacedPrimaryContentMarker() {
        let summary = BillSummary.split(
            rawText: "제안이유 현행 제도를 정비할 필요가 있음. 주요 내용 관련 조항을 명확히 함."
        )

        XCTAssertEqual(summary.proposalReason, "제안이유 현행 제도를 정비할 필요가 있음.")
        XCTAssertEqual(summary.keyContent, "관련 조항을 명확히 함.")
    }

    func testBillSummaryInfersKeyContentWhenMarkerIsMissing() {
        let summary = BillSummary.split(
            rawText: """
            현행법은 관련 제도를 운영하고 있음. 그러나 제도적 공백이 있다는 지적이 있음.
            이에 관련 행위에 대한 제재처분 근거를 마련하려는 것임(안 제35조제2항제6호 신설 등).
            참고사항 이 법률안은 다른 법률안의 의결을 전제로 함.
            """
        )

        XCTAssertEqual(summary.proposalReason, "현행법은 관련 제도를 운영하고 있음.\n그러나 제도적 공백이 있다는 지적이 있음.")
        XCTAssertEqual(summary.keyContent, "이에 관련 행위에 대한 제재처분 근거를 마련하려는 것임(안 제35조제2항제6호 신설 등).")
        XCTAssertFalse(summary.keyContent.contains("분리하지 못했습니다"))
    }

    func testCachedFallbackSummaryIsRepairedWhenSnapshotIsLoaded() {
        let manager = CoreDataManager.makeInMemory()
        let rawText = """
        현행법은 관련 제도를 운영하고 있음. 그러나 보완이 필요하다는 지적이 있음.
        이에 관련 조항을 정비하려는 것임(안 제3조).
        """
        let snapshot = BillSnapshot(
            billID: "SUMMARY-REPAIR",
            age: 22,
            title: "요약 보정 법안",
            summaryProposalReason: rawText,
            summaryKeyContent: BillSummary.unableToSeparateKeyContentText
        )

        manager.saveSnapshots([snapshot])
        let repaired = manager.fetchSnapshot(id: "SUMMARY-REPAIR")

        XCTAssertEqual(repaired?.summaryProposalReason, "현행법은 관련 제도를 운영하고 있음.\n그러나 보완이 필요하다는 지적이 있음.")
        XCTAssertEqual(repaired?.summaryKeyContent, "이에 관련 조항을 정비하려는 것임(안 제3조).")
    }

    func testHotBillScoringUsesInternalSignals() throws {
        let now = try XCTUnwrap(Self.dateFormatter.date(from: "2026-06-27"))
        let snapshot = BillSnapshot(
            billID: "HOT-1",
            age: 22,
            billNo: "220001",
            title: "기후위기 대응 법률안",
            proposedDate: "2026-06-20",
            proposer: "대표의원 외 11인",
            memberList: (1...12).map { "의원\($0)" }.joined(separator: ","),
            committee: "환경노동위원회",
            lawProcDate: "2026-06-24",
            isFavorite: true
        )

        let scored = HotBillScorer.score(
            snapshot,
            context: HotBillScoringContext(
                now: now,
                recentSearchTerms: ["기후"],
                trackedCommittees: ["환경노동위원회"],
                favoriteBillIDs: ["HOT-1"]
            )
        )

        XCTAssertGreaterThan(scored.score, 70)
        XCTAssertTrue(scored.reasons.contains(.recentlyProposed))
        XCTAssertTrue(scored.reasons.contains(.manyCosponsors))
        XCTAssertTrue(scored.reasons.contains(.keywordMatch))
        XCTAssertTrue(scored.reasons.contains(.fastProgress))
        XCTAssertTrue(scored.reasons.contains(.trackedCommittee))
    }

    func testLawNameNormalizationMatchesBillNamesBestEffort() {
        let bill = BillSnapshot(
            billID: "BILL-PRIVACY",
            age: 22,
            title: "개인정보 보호법 일부개정법률안"
        )
        let enforcement = LawEnforcementSnapshot(
            lawID: "001",
            mst: "1001",
            lawName: "개인정보 보호법",
            promulgationDate: "2026-01-01",
            enforcementDate: "2026-07-01",
            ministry: "개인정보보호위원회",
            lawType: "법률",
            detailURL: URL(string: "https://www.law.go.kr"),
            matchedBillID: nil,
            updatedAt: Date()
        )

        let matched = LawBillMatcher.match(lawEnforcements: [enforcement], bills: [bill])

        XCTAssertEqual(BillLawNameNormalizer.normalizedKey("개인정보 보호법 일부개정법률안"), "개인정보보호법")
        XCTAssertEqual(matched.first?.matchedBillID, "BILL-PRIVACY")
    }

    func testLawInfoAPIClientDecodesJSONAndEmptyResponse() throws {
        let json = """
        {
          "LawSearch": {
            "law": [
              {
                "법령ID": "001",
                "법령일련번호": "1001",
                "법령명한글": "개인정보 보호법",
                "공포일자": "20260101",
                "시행일자": "20260701",
                "소관부처명": "개인정보보호위원회",
                "법령구분명": "법률",
                "법령상세링크": "/DRF/lawService.do?OC=test&target=law&MST=1001"
              }
            ]
          }
        }
        """
        let data = try XCTUnwrap(json.data(using: .utf8))
        let decoded = try LawInfoAPIClient().decodeLawEnforcements(from: data)

        XCTAssertEqual(decoded.count, 1)
        XCTAssertEqual(decoded.first?.lawName, "개인정보 보호법")
        XCTAssertEqual(decoded.first?.promulgationDate, "2026-01-01")
        XCTAssertEqual(decoded.first?.enforcementDate, "2026-07-01")
        XCTAssertEqual(decoded.first?.detailURL?.host, "www.law.go.kr")

        let emptyData = try XCTUnwrap(#"{"LawSearch":{"law":[]}}"#.data(using: .utf8))
        XCTAssertTrue(try LawInfoAPIClient().decodeLawEnforcements(from: emptyData).isEmpty)
    }

    func testLawInfoAPIClientDecodesXML() throws {
        let xml = """
        <LawSearch>
          <law>
            <법령ID>002</법령ID>
            <법령일련번호>2002</법령일련번호>
            <법령명한글>전자문서 및 전자거래 기본법</법령명한글>
            <공포일자>20260201</공포일자>
            <시행일자>20260801</시행일자>
            <소관부처명>과학기술정보통신부</소관부처명>
            <법령구분명>법률</법령구분명>
          </law>
        </LawSearch>
        """
        let data = try XCTUnwrap(xml.data(using: .utf8))
        let decoded = try LawInfoAPIClient().decodeLawEnforcements(from: data, contentType: "text/xml")

        XCTAssertEqual(decoded.first?.lawID, "002")
        XCTAssertEqual(decoded.first?.mst, "2002")
        XCTAssertEqual(decoded.first?.enforcementDate, "2026-08-01")
    }

    func testHomeDashboardCacheRoundTrip() throws {
        let suiteName = "HomeDashboardCacheTests.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defer {
            defaults.removePersistentDomain(forName: suiteName)
        }

        let cache = HomeDashboardCache(defaults: defaults)
        let dashboard = HomeDashboard(
            newProposals: [
                BillSnapshot(billID: "CACHE-1", age: 22, title: "캐시 법안", proposedDate: "2026-06-27")
            ],
            failedSections: [.lawEnforcements]
        )

        cache.save(dashboard)
        let loaded = try XCTUnwrap(cache.load())

        XCTAssertEqual(loaded.newProposals.first?.billID, "CACHE-1")
        XCTAssertEqual(loaded.failedSections, [.lawEnforcements])
    }

    func testHomeViewModelEmitsLoadingAndLoadedDashboard() {
        let expectation = expectation(description: "Home dashboard loaded")
        let dashboard = HomeDashboard(
            selectedDateBills: [
                BillSnapshot(billID: "VM-1", age: 22, title: "ViewModel 법안", proposedDate: "2026-06-27")
            ]
        )
        let viewModel = HomeViewModel(repository: MockBillRepository(dashboardResult: .success(dashboard)))
        var didEmitLoading = false
        var didEmitLoaded = false

        viewModel.onStateChange = { state in
            switch state {
            case .loading:
                didEmitLoading = true
            case .loaded(let loadedDashboard):
                didEmitLoaded = loadedDashboard.selectedDateBills.first?.billID == "VM-1"
                expectation.fulfill()
            default:
                break
            }
        }

        viewModel.load(date: Date())

        wait(for: [expectation], timeout: 1)
        XCTAssertTrue(didEmitLoading)
        XCTAssertTrue(didEmitLoaded)
    }

    private func makeRow(id: String, date: String, committee: String? = nil) throws -> Row {
        let committeeJSON = committee.map { #""COMMITTEE": "\#($0)","# } ?? ""
        let json = """
        {
          "BILL_ID": "\(id)",
          "BILL_NO": "123",
          "BILL_NAME": "Test Bill",
          \(committeeJSON)
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

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private final class MockBillRepository: BillRepositoryProtocol {
    private let dashboardResult: Result<HomeDashboard, Error>

    init(dashboardResult: Result<HomeDashboard, Error>) {
        self.dashboardResult = dashboardResult
    }

    func fetchHomeBills(date: Date, completion: @escaping (Result<[BillSnapshot], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchHomeDashboard(date: Date, completion: @escaping (Result<HomeDashboard, Error>) -> Void) {
        completion(dashboardResult)
    }

    func fetchHotBills(limit: Int, completion: @escaping (Result<[HotBillSnapshot], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchLawEnforcements(range: LawEnforcementDateRange, completion: @escaping (Result<[LawEnforcementSnapshot], Error>) -> Void) {
        completion(.success([]))
    }

    func refreshHomeDashboard(completion: @escaping (Result<HomeDashboard, Error>) -> Void) {
        completion(dashboardResult)
    }

    func searchBills(filter: BillFilter, page: Int, completion: @escaping (Result<[BillSnapshot], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchDetail(id: String, age: Int, completion: @escaping (Result<BillSnapshot, Error>) -> Void) {
        completion(.failure(BillsRepositoryError.missingSnapshot))
    }

    func toggleFavorite(id: String, completion: @escaping (Result<BillSnapshot, Error>) -> Void) {
        completion(.failure(BillsRepositoryError.missingSnapshot))
    }

    func refreshFavoriteSnapshots(completion: @escaping (Result<[BillSnapshot], Error>) -> Void) {
        completion(.success([]))
    }

    func markStageSeen(id: String) {
    }

    func fetchSummary(for snapshot: BillSnapshot, completion: @escaping (Result<BillSnapshot, Error>) -> Void) {
        completion(.failure(BillsRepositoryError.missingSnapshot))
    }

    func cachedSnapshot(id: String) -> BillSnapshot? {
        nil
    }
}
