import CoreData
import Foundation

struct Bills: Codable {
    let nzmimeepazxkubdpn: [Nzmimeepazxkubdpn]
}

struct Nzmimeepazxkubdpn: Codable {
    let head: [Head]?
    let row: [Row]?
}

struct Head: Codable {
    let list_total_count: Int?
    let RESULT: APIResult?
}

struct APIResult: Codable {
    let CODE: String
    let MESSAGE: String?
}

struct Row: Codable {
    let BILL_ID: String
    let BILL_NO: String
    let BILL_NAME: String
    let COMMITTEE: String?
    let PROPOSE_DT: String
    let PROC_RESULT: String?
    let AGE: String
    let DETAIL_LINK: String
    let PROPOSER: String
    let MEMBER_LIST: String
    let LAW_PROC_DT: String?
    let LAW_PRESENT_DT: String?
    let LAW_SUBMIT_DT: String?
    let CMT_PROC_RESULT_CD: String?
    let CMT_PROC_DT: String?
    let CMT_PRESENT_DT: String?
    let COMMITTEE_DT: String?
    let PROC_DT: String?
    let COMMITTEE_ID: String?
    let PUBL_PROPOSER: String?
    let LAW_PROC_RESULT_CD: String?
    let RST_PROPOSER: String?
    var favoriteInfo: FavoriteInfo
    
    enum CodingKeys: String, CodingKey {
        case BILL_ID, 
             BILL_NO,
             BILL_NAME,
             COMMITTEE,
             PROPOSE_DT,
             PROC_RESULT,
             AGE,
             DETAIL_LINK,
             PROPOSER,
             MEMBER_LIST,
             LAW_PROC_DT,
             LAW_PRESENT_DT,
             LAW_SUBMIT_DT, 
             CMT_PROC_RESULT_CD,
             CMT_PROC_DT,
             CMT_PRESENT_DT,
             COMMITTEE_DT,
             PROC_DT,
             COMMITTEE_ID,
             PUBL_PROPOSER,
             LAW_PROC_RESULT_CD,
             RST_PROPOSER
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        BILL_ID = try container.decode(String.self, forKey: .BILL_ID)
        BILL_NO = try container.decode(String.self, forKey: .BILL_NO)
        BILL_NAME = try container.decode(String.self, forKey: .BILL_NAME)
        COMMITTEE = try? container.decode(String.self, forKey: .COMMITTEE)
        PROPOSE_DT = try container.decode(String.self, forKey: .PROPOSE_DT)
        PROC_RESULT = try? container.decode(String.self, forKey: .PROC_RESULT)
        AGE = try container.decode(String.self, forKey: .AGE)
        DETAIL_LINK = try container.decode(String.self, forKey: .DETAIL_LINK)
        PROPOSER = try container.decode(String.self, forKey: .PROPOSER)
        MEMBER_LIST = try container.decode(String.self, forKey: .MEMBER_LIST)
        LAW_PROC_DT = try? container.decode(String.self, forKey: .LAW_PROC_DT)
        LAW_PRESENT_DT = try? container.decode(String.self, forKey: .LAW_PRESENT_DT)
        LAW_SUBMIT_DT = try? container.decode(String.self, forKey: .LAW_SUBMIT_DT)
        CMT_PROC_RESULT_CD = try? container.decode(String.self, forKey: .CMT_PROC_RESULT_CD)
        CMT_PROC_DT = try? container.decode(String.self, forKey: .CMT_PROC_DT)
        CMT_PRESENT_DT = try? container.decode(String.self, forKey: .CMT_PRESENT_DT)
        COMMITTEE_DT = try? container.decode(String.self, forKey: .COMMITTEE_DT)
        PROC_DT = try? container.decode(String.self, forKey: .PROC_DT)
        COMMITTEE_ID = try? container.decode(String.self, forKey: .COMMITTEE_ID)
        PUBL_PROPOSER = try? container.decode(String.self, forKey: .PUBL_PROPOSER)
        LAW_PROC_RESULT_CD = try? container.decode(String.self, forKey: .LAW_PROC_RESULT_CD)
        RST_PROPOSER = try? container.decode(String.self, forKey: .RST_PROPOSER)
        favoriteInfo = FavoriteInfo(isFavorite: false)
    }
}

