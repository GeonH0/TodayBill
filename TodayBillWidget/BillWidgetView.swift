import SwiftUI
import WidgetKit

struct BillWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: BillWidgetEntry

    /// 이보다 오래된 스냅샷은 하단에 상대 시각을 덧붙인다.
    static let stalenessThreshold: TimeInterval = 6 * 60 * 60
    /// 중간 위젯이 담는 줄 수. 큰 위젯은 `BillWidgetSnapshot.maxRows`까지 담는다.
    private static let mediumRowLimit = 2

    private var rowLimit: Int {
        family == .systemLarge ? BillWidgetSnapshot.maxRows : Self.mediumRowLimit
    }

    private var visibleRows: [BillWidgetSnapshot.Row] {
        Array((entry.snapshot?.rows ?? []).prefix(rowLimit))
    }

    private var changeCount: Int { entry.snapshot?.changeCount ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            header
            Divider()
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            Divider()
            footer
        }
        .padding(14)
        .widgetContainerBackground(WidgetTheme.background)
        .widgetURL(URL(string: changeCount > 0 ? "todaybill://favorites" : "todaybill://home"))
    }

    private var header: some View {
        HStack {
            Text("관심 법안")
                .font(.caption).fontWeight(.semibold)
                .foregroundColor(WidgetTheme.secondaryText)
            Spacer()
            Text(changeCount > 0 ? "\(changeCount)건 변동" : "변동 없음")
                .font(.caption2).fontWeight(.bold)
                .foregroundColor(changeCount > 0 ? WidgetTheme.accent : WidgetTheme.secondaryText)
        }
    }

    @ViewBuilder
    private var content: some View {
        if entry.snapshot == nil {
            message("앱을 한 번 열어주세요")
        } else if visibleRows.isEmpty {
            message("담아둔 법안이 없습니다")
        } else {
            VStack(alignment: .leading, spacing: 6) {
                ForEach(visibleRows, id: \.billID) { row in
                    rowView(row)
                }
                if changeCount > visibleRows.filter(\.hasChange).count {
                    Text("외 \(changeCount - visibleRows.filter(\.hasChange).count)건 변동")
                        .font(.caption2)
                        .foregroundColor(WidgetTheme.secondaryText)
                }
            }
        }
    }

    private func rowView(_ row: BillWidgetSnapshot.Row) -> some View {
        Link(destination: Self.detailURL(for: row)) {
            HStack(spacing: 6) {
                Circle()
                    .fill(row.hasChange ? WidgetTheme.accent : Color.clear)
                    .frame(width: 5, height: 5)
                Text(row.title)
                    .font(.caption)
                    .fontWeight(row.hasChange ? .semibold : .regular)
                    .foregroundColor(WidgetTheme.primaryText)
                    .lineLimit(1)
                    .truncationMode(.tail)
                Spacer(minLength: 4)
                Text(row.stageTitle)
                    .font(.caption2)
                    .foregroundColor(row.hasChange ? WidgetTheme.accent : WidgetTheme.secondaryText)
                    .layoutPriority(1)
            }
        }
    }

    /// 상세 화면은 billID와 age를 둘 다 요구한다.
    private static func detailURL(for row: BillWidgetSnapshot.Row) -> URL {
        var components = URLComponents()
        components.scheme = "todaybill"
        components.host = "bill"
        components.path = "/\(row.billID)"
        components.queryItems = [URLQueryItem(name: "age", value: String(row.age))]
        // 구성 요소가 모두 고정이라 실패할 수 없다.
        return components.url ?? URL(string: "todaybill://favorites")!
    }

    private func message(_ text: String) -> some View {
        Text(text)
            .font(.caption)
            .foregroundColor(WidgetTheme.secondaryText)
    }

    private var footer: some View {
        HStack(spacing: 4) {
            Text("오늘 발의 \(entry.snapshot?.todayProposalCount ?? 0)건")
                .font(.caption2)
                .foregroundColor(WidgetTheme.secondaryText)
            if let staleness {
                Text("· \(staleness)")
                    .font(.caption2)
                    .foregroundColor(WidgetTheme.secondaryText)
            }
            Spacer()
        }
    }

    /// 캐시만 보여주는 화면은 신선도를 밝혀야 한다.
    private var staleness: String? {
        guard let generatedAt = entry.snapshot?.generatedAt else { return nil }
        let age = entry.date.timeIntervalSince(generatedAt)
        guard age >= Self.stalenessThreshold else { return nil }
        return "\(Int(age / 3600))시간 전"
    }
}

// `#Preview` 매크로는 iOS 17+ 전용이라 16.4 타깃에서 컴파일되지 않는다.
// `PreviewProvider`는 iOS 14부터 쓸 수 있다.
struct BillWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview(BillWidgetProvider.sample, "변동 있음 · 중간", .systemMedium)
            preview(BillWidgetProvider.sample, "변동 있음 · 큰", .systemLarge)
            preview(noChanges, "변동 없음 · 중간", .systemMedium)
            preview(empty, "즐겨찾기 없음 · 중간", .systemMedium)
            preview(nil, "스냅샷 없음 · 중간", .systemMedium)
            preview(stale, "오래된 스냅샷 · 중간", .systemMedium)
        }
    }

    private static let noChanges = BillWidgetSnapshot(
        generatedAt: Date(),
        favoriteCount: 2,
        rows: [
            BillWidgetSnapshot.Row(billID: "1", age: 22, title: "주택임대차보호법 일부개정법률안", stageTitle: "제안", hasChange: false),
            BillWidgetSnapshot.Row(billID: "2", age: 22, title: "건축법 일부개정법률안", stageTitle: "위원회", hasChange: false)
        ],
        changeCount: 0,
        todayProposalCount: 37
    )

    private static let stale = BillWidgetSnapshot(
        generatedAt: Date().addingTimeInterval(-9 * 60 * 60),
        favoriteCount: 2,
        rows: noChanges.rows,
        changeCount: 0,
        todayProposalCount: 37
    )

    private static let empty = BillWidgetSnapshot(
        generatedAt: Date(), favoriteCount: 0, rows: [], changeCount: 0, todayProposalCount: 37
    )

    private static func preview(
        _ snapshot: BillWidgetSnapshot?,
        _ name: String,
        _ family: WidgetFamily
    ) -> some View {
        BillWidgetView(entry: BillWidgetEntry(date: Date(), snapshot: snapshot))
            .previewContext(WidgetPreviewContext(family: family))
            .previewDisplayName(name)
    }
}
