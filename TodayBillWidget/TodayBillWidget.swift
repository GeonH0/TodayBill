//
//  TodayBillWidget.swift
//  TodayBillWidget
//

import SwiftUI
import WidgetKit

struct TodayBillWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: BillWidgetSnapshot.kind, provider: BillWidgetProvider()) { entry in
            BillWidgetView(entry: entry)
        }
        .configurationDisplayName("관심 법안")
        .description("담아둔 법안의 진행 단계와 오늘 발의 건수를 보여줍니다.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}
