//
//  Theme.swift
//  TodayBill
//
//  Created by 김건호 on 2/22/25.
//

import Foundation
import UIKit

/// Design tokens for the "뉴트럴 그레이 바탕 · 흰 카드 · 단일 액센트" tone.
///
/// Two surface layers make the depth (background + white card), one accent carries "진행",
/// and green is reserved for "완료". Hierarchy comes from type size and weight, not from color.
struct Theme {

    // MARK: - Surfaces

    /// Screen background. #F2F4F6 in light.
    static let backgroundColor = dynamic(light: 0xF2F4F6, dark: 0x0F1114)

    /// Card / list-row surface sitting on `backgroundColor`. #FFFFFF in light.
    static let cellBackgroundColor = dynamic(light: 0xFFFFFF, dark: 0x191C21)

    /// Near-black surface for the one emphasized card per screen (알림 유도, 주간 변동).
    static let inkSurface = dynamic(light: 0x17181C, dark: 0x262B33)

    /// Neutral fill for tracks, unfilled progress segments and inactive chips. #E5E8EB in light.
    static let fill = dynamic(light: 0xE5E8EB, dark: 0x2C313A)

    /// 1px divider inside cards. Uses a tint rather than a shadow to separate content.
    static let separator = dynamic(light: 0xF2F4F6, dark: 0x23272E)

    /// 1px line above the tab bar.
    static let border = dynamic(light: 0xEDEFF2, dark: 0x272C34)

    // MARK: - Accents

    /// The single accent. Used for "진행 중", selected state and primary actions.
    static let accent = dynamic(light: 0x1F5CD8, dark: 0x4E86F0)

