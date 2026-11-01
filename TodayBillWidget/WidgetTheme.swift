import SwiftUI
import UIKit
import WidgetKit

/// The app's warm-white/charcoal palette, expressed for the widget target.
enum WidgetTheme {
    static let background = color(light: 0xF4F3F0, dark: 0x121211)
    static let primaryText = color(light: 0x252521, dark: 0xF4F3ED)
    static let secondaryText = color(light: 0x64645D, dark: 0xBDBCB3)
    static let accent = color(light: 0x5C5B57, dark: 0xD9D6CE)

    private static func color(light: UInt32, dark: UInt32) -> Color {
        Color(UIColor { traits in
            let hex = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: CGFloat((hex >> 16) & 0xFF) / 255,
                           green: CGFloat((hex >> 8) & 0xFF) / 255,
                           blue: CGFloat(hex & 0xFF) / 255, alpha: 1)
        })
    }
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
