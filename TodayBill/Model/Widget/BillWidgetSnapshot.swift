import Foundation

/// 위젯이 그리는 데 필요한 전부. 앱이 쓰고 위젯 익스텐션이 읽는다.
/// 위젯은 이 값 외에 어떤 저장소나 네트워크도 건드리지 않는다.
struct BillWidgetSnapshot: Codable, Equatable {
    /// 위젯 타임라인을 다시 불러올 때 쓰는 식별자.
    static let kind = "TodayBillStatusWidget"
    /// 큰 위젯이 담는 줄 수. 중간 위젯은 이 중 앞의 일부만 그린다.
    static let maxRows = 5

    /// 이 스냅샷을 만든 시각. 위젯이 신선도를 표시하는 데 쓴다.
    let generatedAt: Date
    /// 담아둔 법안 수. 0이면 "변동 없음"이 아니라 "담아둔 법안이 없음"이다.
    let favoriteCount: Int
    /// 담아둔 법안을 변동 있는 것부터 담는다. 최대 `maxRows`줄.
    let rows: [Row]
    /// 전체 변동 건수. 담긴 줄 수보다 클 수 있다.
    let changeCount: Int
    let todayProposalCount: Int

    struct Row: Codable, Equatable {
        let billID: String
        /// 상세 화면을 여는 데 필요하다. `DetailViewController(billID:age:)`는 둘 다 요구한다.
        let age: Int
        let title: String
        /// "위원회", "법사위" 등 — `BillStage.title`
        let stageTitle: String
        /// 확인하지 않은 단계 변동이 있는 줄. 위젯이 강조에 쓴다.
        let hasChange: Bool
    }
}