struct FavoriteInfo: Codable {
    var isFavorite: Bool
}

extension Row {
    func toBillEntity(context: NSManagedObjectContext) -> BillEntity {
        let entity = BillEntity(context: context)
        let snapshot = BillSnapshot(row: self)
        entity.apply(snapshot: snapshot, preservingUserFields: false)
        return entity
    }
}

enum ViewState<Value> {
    case idle
    case loading(String)
    case loaded(Value)
    case empty(String)
    case error(String)
}

enum HomeDashboardSection: String, Codable, CaseIterable {
    case newProposals
    case stageChanges
    case hotBills
    case lawEnforcements
    case selectedDateBills

    var title: String {
        switch self {
        case .newProposals:
            return "오늘 새로 발의"
        case .stageChanges:
            return "진행 변경"
        case .hotBills:
            return "주목할 법안"
        case .lawEnforcements:
            return "시행 예정/최근 시행"
        case .selectedDateBills:
            return "선택 날짜 법안"
        }
    }
}

struct HomeDashboard: Codable, Equatable {
    var newProposals: [BillSnapshot]
    var stageChanges: [BillSnapshot]
    var hotBills: [HotBillSnapshot]
    var lawEnforcements: [LawEnforcementSnapshot]
    var selectedDateBills: [BillSnapshot]
    var updatedAt: Date
    var isUsingCache: Bool
    var failedSections: [HomeDashboardSection]

    init(
        newProposals: [BillSnapshot] = [],
        stageChanges: [BillSnapshot] = [],
        hotBills: [HotBillSnapshot] = [],
        lawEnforcements: [LawEnforcementSnapshot] = [],
        selectedDateBills: [BillSnapshot] = [],
        updatedAt: Date = Date(),
        isUsingCache: Bool = false,
        failedSections: [HomeDashboardSection] = []
    ) {
        self.newProposals = newProposals
        self.stageChanges = stageChanges
        self.hotBills = hotBills
        self.lawEnforcements = lawEnforcements
        self.selectedDateBills = selectedDateBills
        self.updatedAt = updatedAt
        self.isUsingCache = isUsingCache
        self.failedSections = failedSections
    }

    var hasVisibleContent: Bool {
        !newProposals.isEmpty ||
            !stageChanges.isEmpty ||
            !hotBills.isEmpty ||
            !lawEnforcements.isEmpty ||
            !selectedDateBills.isEmpty
    }

    var updateFailed: Bool {
        isUsingCache || !failedSections.isEmpty
    }
}

enum HotBillReason: String, Codable, CaseIterable {
    case recentlyProposed
    case manyCosponsors
    case keywordMatch
    case plenarySoon
    case fastProgress
    case trackedCommittee

    var title: String {
        switch self {
        case .recentlyProposed:
            return "최근 발의"
        case .manyCosponsors:
            return "공동발의 많음"
        case .keywordMatch:
            return "관심 키워드"
        case .plenarySoon:
            return "본회의 임박"
        case .fastProgress:
            return "진행 빠름"
        case .trackedCommittee:
            return "관심 위원회"
        }
    }
}

struct HotBillSnapshot: Codable, Equatable, Identifiable {
    var bill: BillSnapshot
    var score: Int
    var reasons: [HotBillReason]

    var id: String { bill.billID }
}

struct LawEnforcementSnapshot: Codable, Equatable, Identifiable {
    var lawID: String
    var mst: String
    var lawName: String
    var promulgationDate: String?
    var enforcementDate: String
    var ministry: String?
    var lawType: String?
    var detailURL: URL?
    var matchedBillID: String?
    var updatedAt: Date

