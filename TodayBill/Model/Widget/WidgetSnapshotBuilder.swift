import Foundation

/// 모델에서 위젯이 쓸 값만 뽑아낸다. 순수 함수라 위젯 타겟 없이도 검증할 수 있다.
enum WidgetSnapshotBuilder {
    /// `favorites`와 `todayProposalCount`는 서로 다른 시점에 갱신된다.
    /// `nil`은 "이번에 갱신된 값이 없으니 이전 스냅샷의 값을 유지하라"는 뜻이다.
    static func make(
        previous: BillWidgetSnapshot?,
        favorites: [BillSnapshot]?,
        todayProposalCount: Int?,
        now: Date
    ) -> BillWidgetSnapshot {
        let rows: [BillWidgetSnapshot.Row]
        let changeCount: Int
        let favoriteCount: Int

        if let favorites {
            let changed = favorites.filter(\.hasUnseenStageChange)
            // 변동이 있는 법안이 먼저. 남는 자리는 최근에 담은 법안으로 채워, 변동이 없는
            // 날에도 위젯이 빈 자리가 되지 않게 한다.
            let unchanged = favorites
                .filter { !$0.hasUnseenStageChange }
                .sorted {
                    ($0.favoriteCreatedAt ?? .distantPast) > ($1.favoriteCreatedAt ?? .distantPast)
                }
            rows = (changed + unchanged)
                .prefix(BillWidgetSnapshot.maxRows)
                .map {
                    BillWidgetSnapshot.Row(
                        billID: $0.billID,
                        age: $0.age,
                        title: $0.title,
                        stageTitle: $0.stage.title,
                        hasChange: $0.hasUnseenStageChange
                    )
                }
            changeCount = changed.count
            favoriteCount = favorites.count
        } else {
            rows = previous?.rows ?? []
            changeCount = previous?.changeCount ?? 0
            favoriteCount = previous?.favoriteCount ?? 0
        }

        return BillWidgetSnapshot(
            generatedAt: now,
            favoriteCount: favoriteCount,
            rows: rows,
            changeCount: changeCount,
            todayProposalCount: todayProposalCount ?? previous?.todayProposalCount ?? 0
        )
    }
}
