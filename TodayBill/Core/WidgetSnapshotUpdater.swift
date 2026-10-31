import Foundation
import WidgetKit

/// 앱의 갱신 지점에서 위젯 스냅샷을 다시 쓴다.
/// 실패는 삼킨다 — 위젯이 늦는 것이지 앱이 망가지는 것은 아니다.
enum WidgetSnapshotUpdater {
    private static let store = WidgetSnapshotStore()

    static func updateFavorites(_ favorites: [BillSnapshot]) {
        update(favorites: favorites, todayProposalCount: nil)
    }

    static func updateTodayProposalCount(_ count: Int) {
        update(favorites: nil, todayProposalCount: count)
    }

    private static func update(favorites: [BillSnapshot]?, todayProposalCount: Int?) {
        let snapshot = WidgetSnapshotBuilder.make(
            previous: store.read(),
            favorites: favorites,
            todayProposalCount: todayProposalCount,
            now: Date()
        )
        guard store.write(snapshot) else { return }
        WidgetCenter.shared.reloadTimelines(ofKind: BillWidgetSnapshot.kind)
    }
}