    var id: String {
        mst.isEmpty ? lawID : mst
    }
}

struct LawEnforcementDateRange: Equatable {
    var start: Date
    var end: Date

    static func aroundToday(
        pastDays: Int = 30,
        futureDays: Int = 90,
        calendar: Calendar = .current
    ) -> LawEnforcementDateRange {
        let now = Date()
        let start = calendar.date(byAdding: .day, value: -pastDays, to: now) ?? now
        let end = calendar.date(byAdding: .day, value: futureDays, to: now) ?? now
        return LawEnforcementDateRange(start: start, end: end)
    }
}

struct HotBillScoringContext {
    var now: Date
    var recentSearchTerms: [String]
    var trackedCommittees: [String]
    var favoriteBillIDs: Set<String>

    init(
        now: Date = Date(),
        recentSearchTerms: [String] = [],
        trackedCommittees: [String] = [],
        favoriteBillIDs: Set<String> = []
    ) {
        self.now = now
        self.recentSearchTerms = recentSearchTerms
        self.trackedCommittees = trackedCommittees
        self.favoriteBillIDs = favoriteBillIDs
    }
}

enum BillStage: String, Codable, CaseIterable {
    case proposed
    case committee
    case lawReview
    case plenary
    case completed
    case unknown

    var title: String {
        switch self {
        case .proposed:
            return "제안"
        case .committee:
            return "위원회"
        case .lawReview:
            return "법사위"
        case .plenary:
            return "본회의"
        case .completed:
            return "완료"
        case .unknown:
            return "상태 미확인"
        }
    }
}

enum BillSortOrder: String, Codable {
    case latest
    case oldest

    var title: String {
        switch self {
        case .latest:
            return "최신순"
        case .oldest:
            return "오래된순"
        }
    }
}

struct BillDateRange: Codable, Equatable {
    var start: Date?
    var end: Date?

    static let all = BillDateRange(start: nil, end: nil)

    static func recent(days: Int, calendar: Calendar = .current) -> BillDateRange {
        let end = Date()
        return BillDateRange(start: calendar.date(byAdding: .day, value: -days, to: end), end: end)
    }

    var title: String {
        switch (start, end) {
        case (nil, nil):
            return "전체 기간"
        case let (start?, nil):
            return "\(Self.displayFormatter.string(from: start)) 이후"
        case let (nil, end?):
            return "\(Self.displayFormatter.string(from: end)) 이전"
        case let (start?, end?):
            return "\(Self.displayFormatter.string(from: start))-\(Self.displayFormatter.string(from: end))"
        }
    }

    private static let displayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy.MM.dd"
        return formatter
    }()
}

struct BillFilter: Codable, Equatable {
    var query: String
    var dateRange: BillDateRange
    var status: BillStage?
    var committee: String?
    var favoriteOnly: Bool
    var sortOrder: BillSortOrder

    init(
        query: String = "",
        dateRange: BillDateRange = .all,
        status: BillStage? = nil,
        committee: String? = nil,
        favoriteOnly: Bool = false,
        sortOrder: BillSortOrder = .latest
    ) {
        self.query = query
        self.dateRange = dateRange
        self.status = status
        self.committee = committee
        self.favoriteOnly = favoriteOnly
        self.sortOrder = sortOrder
    }

    var normalizedQuery: String {
        query.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var activeSummary: String {
        var parts: [String] = []
        if let status {
            parts.append(status.title)
        }
        if favoriteOnly {
            parts.append("즐겨찾기")
        }
        if let committee = committee?.trimmingCharacters(in: .whitespacesAndNewlines),
           !committee.isEmpty {
            parts.append("위원회: \(committee)")
        }
        if dateRange != .all {
            parts.append(dateRange.title)
        }
        parts.append(sortOrder.title)
        return parts.joined(separator: " · ")
    }
}

enum HotBillScorer {
    static func rank(
        _ snapshots: [BillSnapshot],
        limit: Int,
        context: HotBillScoringContext = HotBillScoringContext()
    ) -> [HotBillSnapshot] {
        snapshots
            .map { score($0, context: context) }
            .filter { $0.score > 0 }
            .sorted { left, right in
                if left.score == right.score {
                    let leftDate = left.bill.proposedDateValue ?? .distantPast
                    let rightDate = right.bill.proposedDateValue ?? .distantPast
                    return leftDate == rightDate ? left.bill.title < right.bill.title : leftDate > rightDate
                }
                return left.score > right.score
            }
            .prefix(limit)
            .map { $0 }
    }

