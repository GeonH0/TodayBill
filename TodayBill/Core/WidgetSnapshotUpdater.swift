import Foundation
import WidgetKit

/// All in-app read/modify/write operations share a lock; the extension only reads.
enum WidgetSnapshotUpdater {
    private static let store = WidgetSnapshotStore()
    private static let lock = NSLock()

    static func updateFavorites(_ favorites: [BillSnapshot], refreshedIDs: Set<String> = []) {
        update(favorites: favorites, refreshedIDs: refreshedIDs)
    }

    static func updateTodayProposalCount(_ count: Int, for date: Date = Date(), refreshedAt: Date = Date()) {
        update(todayProposalCount: count, proposalDate: date, proposalsUpdatedAt: refreshedAt)
    }

    static func updateDashboard(_ dashboard: HomeDashboard, now: Date = Date()) {
        guard !dashboard.failedSections.contains(.newProposals),
              let count = dashboard.todayProposalCount,
              let date = dashboard.todayProposalDate,
              let refreshedAt = dashboard.todayProposalsUpdatedAt,
              Calendar.current.isDate(date, inSameDayAs: now) else { return }
        updateTodayProposalCount(count, for: date, refreshedAt: refreshedAt)
    }

    private static func update(favorites: [BillSnapshot]? = nil, refreshedIDs: Set<String> = [],
                               todayProposalCount: Int? = nil, proposalDate: Date? = nil,
                               proposalsUpdatedAt: Date? = nil) {
        lock.lock()
        let previous = store.read()
        if let incoming = proposalsUpdatedAt, let stored = previous?.proposalsUpdatedAt, incoming < stored {
            lock.unlock()
            return
        }
        let snapshot = WidgetSnapshotBuilder.make(
            previous: previous, favorites: favorites, todayProposalCount: todayProposalCount,
            now: Date(), refreshedFavoriteIDs: refreshedIDs,
            proposalDate: proposalDate, proposalsUpdatedAt: proposalsUpdatedAt
        )
        let written = store.write(snapshot)
        lock.unlock()
        if written { WidgetCenter.shared.reloadTimelines(ofKind: BillWidgetSnapshot.kind) }
    }
}