    /// Accent wash behind progress badges and accent icon tiles.
    static let accentSoft = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0x4E86F0).withAlphaComponent(0.18)
            : UIColor(hex: 0xEEF3FE)
    }

    /// Reserved for "완료" only - never used as a generic accent.
    static let success = dynamic(light: 0x0E8A5F, dark: 0x34C98D)

    static let successSoft = UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: 0x34C98D).withAlphaComponent(0.18)
            : UIColor(hex: 0xE7F5EF)
    }

    // MARK: - Text

    /// Primary text. #17181C in light.
    static let textColor = dynamic(light: 0x17181C, dark: 0xF2F4F6)

    /// Slightly softened primary, for dense rows. #333D4B in light.
    static let textStrong = dynamic(light: 0x333D4B, dark: 0xDCE1E8)

    /// Body copy. #4E5968 in light.
    static let textSecondary = dynamic(light: 0x4E5968, dark: 0xA7B0BC)

    /// Meta text - dates, counts, captions. #8B95A1 in light.
    static let textMuted = dynamic(light: 0x8B95A1, dark: 0x7C8794)

    /// Retired / expired content, and the trailing half of a dimmed row. #B0B8C1 in light.
    static let textDisabled = dynamic(light: 0xB0B8C1, dark: 0x5E6875)

    /// Legacy name for the muted meta tone.
    static let emptyLabelTextColor = textMuted

    /// Text drawn on `inkSurface`.
    static let onInkPrimary = UIColor.white
    static let onInkSecondary = dynamic(light: 0x98A2B0, dark: 0x98A2B0)

    // MARK: - Type

    /// Four-step scale: 지표(숫자) · 화면 제목 · 법안명 · 메타.
    /// CSS weight 800 maps to `.heavy`, 700 to `.bold`, 600 to `.semibold`, 500 to `.medium`.
    struct Font {
        /// 44 / 800 - the one headline number on a screen.
        static let metricXL = UIFont.systemFont(ofSize: 44, weight: .heavy)
        /// 36 / 800 - secondary headline number (표결 결과).
        static let metricL = UIFont.systemFont(ofSize: 36, weight: .heavy)
        /// 19 / 800 - sub-stat under a divider.
        static let metricS = UIFont.systemFont(ofSize: 19, weight: .heavy)

        /// 26 / 800 - screen title.
        static let screenTitle = UIFont.systemFont(ofSize: 26, weight: .heavy)
        /// 24 / 800 - bill title on the detail screen.
        static let detailTitle = UIFont.systemFont(ofSize: 24, weight: .heavy)
        /// 16 / 600 - sticky nav title.
        static let navTitle = UIFont.systemFont(ofSize: 16, weight: .semibold)

        /// 15 / 800 - section and card heading.
        static let sectionHeading = UIFont.systemFont(ofSize: 15, weight: .heavy)
        /// 16 / 700 - bill title in a card.
        static let cardHeading = UIFont.systemFont(ofSize: 16, weight: .bold)
        /// 15 / 700 - title in a dense row (timeline step, tracking row).
        static let listTitle = UIFont.systemFont(ofSize: 15, weight: .bold)

        /// 16 / 700 - primary button label.
        static let button = UIFont.systemFont(ofSize: 16, weight: .bold)
        /// 13 / 600 - filter chip / keyword chip.
        static let chip = UIFont.systemFont(ofSize: 13, weight: .semibold)
        /// 14 / 700 - inline text link ("더 보기").
        static let link = UIFont.systemFont(ofSize: 14, weight: .bold)

        /// 14 / 400 - body copy. Pair with `Theme.Metric.bodyLineSpacing`.
        static let body = UIFont.systemFont(ofSize: 14, weight: .regular)
        /// 14 / 600 - left label of a key/value row.
        static let rowLabel = UIFont.systemFont(ofSize: 14, weight: .semibold)
        /// 14 / 700 - right value of a key/value row.
        static let rowValue = UIFont.systemFont(ofSize: 14, weight: .bold)
        /// 15 / 500 - status and empty-state message.
        static let statusMessage = UIFont.systemFont(ofSize: 15, weight: .medium)
        /// 14 / 500 - empty-state message inside a card.
        static let emptyMessage = UIFont.systemFont(ofSize: 14, weight: .medium)

        /// 13 / 500 - meta line (발의자 · 날짜).
        static let meta = UIFont.systemFont(ofSize: 13, weight: .medium)
        /// 13 / 700 - emphasized meta.
        static let metaStrong = UIFont.systemFont(ofSize: 13, weight: .bold)
        /// 12 / 600 - caption / legend.
        static let caption = UIFont.systemFont(ofSize: 12, weight: .semibold)
        /// 12 / 700 - emphasized caption.
        static let captionStrong = UIFont.systemFont(ofSize: 12, weight: .bold)
        /// 11 / 700 - badge and tab label.
        static let badge = UIFont.systemFont(ofSize: 11, weight: .bold)
        /// 11 / 600 - unselected tab label.
        static let tabLabel = UIFont.systemFont(ofSize: 11, weight: .semibold)
    }

    /// 카드 20 / 리스트 18 / 버튼 16 / 필드 15 / 칩 11 / 배지 6.
    struct Radius {
        static let card: CGFloat = 20
        static let list: CGFloat = 18
        static let button: CGFloat = 16
        static let field: CGFloat = 15
        static let chip: CGFloat = 11
        static let iconTile: CGFloat = 11
        static let badge: CGFloat = 6
    }

    /// 화면 좌우 20, 섹션 간 14, 카드 내부 16~20.
    struct Spacing {
        static let screenHorizontal: CGFloat = 20
        static let section: CGFloat = 14
        static let cardPadding: CGFloat = 20
        static let listPadding: CGFloat = 16
        /// Minimum touch target.
        static let touchTarget: CGFloat = 44
    }

    struct Metric {
        /// Body copy is set at line-height 1.65; `body` is 14pt, so 14 * 0.65 ≈ 9.
        static let bodyLineSpacing: CGFloat = 9
        static let tabBarContentHeight: CGFloat = 60
    }

    struct Layout {
        /// Caps a column of content. Phones in portrait stay under it and are
        /// unaffected; wide poses — landscape, and the unfolded display — centre
        /// the column instead of stretching every card across the screen.
        static let maxContentWidth: CGFloat = 680

        /// A short pose — landscape, or the cover screen turned sideways — cannot
        /// spare 60pt for a tab bar, so it loses its labels and gets shorter.
        static func tabBarContentHeight(for traits: UITraitCollection) -> CGFloat {
            traits.verticalSizeClass == .compact ? 44 : Metric.tabBarContentHeight
        }
    }

    // MARK: - Helpers

    private static func dynamic(light: UInt32, dark: UInt32) -> UIColor {
        UIColor { trait in
            UIColor(hex: trait.userInterfaceStyle == .dark ? dark : light)
        }
    }
}

extension UIColor {
    convenience init(hex: UInt32) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255,
            green: CGFloat((hex >> 8) & 0xFF) / 255,
            blue: CGFloat(hex & 0xFF) / 255,
            alpha: 1
        )
    }
}

// MARK: - Shared components

/// The only three badge tones in the app. Anything outside this set is expressed with
/// lightness (`.muted`) instead of a new hue, so the color vocabulary stays learnable.
enum BadgeStyle {
    /// 분류 · 소관 (위원회, 대수).
    case neutral
    /// 살아있는 법안 - 심사 진행, 정부 이송.
    case progress
    /// 확정된 결과 - 공포, 본회의 통과.
    case done
    /// 폐기 · 임기만료. Grey on grey, never a new color.
    case muted