    static func score(
        _ snapshot: BillSnapshot,
        context: HotBillScoringContext = HotBillScoringContext(),
        calendar: Calendar = .current
    ) -> HotBillSnapshot {
        var score = 0
        var reasons: [HotBillReason] = []

        if let proposedDate = snapshot.proposedDateValue,
           let recentBoundary = calendar.date(byAdding: .day, value: -14, to: context.now),
           proposedDate >= recentBoundary {
            score += 30
            reasons.append(.recentlyProposed)
        }

        switch snapshot.stage {
        case .proposed:
            score += 4
        case .committee:
            score += 12
        case .lawReview:
            score += 22
            reasons.append(.fastProgress)
        case .plenary:
            score += 32
            reasons.append(.plenarySoon)
        case .completed:
            score += 16
        case .unknown:
            break
        }

        let cosponsorCount = snapshot.cosponsorCount
        if cosponsorCount >= 20 {
            score += min(30, 10 + cosponsorCount / 2)
            reasons.append(.manyCosponsors)
        } else if cosponsorCount >= 10 {
            score += 10
            reasons.append(.manyCosponsors)
        }

        if matchesKeyword(snapshot, keywords: context.recentSearchTerms) {
            score += 18
            reasons.append(.keywordMatch)
        }

        if context.favoriteBillIDs.contains(snapshot.billID) {
            score += 8
        }

        if matchesTrackedCommittee(snapshot, committees: context.trackedCommittees) {
            score += 14
            reasons.append(.trackedCommittee)
        }

        var uniqueReasons: [HotBillReason] = []
        reasons.forEach { reason in
            if !uniqueReasons.contains(reason) {
                uniqueReasons.append(reason)
            }
        }

        return HotBillSnapshot(
            bill: snapshot,
            score: score,
            reasons: uniqueReasons
        )
    }

    private static func matchesKeyword(_ snapshot: BillSnapshot, keywords: [String]) -> Bool {
        let haystack = [
            snapshot.title,
            snapshot.billNo,
            snapshot.proposer ?? "",
            snapshot.committee ?? ""
        ]
        .joined(separator: " ")
        .lowercased()

        return keywords
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .contains { haystack.contains($0) }
    }

    private static func matchesTrackedCommittee(_ snapshot: BillSnapshot, committees: [String]) -> Bool {
        guard let committee = BillSnapshot.nonEmpty(snapshot.committee)?.lowercased() else { return false }
        return committees
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() }
            .filter { !$0.isEmpty }
            .contains { committee.contains($0) || $0.contains(committee) }
    }
}

enum BillLawNameNormalizer {
    static func normalizedKey(_ value: String) -> String {
        var normalized = value
            .replacingOccurrences(of: "\\([^)]*\\)", with: "", options: .regularExpression)
            .replacingOccurrences(of: "\\[[^]]*\\]", with: "", options: .regularExpression)

        let removablePhrases = [
            "일부개정법률안",
            "전부개정법률안",
            "일부개정법률",
            "전부개정법률",
            "제정법률안",
            "제정법률",
            "개정법률안",
            "개정법률",
            "폐지법률안",
            "폐지법률",
            "법률안",
            "법률"
        ]

        removablePhrases.forEach {
            normalized = normalized.replacingOccurrences(of: $0, with: "")
        }

        normalized = normalized
            .replacingOccurrences(of: "[^가-힣A-Za-z0-9]", with: "", options: .regularExpression)
            .lowercased()

        return normalized
    }
}

