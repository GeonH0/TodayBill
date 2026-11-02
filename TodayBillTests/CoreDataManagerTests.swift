import XCTest
import UIKit
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

    func testRepresentativeLookupExtractsNameAndFormatsCurrentParty() throws {
        let data = try XCTUnwrap(
            #"{"HG_NM":"이주영","POLY_NM":"개혁신당","UNITS":"제22대"}"#
                .data(using: .utf8)
        )
        let representative = try JSONDecoder().decode(Representative.self, from: data)

        XCTAssertEqual(RepresentativeLookup.proposerName(from: "이주영의원 등 10인"), "이주영")
        XCTAssertEqual(
            RepresentativeLookup.displayText(
                proposer: "이주영의원 등 10인",
                representative: representative
            ),
            "이주영 의원 · 개혁신당"
        )
    }

    func testRepresentativeLookupKeepsOriginalProposerWhenDirectoryHasNoMatch() {
        XCTAssertEqual(
            RepresentativeLookup.displayText(proposer: "정부", representative: nil),
            "정부"
        )
        XCTAssertEqual(
            RepresentativeLookup.displayText(proposer: "홍길동의원 등 12인", representative: nil),
            "홍길동의원"
        )
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

        XCTAssertEqual(summary.proposalReason, "현행 제도를 정비할 필요가 있음.")
        XCTAssertEqual(summary.keyContent, "관련 조항을 명확히 함.")
    }

    func testBillSummaryStripsLeadingSectionHeadings() {
        let summary = BillSummary.split(
            rawText: "제안이유 및 주요내용 제안이유 현행 제도를 보완할 필요가 있음. 주요내용 관련 절차를 정비함."
        )

        XCTAssertEqual(summary.proposalReason, "현행 제도를 보완할 필요가 있음.")
        XCTAssertEqual(summary.keyContent, "관련 절차를 정비함.")
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

    func testSearchViewModelSortsAccumulatedPagesBySelectedOrder() {
        let oldSnapshot = BillSnapshot(
            billID: "OLD",
            age: 22,
            title: "환경 오래된 법안",
            proposedDate: "2026-01-01"
        )
        let newSnapshot = BillSnapshot(
            billID: "NEW",
            age: 22,
            title: "환경 최신 법안",
            proposedDate: "2026-03-01"
        )
        let repository = MockBillRepository(
            dashboardResult: .success(HomeDashboard()),
            searchResultsByPage: [
                1: [oldSnapshot],
                2: [newSnapshot]
            ]
        )
        let viewModel = SearchViewModel(repository: repository)
        viewModel.updateFilter(BillFilter(query: "환경", sortOrder: .latest))

        let expectation = expectation(description: "loads and sorts accumulated search pages")
        var requestedNextPage = false

        viewModel.onStateChange = { (state: ViewState<[BillSnapshot]>) in
            guard case .loaded(let snapshots) = state else { return }

            if snapshots.count == 1, !requestedNextPage {
                requestedNextPage = true
                viewModel.loadNextPageIfNeeded()
            } else if snapshots.count == 2 {
                XCTAssertEqual(snapshots.map(\.billID), ["NEW", "OLD"])
                expectation.fulfill()
            }
        }

        viewModel.search()
        wait(for: [expectation], timeout: 1)
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
    var dashboardRequests: [Date] = []
    var pageOverrides: [Int: Result<BillSearchPage, Error>] = [:]
    var requestHandles: [MockSearchRequest] = []
    var holdSearch = false
    var searchRequests: [(BillFilter, Int)] = []
    var pendingSearchCompletions: [(Result<[BillSnapshot], Error>) -> Void] = []
    private let dashboardResult: Result<HomeDashboard, Error>
    private let searchResultsByPage: [Int: [BillSnapshot]]

    init(
        dashboardResult: Result<HomeDashboard, Error>,
        searchResultsByPage: [Int: [BillSnapshot]] = [:]
    ) {
        self.dashboardResult = dashboardResult
        self.searchResultsByPage = searchResultsByPage
    }

    func fetchHomeBills(date: Date, completion: @escaping (Result<[BillSnapshot], Error>) -> Void) {
        completion(.success([]))
    }

    func fetchHomeDashboard(date: Date, completion: @escaping (Result<HomeDashboard, Error>) -> Void) {
        dashboardRequests.append(date)
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

    func searchPage(filter: BillFilter, page: Int, completion: @escaping (Result<BillSearchPage, Error>) -> Void) -> SearchRequestCancelling? {
        let request = MockSearchRequest()
        requestHandles.append(request)
        if let result = pageOverrides[page] {
            searchRequests.append((filter, page))
            completion(result)
        } else {
            searchBills(filter: filter, page: page) { completion($0.map { BillSearchPage(snapshots: $0, hasMore: !$0.isEmpty) }) }
        }
        return request
    }

    func searchBills(filter: BillFilter, page: Int, completion: @escaping (Result<[BillSnapshot], Error>) -> Void) {
        searchRequests.append((filter, page))
        if holdSearch { pendingSearchCompletions.append(completion) }
        else { completion(.success(searchResultsByPage[page] ?? [])) }
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

    func fetchVoteSummary(billID: String, age: Int, completion: @escaping (Result<BillVoteSummary?, Error>) -> Void) {
        completion(.success(nil))
    }

    func fetchRepresentative(proposer: String?, age: Int, completion: @escaping (Result<Representative?, Error>) -> Void) {
        completion(.success(nil))
    }

    func cachedSnapshot(id: String) -> BillSnapshot? {
        nil
    }
}


/// Regression coverage for request ownership, filtered pagination, and draft application.
final class SearchFilterRegressionTests: XCTestCase {
    private func drain() {
        let done = expectation(description: "main queue drained")
        DispatchQueue.main.async { done.fulfill() }
        wait(for: [done], timeout: 2)
    }

    func testFilterChangeStartsANewRequestAndIgnoresOldResults() {
        let repository = MockBillRepository(dashboardResult: .success(HomeDashboard()))
        repository.holdSearch = true
        let model = SearchViewModel(repository: repository)
        model.search(query: "환경")
        var filter = model.filter
        filter.status = .completed
        model.updateFilter(filter)
        model.search()
        XCTAssertEqual(repository.searchRequests.count, 2)
        var loaded: [[String]] = []
        model.onStateChange = { if case .loaded(let values) = $0 { loaded.append(values.map(\.billID)) } }
        repository.pendingSearchCompletions[1](.success([BillSnapshot(billID: "NEW", age: 22, title: "환경", procResult: "가결")]))
        repository.pendingSearchCompletions[0](.success([BillSnapshot(billID: "OLD", age: 22, title: "환경")]))
        drain()
        XCTAssertEqual(loaded, [["NEW"]])
        XCTAssertEqual(model.filter.status, .completed)
    }

    func testClearedSearchIgnoresLateSuccessAndDoesNotRecordRecentTerm() {
        let repository = MockBillRepository(dashboardResult: .success(HomeDashboard()))
        repository.holdSearch = true
        let model = SearchViewModel(repository: repository)
        var loaded = false
        var recentTerms: [String] = []
        model.onStateChange = { if case .loaded = $0 { loaded = true } }
        model.onSearchCompleted = { recentTerms.append($0) }
        model.search(query: "환경")
        model.clearResults()
        repository.pendingSearchCompletions[0](.success([BillSnapshot(billID: "LATE", age: 22, title: "환경")]))
        drain()
        XCTAssertFalse(loaded)
        XCTAssertTrue(recentTerms.isEmpty)
        XCTAssertTrue(model.filter.normalizedQuery.isEmpty)
        XCTAssertEqual(model.currentPage, 0)
    }

    func testLateOldErrorCannotEndNewSearchLoading() {
        let repository = MockBillRepository(dashboardResult: .success(HomeDashboard()))
        repository.holdSearch = true
        let model = SearchViewModel(repository: repository)
        model.search(query: "이전")
        model.search(query: "현재")
        var errorShown = false
        model.onStateChange = { if case .error = $0 { errorShown = true } }
        repository.pendingSearchCompletions[0](.failure(URLError(.timedOut)))
        drain()
        model.loadNextPageIfNeeded()
        XCTAssertEqual(repository.searchRequests.count, 2, "The current request must still own the loading flag")
        XCTAssertFalse(errorShown)
        repository.pendingSearchCompletions[1](.success([]))
        drain()
    }

    func testFilteredEmptyFirstPageAutomaticallyContinuesToMatchingSecondPage() {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [FilterPagingURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let repository = BillRepository(apiClient: OpenAssemblyAPIClient(session: session), coreDataManager: .makeInMemory())
        let model = SearchViewModel(repository: repository)
        model.updateFilter(BillFilter(query: "환경", status: .completed))
        let done = expectation(description: "page two match")
        model.onStateChange = { state in
            if case .loaded(let values) = state {
                XCTAssertEqual(values.map(\.billID), ["QA-MATCH"])
                done.fulfill()
            }
            if case .empty = state { XCTFail("Filtered page one is not the end of the raw results") }
        }
        model.search()
        wait(for: [done], timeout: 5)
        XCTAssertEqual(model.currentPage, 2)
        XCTAssertFalse(model.canLoadMore)
    }

    func testPaginationFailureKeepsResultsAndRetriesTheSamePage() {
        let repository = MockBillRepository(dashboardResult: .success(HomeDashboard()))
        repository.pageOverrides[1] = .success(BillSearchPage(snapshots: [BillSnapshot(billID: "A", age: 22, title: "환경")], hasMore: true))
        repository.pageOverrides[2] = .failure(URLError(.notConnectedToInternet))
        let model = SearchViewModel(repository: repository)
        model.search(query: "환경")
        drain()
        model.loadNextPageIfNeeded()
        drain()
        XCTAssertEqual(model.currentPage, 1)
        XCTAssertTrue(model.canLoadMore)
        repository.pageOverrides[2] = .success(BillSearchPage(snapshots: [BillSnapshot(billID: "B", age: 22, title: "환경")], hasMore: false))
        var latest: [String] = []
        model.onStateChange = { if case .loaded(let values) = $0 { latest = values.map(\.billID).sorted() } }
        model.loadNextPageIfNeeded()
        drain()
        XCTAssertEqual(repository.searchRequests.map { $0.1 }, [1, 2, 2])
        XCTAssertEqual(latest, ["A", "B"])
        XCTAssertEqual(model.currentPage, 2)
        XCTAssertFalse(model.canLoadMore)
    }

    func testResetClearsEveryOptionAndKeepsTheQuery() {
        var filter = BillFilter(query: "환경", dateRange: .recent(days: 30), status: .completed,
                                committee: "환경노동", favoriteOnly: true, sortOrder: .oldest)
        filter.resetOptions()
        XCTAssertEqual(filter, BillFilter(query: "환경"))
        XCTAssertEqual(filter.activeOptionCount, 0)
    }

    @MainActor
    func testFilterSheetEditsDraftAndOnlyApplyPublishesIt() throws {
        let original = BillFilter(query: "환경", committee: "교육", favoriteOnly: true)
        let editor = SearchFilterViewController(filter: original)
        var applied: [BillFilter] = []
        editor.onApply = { applied.append($0) }
        editor.loadViewIfNeeded()
        let form = try XCTUnwrap(editor.view as? SearchFilterView)
        XCTAssertEqual(editor.numberOfSections(in: form.tableView), 5)
        editor.tableView(form.tableView, didSelectRowAt: IndexPath(row: 5, section: 0))
        XCTAssertEqual(editor.draft.status, .completed)
        XCTAssertTrue(applied.isEmpty)
        editor.resetDraft()
        XCTAssertEqual(editor.draft, BillFilter(query: "환경"))
        XCTAssertTrue(applied.isEmpty)
        editor.applyDraft()
        editor.applyDraft()
        XCTAssertEqual(applied, [BillFilter(query: "환경")])
        XCTAssertEqual(original.committee, "교육", "Editing a copy must not mutate the applied filter")
    }

    func testRecentRangeIncludesTheWholeFirstDayAndExcludesEarlierDay() {
        let now = Date()
        let range = BillDateRange.recent(days: 30, now: now)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let first = Calendar.current.startOfDay(for: range.start!)
        let previous = Calendar.current.date(byAdding: .day, value: -1, to: first)!
        let filter = BillFilter(dateRange: range)
        XCTAssertTrue(BillSnapshot(billID: "FIRST", age: 22, title: "A", proposedDate: formatter.string(from: first)).matches(filter: filter))
        XCTAssertFalse(BillSnapshot(billID: "OLDER", age: 22, title: "A", proposedDate: formatter.string(from: previous)).matches(filter: filter))
    }
}

private final class FilterPagingURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        let page = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first { $0.name == "pIndex" }?.value
        var row = ["BILL_ID": page == "2" ? "QA-MATCH" : "QA-NONMATCH", "BILL_NO": "123", "BILL_NAME": "환경 법안", "PROPOSE_DT": "2026-01-01", "AGE": "22", "DETAIL_LINK": "https://example.com", "PROPOSER": "QA", "MEMBER_LIST": "QA"]
        if page == "2" { row["PROC_RESULT"] = "가결" }
        let data = try! JSONSerialization.data(withJSONObject: ["nzmimeepazxkubdpn": [["head": [["list_total_count": 101]]], ["row": [row]]]])
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

final class HomeDayChangeTests: XCTestCase {
    func testSignificantTimeChangeReloadsTheDashboard() {
        let repository = MockBillRepository(dashboardResult: .success(HomeDashboard()))
        let controller = CalenderViewController(viewModel: HomeViewModel(repository: repository))
        controller.loadViewIfNeeded()
        XCTAssertEqual(repository.dashboardRequests.count, 1)
        NotificationCenter.default.post(name: UIApplication.significantTimeChangeNotification, object: nil)
        XCTAssertEqual(repository.dashboardRequests.count, 2)
        XCTAssertTrue(Calendar.current.isDateInToday(repository.dashboardRequests.last!))
        let historical = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
        let selection = UICalendarSelectionSingleDate(delegate: controller)
        controller.dateSelection(selection, didSelectDate: Calendar.current.dateComponents([.year, .month, .day], from: historical))
        NotificationCenter.default.post(name: UIApplication.significantTimeChangeNotification, object: nil)
        XCTAssertTrue(Calendar.current.isDate(repository.dashboardRequests.last!, inSameDayAs: historical))
    }

    func testOnlyTodaysVerifiedCountMakesAnOtherwiseEmptyDashboardVisible() {
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: Date())!
        XCTAssertFalse(HomeDashboard(todayProposalCount: 0, todayProposalDate: yesterday).hasVisibleContent)
        XCTAssertFalse(HomeDashboard(todayProposalCount: 0).hasVisibleContent)
        XCTAssertTrue(HomeDashboard(todayProposalCount: 0, todayProposalDate: Date()).hasVisibleContent)
    }
}

final class SearchPageMetadataTests: XCTestCase {
    private var session: URLSession!
    override func setUp() {
        super.setUp()
        SearchPageURLProtocol.status = 200
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [SearchPageURLProtocol.self]
        session = URLSession(configuration: configuration)
    }
    override func tearDown() { session.invalidateAndCancel(); super.tearDown() }
    private func row(_ id: String) -> [String: String] {
        ["BILL_ID": id, "BILL_NO": "1", "BILL_NAME": "환경", "PROPOSE_DT": "2026-01-01",
         "AGE": "22", "DETAIL_LINK": "https://example.com", "PROPOSER": "QA", "MEMBER_LIST": "QA"]
    }
    private func respond(rows: Int, total: Int? = nil) throws {
        var values: [[String: Any]] = []
        if let total { values.append(["head": [["list_total_count": total], ["RESULT": ["CODE": "INFO-000"]]]]) }
        values.append(["row": (0..<rows).map { row("\($0)") }])
        SearchPageURLProtocol.data = try JSONSerialization.data(withJSONObject: ["nzmimeepazxkubdpn": values])
    }
    private func page(_ number: Int = 1) throws -> BillRowsPage {
        let done = expectation(description: "raw API page")
        var received: Result<BillRowsPage, Error>?
        OpenAssemblyAPIClient(session: session).searchPage(filter: BillFilter(query: "환경"), page: number) { received = $0; done.fulfill() }
        wait(for: [done], timeout: 3)
        return try XCTUnwrap(received).get()
    }
    func testTotalMetadataControlsPaginationBeforeClientFiltering() throws {
        try respond(rows: 1, total: 201)
        XCTAssertTrue(try page().hasMore)
        XCTAssertFalse(try page(3).hasMore)
    }
    func testMissingTotalUsesRawPageSizeInsteadOfFilteredCount() throws {
        try respond(rows: 100)
        XCTAssertTrue(try page().hasMore)
        try respond(rows: 1)
        XCTAssertFalse(try page().hasMore)
    }
    func testNoDataResponseIsAConfirmedEmptyPage() throws {
        SearchPageURLProtocol.data = Data(#"{"RESULT":{"CODE":"INFO-200","MESSAGE":"no data"}}"#.utf8)
        let value = try page()
        XCTAssertTrue(value.rows.isEmpty)
        XCTAssertFalse(value.hasMore)
    }
    func testServiceErrorIsNotTreatedAsNoMatches() throws {
        SearchPageURLProtocol.data = Data(#"{"RESULT":{"CODE":"ERROR-290","MESSAGE":"invalid key"}}"#.utf8)
        XCTAssertThrowsError(try page())
        SearchPageURLProtocol.data = Data(#"{"nzmimeepazxkubdpn":[{"head":[{"RESULT":{"CODE":"ERROR-290"}}]}]}"#.utf8)
        XCTAssertThrowsError(try page())
    }
    func testNetworkFallbackIsLabelledAndCannotBecomeAnotherPage() throws {
        let manager = CoreDataManager.makeInMemory()
        manager.saveSnapshots([BillSnapshot(billID: "CACHED", age: 22, title: "환경")])
        let repository = BillRepository(apiClient: OpenAssemblyAPIClient(session: session), coreDataManager: manager)
        SearchPageURLProtocol.status = 503
        SearchPageURLProtocol.data = Data()
        let first = expectation(description: "cached first page")
        repository.searchPage(filter: BillFilter(query: "환경"), page: 1) { result in
            do {
                let value = try result.get()
                XCTAssertTrue(value.isUsingCache)
                XCTAssertFalse(value.hasMore)
                XCTAssertEqual(value.snapshots.map(\.billID), ["CACHED"])
            } catch { XCTFail("\(error)") }
            first.fulfill()
        }
        wait(for: [first], timeout: 3)
        let next = expectation(description: "page two must report a fetch error")
        repository.searchPage(filter: BillFilter(query: "환경"), page: 2) { result in
            if case .success = result { XCTFail("A cached first page cannot impersonate page two") }
            next.fulfill()
        }
        wait(for: [next], timeout: 3)
    }
}

private final class SearchPageURLProtocol: URLProtocol {
    static var data = Data()
    static var status = 200
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: Self.status, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Self.data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() {}
}

extension SearchFilterRegressionTests {
    func testMultipleFilteredEmptyPagesContinueWithoutAScroll() {
        let repository = MockBillRepository(dashboardResult: .success(HomeDashboard()))
        repository.pageOverrides[1] = .success(BillSearchPage(snapshots: [], hasMore: true))
        repository.pageOverrides[2] = .success(BillSearchPage(snapshots: [], hasMore: true))
        repository.pageOverrides[3] = .success(BillSearchPage(snapshots: [BillSnapshot(billID: "FOUND", age: 22, title: "환경")], hasMore: false))
        let model = SearchViewModel(repository: repository)
        let done = expectation(description: "third page match")
        model.onStateChange = { if case .loaded(let values) = $0 {
            XCTAssertEqual(values.map(\.billID), ["FOUND"])
            done.fulfill()
        } }
        model.search(query: "환경")
        wait(for: [done], timeout: 3)
        XCTAssertEqual(repository.searchRequests.map { $0.1 }, [1, 2, 3])
    }

    func testFinalEmptyPageEndsTheSearchOnlyOnce() {
        let repository = MockBillRepository(dashboardResult: .success(HomeDashboard()))
        repository.pageOverrides[1] = .success(BillSearchPage(snapshots: [], hasMore: true))
        repository.pageOverrides[2] = .success(BillSearchPage(snapshots: [], hasMore: false))
        let model = SearchViewModel(repository: repository)
        let done = expectation(description: "confirmed no matches")
        model.onStateChange = { if case .empty = $0 { done.fulfill() } }
        model.search(query: "환경")
        wait(for: [done], timeout: 3)
        XCTAssertFalse(model.canLoadMore)
        model.loadNextPageIfNeeded()
        XCTAssertEqual(repository.searchRequests.count, 2)
    }

    func testPagesDeduplicateAndSortTheAccumulatedResults() {
        let repository = MockBillRepository(dashboardResult: .success(HomeDashboard()))
        let a = BillSnapshot(billID: "A", age: 22, title: "환경", proposedDate: "2026-03-01")
        let b = BillSnapshot(billID: "B", age: 22, title: "환경", proposedDate: "2026-01-01")
        repository.pageOverrides[1] = .success(BillSearchPage(snapshots: [a], hasMore: true))
        repository.pageOverrides[2] = .success(BillSearchPage(snapshots: [a, b], hasMore: false))
        let model = SearchViewModel(repository: repository)
        model.updateFilter(BillFilter(query: "환경", sortOrder: .oldest))
        let done = expectation(description: "deduplicated sorted pages")
        model.onStateChange = { if case .loaded(let values) = $0 {
            if values.count == 1 { model.loadNextPageIfNeeded() }
            else { XCTAssertEqual(values.map(\.billID), ["B", "A"]); done.fulfill() }
        } }
        model.search()
        wait(for: [done], timeout: 3)
    }
}

private final class MockSearchRequest: SearchRequestCancelling {
    private(set) var cancelled = false
    func cancel() { cancelled = true }
}

extension SearchFilterRegressionTests {
    func testSupersededAndClearedRequestsAreCancelled() {
        let repository = MockBillRepository(dashboardResult: .success(HomeDashboard()))
        repository.holdSearch = true
        let model = SearchViewModel(repository: repository)
        model.search(query: "이전")
        model.search(query: "현재")
        XCTAssertTrue(repository.requestHandles[0].cancelled)
        XCTAssertFalse(repository.requestHandles[1].cancelled)
        model.clearResults()
        XCTAssertTrue(repository.requestHandles[1].cancelled)
    }
}

extension SearchFilterRegressionTests {
    @MainActor
    func testFilterFormKeepsActionsInsideSmallAndWideLayouts() throws {
        for size in [CGSize(width: 320, height: 568), CGSize(width: 760, height: 390), CGSize(width: 768, height: 1024)] {
            let editor = SearchFilterViewController(filter: BillFilter())
            let previousKey = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }.flatMap(\.windows).first(where: \.isKeyWindow)
            let window = UIWindow(frame: CGRect(origin: .zero, size: size))
            window.rootViewController = editor
            window.makeKeyAndVisible()
            defer { window.isHidden = true; window.rootViewController = nil; previousKey?.makeKey() }
            editor.loadViewIfNeeded()
            let form = try XCTUnwrap(editor.view as? SearchFilterView)
            form.frame = CGRect(origin: .zero, size: size)
            window.layoutIfNeeded()
            form.setNeedsLayout()
            form.layoutIfNeeded()
            XCTAssertGreaterThanOrEqual(form.applyButton.bounds.height, 44)
            XCTAssertGreaterThanOrEqual(form.resetButton.bounds.height, 44)
            let applyFrame = form.applyButton.convert(form.applyButton.bounds, to: form)
            XCTAssertGreaterThanOrEqual(applyFrame.minY, form.tableView.frame.maxY)
            XCTAssertLessThanOrEqual(applyFrame.maxY, form.bounds.maxY)
            XCTAssertGreaterThan(form.tableView.bounds.height, 0)
        }
    }

    @MainActor
    func testSelectedFilterRowsExposeSelectedAccessibilityTraits() throws {
        let editor = SearchFilterViewController(filter: BillFilter(status: .committee, favoriteOnly: true))
        editor.loadViewIfNeeded()
        let form = try XCTUnwrap(editor.view as? SearchFilterView)
        let selected = editor.tableView(form.tableView, cellForRowAt: IndexPath(row: 2, section: 0))
        XCTAssertEqual(selected.accessoryType, .checkmark)
        XCTAssertTrue(selected.accessibilityTraits.contains(.selected))
        let other = editor.tableView(form.tableView, cellForRowAt: IndexPath(row: 0, section: 0))
        XCTAssertFalse(other.accessibilityTraits.contains(.selected))
    }
}
