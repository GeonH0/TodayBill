import Foundation

/// App-owned cache. File generation time is deliberately separate from source freshness.
struct BillWidgetSnapshot: Codable, Equatable {
    static let kind = "TodayBillStatusWidget"
    static let maxRows = 5
    static let stalenessThreshold: TimeInterval = 6 * 60 * 60

    let schemaVersion: Int
    let generatedAt: Date
    /// nil means favorites have not been read; zero is a confirmed empty list.
    let favoriteCount: Int?
    let rows: [Row]
    let changeCount: Int
    let todayProposalCount: Int?
    let favoritesUpdatedAt: Date?
    let proposalDate: Date?
    let proposalsUpdatedAt: Date?
    /// Only successful network refreshes advance these dates; local edits do not.
    let favoriteRefreshDates: [String: Date]?

    init(generatedAt: Date, favoriteCount: Int?, rows: [Row], changeCount: Int,
         todayProposalCount: Int?, favoritesUpdatedAt: Date? = nil,
         proposalDate: Date? = nil, proposalsUpdatedAt: Date? = nil,
         favoriteRefreshDates: [String: Date]? = nil) {
        self.schemaVersion = 2
        self.generatedAt = generatedAt
        self.favoriteCount = favoriteCount
        self.rows = rows
        self.changeCount = changeCount
        self.todayProposalCount = todayProposalCount
        self.favoritesUpdatedAt = favoritesUpdatedAt
        self.proposalDate = proposalDate
        self.proposalsUpdatedAt = proposalsUpdatedAt
        self.favoriteRefreshDates = favoriteRefreshDates
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, generatedAt, favoriteCount, rows, changeCount, todayProposalCount
        case favoritesUpdatedAt, proposalDate, proposalsUpdatedAt, favoriteRefreshDates
    }

    init(from decoder: Decoder) throws {
        let values = try decoder.container(keyedBy: CodingKeys.self)
        let version = try values.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
        self.init(
            generatedAt: try values.decode(Date.self, forKey: .generatedAt),
            // Version 1 could have invented zero or written a partial favorites list.
            favoriteCount: version >= 2 ? try values.decodeIfPresent(Int.self, forKey: .favoriteCount) : nil,
            rows: try values.decode([Row].self, forKey: .rows),
            changeCount: try values.decode(Int.self, forKey: .changeCount),
            todayProposalCount: try values.decodeIfPresent(Int.self, forKey: .todayProposalCount),
            favoritesUpdatedAt: try values.decodeIfPresent(Date.self, forKey: .favoritesUpdatedAt),
            proposalDate: try values.decodeIfPresent(Date.self, forKey: .proposalDate),
            proposalsUpdatedAt: try values.decodeIfPresent(Date.self, forKey: .proposalsUpdatedAt),
            favoriteRefreshDates: try values.decodeIfPresent([String: Date].self, forKey: .favoriteRefreshDates)
        )
    }

    /// Schedule source staleness and day rollover independently of file writes/reloads.
    func refreshBoundaries(after date: Date, calendar: Calendar = .current) -> [Date] {
        var dates = Set<Date>()
        for sourceDate in [favoritesUpdatedAt, proposalsUpdatedAt].compactMap({ $0 }) {
            let boundary = sourceDate.addingTimeInterval(Self.stalenessThreshold)
            if boundary > date { dates.insert(boundary) }
        }
        if proposalCount(on: date, calendar: calendar) != nil,
           let midnight = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: date)) {
            dates.insert(midnight)
        }
        return dates.sorted()
    }

    /// Older files without the new optional dates decode, but cannot invent today's count.
    func proposalCount(on date: Date, calendar: Calendar = .current) -> Int? {
        guard let proposalDate, calendar.isDate(proposalDate, inSameDayAs: date) else { return nil }
        return todayProposalCount
    }

    struct Row: Codable, Equatable {
        let billID: String
        let age: Int
        let title: String
        let stageTitle: String
        let hasChange: Bool

        var destinationURL: URL {
            guard age > 0, !billID.isEmpty, !billID.contains("/") else { return URL(string: "todaybill://favorites")! }
            var components = URLComponents()
            components.scheme = "todaybill"
            components.host = "bill"
            components.path = "/\(billID)"
            components.queryItems = [URLQueryItem(name: "age", value: String(age))]
            return components.url ?? URL(string: "todaybill://favorites")!
        }
    }
}