enum LawBillMatcher {
    static func match(
        lawEnforcements: [LawEnforcementSnapshot],
        bills: [BillSnapshot]
    ) -> [LawEnforcementSnapshot] {
        let keyedBills = Dictionary(grouping: bills) { BillLawNameNormalizer.normalizedKey($0.title) }

        return lawEnforcements.map { law in
            var updated = law
            guard updated.matchedBillID == nil else { return updated }

            let lawKey = BillLawNameNormalizer.normalizedKey(law.lawName)
            if let exactMatch = keyedBills[lawKey]?.first {
                updated.matchedBillID = exactMatch.billID
                return updated
            }

            let bestMatch = bills
                .map { bill -> (bill: BillSnapshot, score: Int) in
                    let billKey = BillLawNameNormalizer.normalizedKey(bill.title)
                    return (bill, similarityScore(left: lawKey, right: billKey))
                }
                .filter { $0.score >= 70 }
                .sorted { $0.score > $1.score }
                .first

            updated.matchedBillID = bestMatch?.bill.billID
            return updated
        }
    }

    private static func similarityScore(left: String, right: String) -> Int {
        guard !left.isEmpty, !right.isEmpty else { return 0 }
        if left == right { return 100 }
        if left.contains(right) || right.contains(left) {
            let shorter = min(left.count, right.count)
            let longer = max(left.count, right.count)
            return Int(Double(shorter) / Double(longer) * 100.0)
        }

        let leftSet = Set(left)
        let rightSet = Set(right)
        let intersection = leftSet.intersection(rightSet).count
        let union = leftSet.union(rightSet).count
        guard union > 0 else { return 0 }
        return Int(Double(intersection) / Double(union) * 100.0)
    }
}

struct BillSummary: Codable, Equatable {
    var proposalReason: String
    var keyContent: String
    var rawText: String

    static func split(rawText: String) -> BillSummary {
        let processedText = rawText
            .replacingOccurrences(of: "(?<=\\.)\\s+", with: "\n", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let range = processedText.range(of: "주요내용") {
            let proposalReason = String(processedText[..<range.lowerBound])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let keyContent = String(processedText[range.upperBound...])
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return BillSummary(
                proposalReason: proposalReason.isEmpty ? "제안 이유 정보가 없습니다." : proposalReason,
                keyContent: keyContent.isEmpty ? "주요 내용 정보가 없습니다." : keyContent,
                rawText: processedText
            )
        }

        return BillSummary(
            proposalReason: processedText.isEmpty ? "요약 정보가 없습니다." : processedText,
            keyContent: "원문에서 주요 내용을 분리하지 못했습니다.",
            rawText: processedText
        )
    }
}

struct BillSnapshot: Codable, Equatable, Identifiable {
    let billID: String
    let age: Int
    let billNo: String
    let title: String
    let proposedDate: String
    let detailLink: String
    var proposer: String?
    var memberList: String?
    var committee: String?
    var procResult: String?
    var lawProcDate: String?
    var lawPresentDate: String?
    var lawSubmitDate: String?
    var committeeDate: String?
    var committeePresentDate: String?
    var committeeProcessDate: String?
    var plenaryDate: String?
    var lawProcResultCode: String?
    var committeeResultCode: String?
    var summaryProposalReason: String?
    var summaryKeyContent: String?
    var summaryFetchedAt: Date?
    var isFavorite: Bool
    var favoriteCreatedAt: Date?
    var lastSeenStageKey: String?
    var updatedAt: Date?

    var id: String { billID }