    var foreground: UIColor {
        switch self {
        case .neutral: return Theme.textSecondary
        case .progress: return Theme.accent
        case .done: return Theme.success
        case .muted: return Theme.textMuted
        }
    }

    var background: UIColor {
        switch self {
        case .neutral, .muted: return Theme.separator
        case .progress: return Theme.accentSoft
        case .done: return Theme.successSoft
        }
    }
}

/// 11 / 700 label in a 6pt-radius tint block.
final class BadgeLabel: UILabel {
    private let contentInsets: UIEdgeInsets

    init(horizontalPadding: CGFloat = 8, verticalPadding: CGFloat = 4) {
        contentInsets = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
        super.init(frame: .zero)
        font = Theme.Font.badge
        numberOfLines = 1
        textAlignment = .center
        layer.cornerRadius = Theme.Radius.badge
        layer.masksToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, style: BadgeStyle) {
        self.text = text
        textColor = style.foreground
        backgroundColor = style.background
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: contentInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + contentInsets.left + contentInsets.right,
            height: size.height + contentInsets.top + contentInsets.bottom
        )
    }
}

/// White card on the grey background. Padding defaults to the 20pt card inset;
/// pass `padding: Theme.Spacing.listPadding` for the denser list variant.
final class CardView: UIView {
    convenience init(
        contentView: UIView,
        padding: CGFloat = Theme.Spacing.cardPadding,
        cornerRadius: CGFloat = Theme.Radius.card
    ) {
        self.init(
            contentView: contentView,
            horizontalPadding: padding,
            verticalPadding: padding,
            cornerRadius: cornerRadius
        )
    }

    /// Rows that supply their own vertical rhythm (a hairline-separated list) pass a small
    /// `verticalPadding` so the card hugs them without doubling the gap.
    init(
        contentView: UIView,
        horizontalPadding: CGFloat,
        verticalPadding: CGFloat,
        cornerRadius: CGFloat = Theme.Radius.card
    ) {
        super.init(frame: .zero)
        backgroundColor = Theme.cellBackgroundColor
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: verticalPadding),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: horizontalPadding),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -horizontalPadding),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -verticalPadding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 1px hairline used to split rows inside a card.
final class HairlineView: UIView {
    init() {
        super.init(frame: .zero)
        backgroundColor = Theme.separator
        translatesAutoresizingMaskIntoConstraints = false
        heightAnchor.constraint(equalToConstant: 1).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// The five legislative stages drawn as filled segments plus a "4 / 5단계" caption.
/// Progress is readable without color: the number of filled segments carries it.
final class StageProgressView: UIView {
    private let segmentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 3
        stack.distribution = .fillEqually
        return stack
    }()

    private let captionLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.captionStrong
        return label
    }()

    private let segments: [UIView]

    init(stepCount: Int = BillStage.orderedStages.count) {
        segments = (0..<stepCount).map { _ in
            let view = UIView()
            view.layer.cornerRadius = 3
            view.layer.masksToBounds = true
            view.heightAnchor.constraint(equalToConstant: 5).isActive = true
            return view
        }
        super.init(frame: .zero)

        segments.forEach { segmentStackView.addArrangedSubview($0) }

        let stack = UIStackView(arrangedSubviews: [segmentStackView, captionLabel])
        stack.axis = .vertical
        stack.spacing = 6
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with stage: BillStage) {
        let filled = stage.progressStep
        let isDone = stage == .completed
        let isRetired = stage == .unknown

        let filledColor: UIColor = isDone ? Theme.success : (isRetired ? Theme.textDisabled : Theme.accent)
        for (index, segment) in segments.enumerated() {
            segment.backgroundColor = index < filled ? filledColor : Theme.fill
        }

        captionLabel.textColor = filledColor
        if isDone {
            captionLabel.text = "완료"
        } else if isRetired {
            captionLabel.text = "단계 확인 필요"
        } else {
            captionLabel.text = "\(filled) / \(segments.count)단계"
        }
        accessibilityLabel = "진행 \(captionLabel.text ?? "")"
    }
}

extension BillStage {
    /// The stages that form the progress track. `.unknown` is a missing reading, not a step.
    static var orderedStages: [BillStage] {
        [.proposed, .committee, .lawReview, .plenary, .completed]
    }

    /// 1-based position on the five-step track; 0 when the stage could not be read.
    var progressStep: Int {
        (Self.orderedStages.firstIndex(of: self).map { $0 + 1 }) ?? 0
    }

    var badgeStyle: BadgeStyle {
        switch self {
        case .completed: return .done
        case .unknown: return .muted
        case .proposed, .committee, .lawReview, .plenary: return .progress
        }
    }
}
