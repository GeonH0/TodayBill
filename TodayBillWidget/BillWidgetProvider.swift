import WidgetKit

struct BillWidgetEntry: TimelineEntry {
    let date: Date
    /// nil이면 앱이 아직 스냅샷을 한 번도 쓰지 않았다는 뜻이다.
    let snapshot: BillWidgetSnapshot?
}

struct BillWidgetProvider: TimelineProvider {
    private let store = WidgetSnapshotStore()

    func placeholder(in context: Context) -> BillWidgetEntry {
        BillWidgetEntry(date: Date(), snapshot: Self.sample)
    }

    func getSnapshot(in context: Context, completion: @escaping (BillWidgetEntry) -> Void) {
        let value = context.isPreview ? Self.sample : store.read()
        completion(BillWidgetEntry(date: Date(), snapshot: value))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<BillWidgetEntry>) -> Void) {
        let now = Date()
        let snapshot = store.read()
        // Midnight invalidates yesterday's count even if the next reload is delayed.
        let dates = [now] + (snapshot?.refreshBoundaries(after: now) ?? [])
        let entries = dates.map { BillWidgetEntry(date: $0, snapshot: snapshot) }
        completion(Timeline(entries: entries, policy: .after(now.addingTimeInterval(60 * 60))))
    }

    /// 갤러리와 프리뷰에서 쓰는 예시. 실제 데이터가 아니다.
    static let sample = BillWidgetSnapshot(
        generatedAt: Date(),
        favoriteCount: 7,
        rows: [
            BillWidgetSnapshot.Row(billID: "1", age: 22, title: "종합부동산세법 일부개정법률안", stageTitle: "위원회", hasChange: true),
            BillWidgetSnapshot.Row(billID: "2", age: 22, title: "부동산등기법 일부개정법률안", stageTitle: "법사위", hasChange: true),
            BillWidgetSnapshot.Row(billID: "3", age: 22, title: "주택임대차보호법 일부개정법률안", stageTitle: "제안", hasChange: false),
            BillWidgetSnapshot.Row(billID: "4", age: 22, title: "건축법 일부개정법률안", stageTitle: "위원회", hasChange: false),
            BillWidgetSnapshot.Row(billID: "5", age: 22, title: "도시 및 주거환경정비법 일부개정법률안", stageTitle: "본회의", hasChange: false)
        ],
        changeCount: 3,
        todayProposalCount: 37, favoritesUpdatedAt: Date(), proposalDate: Date(), proposalsUpdatedAt: Date()
    )
}