    init(
        billID: String,
        age: Int,
        billNo: String = "",
        title: String,
        proposedDate: String = "",
        detailLink: String = "",
        proposer: String? = nil,
        memberList: String? = nil,
        committee: String? = nil,
        procResult: String? = nil,
        lawProcDate: String? = nil,
        lawPresentDate: String? = nil,
        lawSubmitDate: String? = nil,
        committeeDate: String? = nil,
        committeePresentDate: String? = nil,
        committeeProcessDate: String? = nil,
        plenaryDate: String? = nil,
        lawProcResultCode: String? = nil,
        committeeResultCode: String? = nil,
        summaryProposalReason: String? = nil,
        summaryKeyContent: String? = nil,
        summaryFetchedAt: Date? = nil,
        isFavorite: Bool = false,
        favoriteCreatedAt: Date? = nil,
        lastSeenStageKey: String? = nil,
        updatedAt: Date? = nil
    ) {
        self.billID = billID
        self.age = age
        self.billNo = billNo
        self.title = title
        self.proposedDate = proposedDate
        self.detailLink = detailLink
        self.proposer = proposer
        self.memberList = memberList
        self.committee = committee
        self.procResult = procResult
        self.lawProcDate = lawProcDate
        self.lawPresentDate = lawPresentDate
        self.lawSubmitDate = lawSubmitDate
        self.committeeDate = committeeDate
        self.committeePresentDate = committeePresentDate
        self.committeeProcessDate = committeeProcessDate
        self.plenaryDate = plenaryDate
        self.lawProcResultCode = lawProcResultCode
        self.committeeResultCode = committeeResultCode
        self.summaryProposalReason = summaryProposalReason
        self.summaryKeyContent = summaryKeyContent
        self.summaryFetchedAt = summaryFetchedAt
        self.isFavorite = isFavorite
        self.favoriteCreatedAt = favoriteCreatedAt
        self.lastSeenStageKey = lastSeenStageKey
        self.updatedAt = updatedAt
    }

    init(row: Row) {
        self.init(
            billID: row.BILL_ID,
            age: Int(row.AGE) ?? 0,
            billNo: row.BILL_NO,
            title: row.BILL_NAME,
            proposedDate: row.PROPOSE_DT,
            detailLink: row.DETAIL_LINK,
            proposer: BillSnapshot.nonEmpty(row.PROPOSER),
            memberList: BillSnapshot.nonEmpty(row.MEMBER_LIST),
            committee: BillSnapshot.nonEmpty(row.COMMITTEE),
            procResult: BillSnapshot.nonEmpty(row.PROC_RESULT),
            lawProcDate: BillSnapshot.nonEmpty(row.LAW_PROC_DT),
            lawPresentDate: BillSnapshot.nonEmpty(row.LAW_PRESENT_DT),
            lawSubmitDate: BillSnapshot.nonEmpty(row.LAW_SUBMIT_DT),
            committeeDate: BillSnapshot.nonEmpty(row.COMMITTEE_DT),
            committeePresentDate: BillSnapshot.nonEmpty(row.CMT_PRESENT_DT),
            committeeProcessDate: BillSnapshot.nonEmpty(row.CMT_PROC_DT),
            plenaryDate: BillSnapshot.nonEmpty(row.PROC_DT),
            lawProcResultCode: BillSnapshot.nonEmpty(row.LAW_PROC_RESULT_CD),
            committeeResultCode: BillSnapshot.nonEmpty(row.CMT_PROC_RESULT_CD),
            isFavorite: row.favoriteInfo.isFavorite,
            updatedAt: Date()
        )
    }

