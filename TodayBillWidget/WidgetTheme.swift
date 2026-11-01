import SwiftUI
import WidgetKit

/// 위젯이 쓰는 색만. 앱 `Theme`와 같은 시스템 색을 가리키지만 SwiftUI 타입이고 타겟이 다르다.
enum WidgetTheme {
    static let background = Color(.systemGroupedBackground)
    static let primaryText = Color(.label)
    static let secondaryText = Color(.secondaryLabel)
    static let accent = Color(.link)
}

extension View {
    /// iOS 17부터 위젯은 `containerBackground`로 배경을 선언해야 홈 화면에서 제대로 그려진다.
    /// 배포 타깃이 16.4라 양쪽을 모두 지원해야 한다.
    @ViewBuilder
    func widgetContainerBackground(_ color: Color) -> some View {
        if #available(iOSApplicationExtension 17.0, *) {
            containerBackground(color, for: .widget)
        } else {
            background(color)
        }
    }
}
