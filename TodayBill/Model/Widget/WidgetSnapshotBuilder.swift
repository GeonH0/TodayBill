import Foundation

/// Pure projection. nil inputs carry previous values, never turn unknown data into zero.
enum WidgetSnapshotBuilder {
    static func make(
        previous: BillWidgetSnapshot?,
        favorites: [BillSnapshot]?,
        todayProposalCount: Int?,
        now: Date,
        refreshedFavoriteIDs: Set<String> = [],
        proposalDate: Date? = nil,
        proposalsUpdatedAt: Date? = nil,
        clearProposalCount: Bool = false
    ) -> BillWidgetSnapshot {
        let rows: [BillWidgetSnapshot.Row]
        let changeCount: Int
        let favoriteCount: Int?
        let favoritesUpdatedAt: Date?
        let refreshDates: [String: Date]?

        if let favorites {
            let changed = favorites.filter(\.hasUnseenStageChange)
            let unchanged = favorites.filter { !$0.hasUnseenStageChange }.sorted {
                let left = $0.favoriteCreatedAt ?? .distantPast
                let right = $1.favoriteCreatedAt ?? .distantPast
                return left == right ? $0.billID < $1.billID : left > right
            }
            rows = (changed + unchanged).prefix(BillWidgetSnapshot.maxRows).map {
                BillWidgetSnapshot.Row(billID: $0.billID, age: $0.age, title: $0.title,
                                       stageTitle: $0.stage.title, hasChange: $0.hasUnseenStageChange)
            }
            changeCount = changed.count
            favoriteCount = favorites.count
            let ids = Set(favorites.map(\.billID))
            var dates = (previous?.favoriteRefreshDates ?? [:]).filter { ids.contains($0.key) }
            for id in refreshedFavoriteIDs.intersection(ids) { dates[id] = now }
            refreshDates = dates
            // A partial refresh must not make failed/never-refreshed bills look fresh.
            favoritesUpdatedAt = ids.isEmpty ? now : (dates.count == ids.count ? dates.values.min() : nil)
        } else {
            rows = previous?.rows ?? []
            changeCount = previous?.changeCount ?? 0
            favoriteCount = previous?.favoriteCount
            favoritesUpdatedAt = previous?.favoritesUpdatedAt
            refreshDates = previous?.favoriteRefreshDates
        }

        return BillWidgetSnapshot(
            generatedAt: now, favoriteCount: favoriteCount, rows: rows, changeCount: changeCount,
            todayProposalCount: clearProposalCount ? nil : (todayProposalCount ?? previous?.todayProposalCount),
            favoritesUpdatedAt: favoritesUpdatedAt,
            proposalDate: todayProposalCount == nil && !clearProposalCount ? previous?.proposalDate : proposalDate,
            proposalsUpdatedAt: todayProposalCount == nil && !clearProposalCount ? previous?.proposalsUpdatedAt : proposalsUpdatedAt,
            favoriteRefreshDates: refreshDates
        )
    }
}
