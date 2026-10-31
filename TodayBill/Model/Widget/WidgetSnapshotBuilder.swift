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
        let changes: [BillWidgetSnapshot.Change]
        let changeCount: Int
        let favoriteCount: Int

        if let favorites {
            let changed = favorites.filter(\.hasUnseenStageChange)
            changes = changed.prefix(BillWidgetSnapshot.maxChanges).map {
                BillWidgetSnapshot.Change(
                    billID: $0.billID,
                    age: $0.age,
                    title: $0.title,
                    stageTitle: $0.stage.title
                )
            }
            changeCount = changed.count
            favoriteCount = favorites.count
        } else {
            changes = previous?.changes ?? []
            changeCount = previous?.changeCount ?? 0
            favoriteCount = previous?.favoriteCount ?? 0
        }

        return BillWidgetSnapshot(
            generatedAt: now,
            favoriteCount: favoriteCount,
            changes: changes,
            changeCount: changeCount,
            todayProposalCount: todayProposalCount ?? previous?.todayProposalCount ?? 0
        )
    }
}