    init(entity: BillEntity) {
        self.init(
            billID: entity.id ?? "",
            age: Int(entity.age),
            billNo: entity.billNo ?? "",
            title: entity.title ?? "",
            proposedDate: entity.date ?? "",
            detailLink: entity.detailLink ?? "",
            proposer: entity.proposer,
            memberList: entity.memberList,
            committee: entity.committee,
            procResult: entity.procResult,
            lawProcDate: entity.lawProcDate,
            lawPresentDate: entity.lawPresentDate,
            lawSubmitDate: entity.lawSubmitDate,
            committeeDate: entity.committeeDate,
            committeePresentDate: entity.committeePresentDate,
            committeeProcessDate: entity.committeeProcessDate,
            plenaryDate: entity.plenaryDate,
            lawProcResultCode: entity.lawProcResultCode,
            committeeResultCode: entity.committeeResultCode,
            summaryProposalReason: entity.summaryProposalReason,
            summaryKeyContent: entity.summaryKeyContent,
            summaryFetchedAt: entity.summaryFetchedAt,
            isFavorite: entity.isFavorite,
            favoriteCreatedAt: entity.favoriteCreatedAt,
            lastSeenStageKey: entity.lastSeenStageKey,
            updatedAt: entity.updatedAt
        )
    }

    var stage: BillStage {
        if Self.nonEmpty(procResult) != nil {
            return .completed
        }
        if Self.nonEmpty(plenaryDate) != nil {
            return .plenary
        }
        if Self.nonEmpty(lawProcDate) != nil ||
            Self.nonEmpty(lawPresentDate) != nil ||
            Self.nonEmpty(lawSubmitDate) != nil ||
            Self.nonEmpty(lawProcResultCode) != nil {
            return .lawReview
        }
        if Self.nonEmpty(committeeProcessDate) != nil ||
            Self.nonEmpty(committeePresentDate) != nil ||
            Self.nonEmpty(committeeDate) != nil ||
            Self.nonEmpty(committee) != nil {
            return .committee
        }
        if !proposedDate.isEmpty {
            return .proposed
        }
        return .unknown
    }

    var stageKey: String {
        [
            stage.rawValue,
            committeeDate,
            committeePresentDate,
            committeeProcessDate,
            committeeResultCode,
            lawSubmitDate,
            lawPresentDate,
            lawProcDate,
            lawProcResultCode,
            plenaryDate,
            procResult
        ]
        .compactMap { Self.nonEmpty($0) }
        .joined(separator: "|")
    }

    var hasUnseenStageChange: Bool {
        guard isFavorite, let lastSeenStageKey, !lastSeenStageKey.isEmpty else { return false }
        return lastSeenStageKey != stageKey
    }

    var proposedDateValue: Date? {
        Self.apiDateFormatter.date(from: proposedDate)
    }

    var displayProposer: String {
        guard let proposer = Self.nonEmpty(proposer) else { return "제안자 미확인" }
        let parts = proposer.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        guard parts.count > 1 else { return proposer }
        return "\(parts[0]) 외 \(parts.count - 1)인"
    }

    var displayCommittee: String {
        Self.nonEmpty(committee) ?? "위원회 미정"
    }

    var cosponsorCount: Int {
        if let memberList = Self.nonEmpty(memberList) {
            let separators = CharacterSet(charactersIn: ",;ㆍ·\n")
            let names = memberList
                .components(separatedBy: separators)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty && $0 != "-" }
            if names.count > 1 {
                return names.count
            }
        }

        let sources = [proposer, memberList].compactMap(Self.nonEmpty)
        for source in sources {
            if let count = Self.extractRepresentativeCount(from: source) {
                return count
            }
        }

        return Self.nonEmpty(proposer) == nil ? 0 : 1
    }

    func toStarredBill() -> StarredBill {
        StarredBill(ID: billID, age: age, name: title)
    }

    func matches(filter: BillFilter) -> Bool {
        let query = filter.normalizedQuery.lowercased()
        if !query.isEmpty {
            let searchable = [
                title,
                billNo,
                proposer ?? "",
                committee ?? ""
            ].joined(separator: " ").lowercased()
            guard searchable.contains(query) else { return false }
        }

        if let status = filter.status, stage != status {
            return false
        }

        if let committee = filter.committee?.trimmingCharacters(in: .whitespacesAndNewlines),
           !committee.isEmpty,
           displayCommittee.localizedCaseInsensitiveContains(committee) == false {
            return false
        }

        if filter.favoriteOnly && !isFavorite {
            return false
        }

        if filter.dateRange.start != nil || filter.dateRange.end != nil {
            guard let proposedDateValue else { return false }
            if let start = filter.dateRange.start, proposedDateValue < start {
                return false
            }
            if let end = filter.dateRange.end, proposedDateValue > end {
                return false
            }
        }

        return true
    }

