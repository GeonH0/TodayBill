import Foundation

/// 위젯이 그리는 데 필요한 전부. 앱이 쓰고 위젯 익스텐션이 읽는다.
/// 위젯은 이 값 외에 어떤 저장소나 네트워크도 건드리지 않는다.
struct BillWidgetSnapshot: Codable, Equatable {
    /// 위젯 타임라인을 다시 불러올 때 쓰는 식별자.
    static let kind = "TodayBillStatusWidget"
    /// 중간 크기 위젯에 들어가는 법안 줄 수.
    static let maxChanges = 2

    /// 이 스냅샷을 만든 시각. 위젯이 신선도를 표시하는 데 쓴다.
    let generatedAt: Date
    /// 담아둔 법안 수. 0이면 "변동 없음"이 아니라 "담아둔 법안이 없음"이다.
    let favoriteCount: Int
    /// 표시할 변동. 최대 `maxChanges`건.
    let changes: [Change]
    /// 전체 변동 건수. `changes.count`보다 클 수 있다.
    let changeCount: Int
    let todayProposalCount: Int

    struct Change: Codable, Equatable {
        let billID: String
        /// 상세 화면을 여는 데 필요하다. `DetailViewController(billID:age:)`는 둘 다 요구한다.
        let age: Int
        let title: String
        /// "위원회", "법사위" 등 — `BillStage.title`
        let stageTitle: String
    }
}