    static func sort(_ snapshots: [BillSnapshot], order: BillSortOrder) -> [BillSnapshot] {
        snapshots.sorted { left, right in
            let leftDate = left.proposedDateValue ?? .distantPast
            let rightDate = right.proposedDateValue ?? .distantPast
            switch order {
            case .latest:
                return leftDate == rightDate ? left.title < right.title : leftDate > rightDate
            case .oldest:
                return leftDate == rightDate ? left.title < right.title : leftDate < rightDate
            }
        }
    }

    static func nonEmpty(_ value: String?) -> String? {
        guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines),
              !value.isEmpty,
              value != "-" else {
            return nil
        }
        return value
    }

    private static func extractRepresentativeCount(from value: String) -> Int? {
        let pattern = #"외\s*(\d+)\s*인|등\s*(\d+)\s*인"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(value.startIndex..<value.endIndex, in: value)
        guard let match = regex.firstMatch(in: value, range: range) else { return nil }

        for index in 1..<match.numberOfRanges {
            let matchRange = match.range(at: index)
            guard matchRange.location != NSNotFound,
                  let range = Range(matchRange, in: value),
                  let count = Int(value[range]) else {
                continue
            }
            return count + 1
        }
        return nil
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

struct BillTrackingSection {
    let title: String
    let snapshots: [BillSnapshot]
}

extension BillEntity {
    func apply(snapshot: BillSnapshot, preservingUserFields: Bool = true) {
        let previousFavorite = isFavorite
        let previousFavoriteCreatedAt = favoriteCreatedAt
        let previousLastSeenStageKey = lastSeenStageKey
        let previousProposalReason = summaryProposalReason
        let previousKeyContent = summaryKeyContent
        let previousSummaryFetchedAt = summaryFetchedAt

        id = snapshot.billID
        title = snapshot.title
        date = snapshot.proposedDate
        age = Int16(snapshot.age)
        billNo = snapshot.billNo
        detailLink = snapshot.detailLink
        proposer = snapshot.proposer
        memberList = snapshot.memberList
        committee = snapshot.committee
        procResult = snapshot.procResult
        lawProcDate = snapshot.lawProcDate
        lawPresentDate = snapshot.lawPresentDate
        lawSubmitDate = snapshot.lawSubmitDate
        committeeDate = snapshot.committeeDate
        committeePresentDate = snapshot.committeePresentDate
        committeeProcessDate = snapshot.committeeProcessDate
        plenaryDate = snapshot.plenaryDate
        lawProcResultCode = snapshot.lawProcResultCode
        committeeResultCode = snapshot.committeeResultCode
        updatedAt = snapshot.updatedAt ?? Date()

        if preservingUserFields {
            isFavorite = previousFavorite || snapshot.isFavorite
            favoriteCreatedAt = previousFavoriteCreatedAt ?? snapshot.favoriteCreatedAt
            lastSeenStageKey = previousLastSeenStageKey ?? snapshot.lastSeenStageKey
            summaryProposalReason = snapshot.summaryProposalReason ?? previousProposalReason
            summaryKeyContent = snapshot.summaryKeyContent ?? previousKeyContent
            summaryFetchedAt = snapshot.summaryFetchedAt ?? previousSummaryFetchedAt
        } else {
            isFavorite = snapshot.isFavorite
            favoriteCreatedAt = snapshot.favoriteCreatedAt
            lastSeenStageKey = snapshot.lastSeenStageKey
            summaryProposalReason = snapshot.summaryProposalReason
            summaryKeyContent = snapshot.summaryKeyContent
            summaryFetchedAt = snapshot.summaryFetchedAt
        }
    }
}
