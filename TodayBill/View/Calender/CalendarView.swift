//
//  CalendarView.swift
//  TodayBill
//
//  Created by 김건호 on 1/31/25.
//

import Foundation
import UIKit

/// 홈: 오늘의 지표 하나를 크게 세우고, 그 아래로 캘린더 · 날짜별 법안 · 시행 예정을 잇는다.
/// 모든 블록은 회색 바탕 위의 흰 카드이며, 색은 상태에만 쓴다.
final class CalendarView: UIView {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Theme.Spacing.section
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()


    let dashboardView = HomeDashboardPanelView()

    private let calendarTitleLabel = SectionHeaderLabel(text: "날짜별 법안")

    lazy var dateView: UICalendarView = {
        var view = UICalendarView()
        view.wantsDateDecorations = true
        view.backgroundColor = .clear
        view.tintColor = Theme.accent
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let selectedDateTitleLabel = SectionHeaderLabel(text: "선택 날짜 법안")

    let listContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.clipsToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let lawSectionView = LawEnforcementSectionView()

    private let footerLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.caption
        label.textColor = Theme.textMuted
        label.numberOfLines = 0
        return label
    }()

    weak var delegate: UICalendarViewDelegate?
    private var listHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        dashboardView.translatesAutoresizingMaskIntoConstraints = false
        lawSectionView.translatesAutoresizingMaskIntoConstraints = false

        let calendarSectionView = Self.makeSection(
            header: calendarTitleLabel,
            content: CardView(contentView: dateView, padding: Theme.Spacing.listPadding)
        )

        contentStackView.addArrangedSubview(dashboardView)
        contentStackView.addArrangedSubview(calendarSectionView)
        contentStackView.addArrangedSubview(
            Self.makeSection(header: selectedDateTitleLabel, content: listContainerView, spacing: 0)
        )
        contentStackView.addArrangedSubview(lawSectionView)
        contentStackView.addArrangedSubview(footerLabel)

        // The list controller sets its own horizontal inset, so it spans the full stack width.
        contentStackView.setCustomSpacing(8, after: calendarSectionView)

        lawSectionView.onLawSelected = { [weak self] enforcement in
            self?.dashboardView.onLawSelected?(enforcement)
        }

        listHeightConstraint = listContainerView.heightAnchor.constraint(equalToConstant: 260)
        listHeightConstraint?.priority = .defaultHigh

        let inset = Theme.Spacing.screenHorizontal

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 6),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: inset),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -inset),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -28),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -inset * 2),

            dateView.heightAnchor.constraint(equalToConstant: 340),

            listHeightConstraint!
        ])
    }

    func updateDashboard(_ dashboard: HomeDashboard) {
        dashboardView.configure(with: dashboard)
        lawSectionView.configure(
            with: dashboard.lawEnforcements,
            failed: dashboard.failedSections.contains(.lawEnforcements)
        )
        footerLabel.attributedText = Self.makeFooterText(updatedAt: dashboard.updatedAt)
    }

    func updateSelectedDateTitle(_ title: String) {
        selectedDateTitleLabel.text = title
    }

    func updateListHeight(_ height: CGFloat) {
        listHeightConstraint?.constant = max(180, height)
        layoutIfNeeded()
    }

    func reloadDateView(date: Date?) {
        if let date = date {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
            dateView.reloadDecorations(forDateComponents: [dateComponents], animated: true)
        }
    }

    private static func makeSection(header: UILabel, content: UIView, spacing: CGFloat = 8) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [header, content])
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }

    private static func makeFooterText(updatedAt: Date) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 4
        let text = "데이터 출처 · 국회 의안정보시스템\n최근 업데이트 \(footerDateFormatter.string(from: updatedAt))"
        return NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: Theme.Font.caption,
                .foregroundColor: Theme.textMuted
            ]
        )
    }

    private static let footerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy.MM.dd HH:mm"
        return formatter
    }()
}

/// 15 / 800 section heading, sitting on the background with a 4pt optical gutter.
final class SectionHeaderLabel: UILabel {
    init(text: String) {
        super.init(frame: .zero)
        self.text = text
        font = Theme.Font.sectionHeading
        textColor = Theme.textColor
        numberOfLines = 1
        translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func drawText(in rect: CGRect) {
        super.drawText(in: rect.inset(by: UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width + 8, height: size.height)
    }
}

final class HomeDashboardPanelView: UIView {
    var onBillSelected: ((BillSnapshot) -> Void)?
    var onLawSelected: ((LawEnforcementSnapshot) -> Void)?

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metaStrong
        label.textColor = Theme.textMuted
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 발의"
        label.font = Theme.Font.screenTitle
        label.textColor = Theme.textColor
        label.numberOfLines = 1
        return label
    }()

    private let headlineStatView = HeadlineStatView()

    private let stageSectionStackView = DashboardSectionStackView(title: "내 관심 법안 변동")
    private let hotSectionStackView = DashboardSectionStackView(title: "주목할 법안")
    private let committeeSectionStackView = DashboardSectionStackView(title: "오늘 위원회별 발의")
    private let committeeChartView = CommitteeBreakdownView()

    private let hotScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        // Clipped: in the two-column layout anything overflowing would be drawn
        // on top of the column beside it.
        scrollView.clipsToBounds = true
        return scrollView
    }()

    private let hotStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        return stackView
    }()

    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = Theme.Spacing.section
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        addSubview(mainStackView)

        let headerStack = UIStackView(arrangedSubviews: [dateLabel, titleLabel])
        headerStack.axis = .vertical
        headerStack.spacing = 4
        headerStack.isLayoutMarginsRelativeArrangement = true
        headerStack.layoutMargins = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 4)

        hotScrollView.addSubview(hotStackView)
        hotStackView.translatesAutoresizingMaskIntoConstraints = false
        hotSectionStackView.contentStackView.addArrangedSubview(hotScrollView)
        committeeSectionStackView.contentStackView.addArrangedSubview(committeeChartView)

        mainStackView.addArrangedSubview(headerStack)
        mainStackView.addArrangedSubview(headlineStatView)
        mainStackView.addArrangedSubview(stageSectionStackView)
        mainStackView.addArrangedSubview(hotSectionStackView)
        mainStackView.addArrangedSubview(committeeSectionStackView)

        dateLabel.text = Self.headerDateFormatter.string(from: Date())

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            hotScrollView.heightAnchor.constraint(equalToConstant: 124),
            hotStackView.topAnchor.constraint(equalTo: hotScrollView.contentLayoutGuide.topAnchor),
            hotStackView.leadingAnchor.constraint(equalTo: hotScrollView.contentLayoutGuide.leadingAnchor),
            hotStackView.trailingAnchor.constraint(equalTo: hotScrollView.contentLayoutGuide.trailingAnchor),
            hotStackView.bottomAnchor.constraint(equalTo: hotScrollView.contentLayoutGuide.bottomAnchor),
            hotStackView.heightAnchor.constraint(equalTo: hotScrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    func configure(with dashboard: HomeDashboard) {
        headlineStatView.configure(with: dashboard)
        configureStageChanges(dashboard.stageChanges)
        configureHotBills(dashboard.hotBills)
        configureCommitteeBreakdown(dashboard.newProposals)
    }

    private func configureStageChanges(_ snapshots: [BillSnapshot]) {
        stageSectionStackView.clearContent()
        guard !snapshots.isEmpty else {
            stageSectionStackView.addEmptyMessage("관심 법안의 새로운 진행 변경이 없습니다.")
            return
        }

        let rows = snapshots.prefix(3).map { snapshot -> UIView in
            let row = StageChangeRowControl()
            row.configure(snapshot: snapshot)
            row.onActivate = { [weak self] in
                self?.onBillSelected?(snapshot)
            }
            return row
        }

        // One card holding hairline-separated rows, rather than one card per row.
        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.spacing = 0
        for (index, row) in rows.enumerated() {
            rowsStack.addArrangedSubview(row)
            if index < rows.count - 1 {
                rowsStack.addArrangedSubview(HairlineView())
            }
        }

        stageSectionStackView.contentStackView.addArrangedSubview(
            CardView(
                contentView: rowsStack,
                horizontalPadding: Theme.Spacing.listPadding,
                verticalPadding: 6,
                cornerRadius: Theme.Radius.list
            )
        )
    }

    private func configureHotBills(_ hotBills: [HotBillSnapshot]) {
        hotStackView.arrangedSubviews.forEach { view in
            hotStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        guard !hotBills.isEmpty else {
            let emptyView = DashboardEmptyStateView(message: "최근 신호로 주목할 법안이 아직 없습니다.")
            hotStackView.addArrangedSubview(emptyView)
            emptyView.widthAnchor.constraint(equalToConstant: 280).isActive = true
            return
        }

        hotBills.forEach { hotBill in
            let card = HotBillCardControl()
            card.configure(with: hotBill)
            card.onActivate = { [weak self] in
                self?.onBillSelected?(hotBill.bill)
            }
            hotStackView.addArrangedSubview(card)
            card.widthAnchor.constraint(equalToConstant: 268).isActive = true
        }
    }

    private func configureCommitteeBreakdown(_ snapshots: [BillSnapshot]) {
        let grouped: [String: [BillSnapshot]] = Dictionary(grouping: snapshots) { $0.displayCommittee }
        var counts: [(name: String, count: Int)] = grouped.map { (name: $0.key, count: $0.value.count) }
        counts.sort { lhs, rhs in
            lhs.count == rhs.count ? lhs.name < rhs.name : lhs.count > rhs.count
        }
        let top = Array(counts.prefix(4))

        committeeSectionStackView.isHidden = top.isEmpty
        committeeChartView.configure(with: top)
    }

    private static let headerDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 EEEE"
        return formatter
    }()
}

/// 오늘 발의 건수를 44/800으로 한 번만 크게 쓰고, 나머지 지표는 구분선 아래 19/800으로 내린다.
private final class HeadlineStatView: UIView {
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metricXL
        label.textColor = Theme.textColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.6
        return label
    }()

    private let unitLabel: UILabel = {
        let label = UILabel()
        label.text = "건"
        label.font = UIFont.systemFont(ofSize: 17, weight: .bold)
        label.textColor = Theme.textSecondary
        return label
    }()

    private let statusBadgeLabel = BadgeLabel(horizontalPadding: 10, verticalPadding: 5)

    private let stageChangeStatView = SubStatView(title: "관심 법안 변동")
    private let enforcementStatView = SubStatView(title: "시행 예정")

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 18
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = Theme.cellBackgroundColor
        layer.cornerRadius = Theme.Radius.card
        layer.masksToBounds = true

        let countRow = UIStackView(arrangedSubviews: [countLabel, unitLabel, UIView(), statusBadgeLabel])
        countRow.axis = .horizontal
        countRow.alignment = .lastBaseline
        countRow.spacing = 6

        let dividerView = UIView()
        dividerView.backgroundColor = Theme.separator
        dividerView.translatesAutoresizingMaskIntoConstraints = false

        let subStatRow = UIStackView(arrangedSubviews: [stageChangeStatView, dividerView, enforcementStatView])
        subStatRow.axis = .horizontal
        subStatRow.distribution = .fill
        subStatRow.alignment = .fill
        subStatRow.spacing = 16

        addSubview(contentStackView)
        contentStackView.addArrangedSubview(countRow)
        contentStackView.addArrangedSubview(HairlineView())
        contentStackView.addArrangedSubview(subStatRow)
        contentStackView.setCustomSpacing(14, after: countRow)

        let padding = Theme.Spacing.cardPadding
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),

            dividerView.widthAnchor.constraint(equalToConstant: 1),
            stageChangeStatView.widthAnchor.constraint(equalTo: enforcementStatView.widthAnchor)
        ])
    }

    func configure(with dashboard: HomeDashboard) {
        countLabel.text = "\(dashboard.newProposals.count)"
        stageChangeStatView.configure(count: dashboard.stageChanges.count)
        enforcementStatView.configure(count: Self.upcomingLawCount(from: dashboard.lawEnforcements))

        // The badge reports freshness, the one thing a cached load has to disclose.
        if dashboard.updateFailed {
            statusBadgeLabel.configure(text: "저장된 데이터", style: .muted)
        } else {
            statusBadgeLabel.configure(text: "최신", style: .progress)
        }

        accessibilityLabel = "오늘 발의 \(dashboard.newProposals.count)건"
    }

    private static func upcomingLawCount(from enforcements: [LawEnforcementSnapshot]) -> Int {
        let today = dayFormatter.string(from: Date())
        return enforcements.filter { $0.enforcementDate >= today }.count
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private final class SubStatView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.caption
        label.textColor = Theme.textMuted
        label.numberOfLines = 1
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metricS
        label.textColor = Theme.textColor
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title

        let stack = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        stack.axis = .vertical
        stack.spacing = 3
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

    func configure(count: Int) {
        countLabel.text = "\(count)"
        accessibilityLabel = "\(titleLabel.text ?? "") \(count)건"
    }
}

/// 위원회별 발의 건수를 가로 막대로. 색은 하나(액센트)이고 순위는 명도로 내려간다.
private final class CommitteeBreakdownView: UIView {
    private let rowsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.cellBackgroundColor
        view.layer.cornerRadius = Theme.Radius.card
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(cardView)
        cardView.addSubview(rowsStackView)

        let padding = Theme.Spacing.cardPadding
        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: topAnchor),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor),
            cardView.bottomAnchor.constraint(equalTo: bottomAnchor),

            rowsStackView.topAnchor.constraint(equalTo: cardView.topAnchor, constant: padding),
            rowsStackView.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 18),
            rowsStackView.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -18),
            rowsStackView.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -padding)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with entries: [(name: String, count: Int)]) {
        rowsStackView.arrangedSubviews.forEach { view in
            rowsStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let maxCount = max(entries.first?.count ?? 1, 1)
        for (index, entry) in entries.enumerated() {
            rowsStackView.addArrangedSubview(
                CommitteeBarRow(
                    name: entry.name,
                    count: entry.count,
                    ratio: CGFloat(entry.count) / CGFloat(maxCount),
                    rank: index
                )
            )
        }
    }
}

private final class CommitteeBarRow: UIView {
    /// Rank shades of the one accent - #1F5CD8 down to a pale tint, never a second hue.
    private static let rankAlphas: [CGFloat] = [1.0, 0.72, 0.48, 0.28]

    init(name: String, count: Int, ratio: CGFloat, rank: Int) {
        super.init(frame: .zero)

        let nameLabel = UILabel()
        nameLabel.text = name
        nameLabel.font = Theme.Font.metaStrong
        nameLabel.textColor = Theme.textStrong
        nameLabel.lineBreakMode = .byTruncatingTail

        let countLabel = UILabel()
        countLabel.text = "\(count)"
        countLabel.font = Theme.Font.metaStrong
        countLabel.textColor = Theme.textColor
        countLabel.setContentHuggingPriority(.required, for: .horizontal)

        let labelRow = UIStackView(arrangedSubviews: [nameLabel, countLabel])
        labelRow.axis = .horizontal
        labelRow.spacing = 8

        let trackView = UIView()
        trackView.backgroundColor = Theme.separator
        trackView.layer.cornerRadius = 3
        trackView.layer.masksToBounds = true
        trackView.translatesAutoresizingMaskIntoConstraints = false

        let barView = UIView()
        barView.backgroundColor = Theme.accent.withAlphaComponent(
            Self.rankAlphas[min(rank, Self.rankAlphas.count - 1)]
        )
        barView.layer.cornerRadius = 3
        barView.layer.masksToBounds = true
        barView.translatesAutoresizingMaskIntoConstraints = false
        trackView.addSubview(barView)

        let stack = UIStackView(arrangedSubviews: [labelRow, trackView])
        stack.axis = .vertical
        stack.spacing = 7
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        isAccessibilityElement = true
        accessibilityLabel = "\(name) \(count)건"

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),

            trackView.heightAnchor.constraint(equalToConstant: 6),
            barView.topAnchor.constraint(equalTo: trackView.topAnchor),
            barView.bottomAnchor.constraint(equalTo: trackView.bottomAnchor),
            barView.leadingAnchor.constraint(equalTo: trackView.leadingAnchor),
            barView.widthAnchor.constraint(
                equalTo: trackView.widthAnchor,
                multiplier: max(0.06, min(ratio, 1))
            )
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// 시행 예정/최근 시행 - one card of hairline-separated rows with a date badge.
private final class LawEnforcementSectionView: UIView {
    var onLawSelected: ((LawEnforcementSnapshot) -> Void)?

    private let sectionStackView = DashboardSectionStackView(title: "시행 예정/최근 시행")

    override init(frame: CGRect) {
        super.init(frame: frame)
        sectionStackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(sectionStackView)

        NSLayoutConstraint.activate([
            sectionStackView.topAnchor.constraint(equalTo: topAnchor),
            sectionStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            sectionStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            sectionStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with enforcements: [LawEnforcementSnapshot], failed: Bool) {
        sectionStackView.clearContent()
        if failed {
            sectionStackView.addStatusBadge("시행일 정보를 불러오지 못했어요")
        }

        guard !enforcements.isEmpty else {
            sectionStackView.addEmptyMessage("시행 예정 법률 항목이 없습니다.")
            return
        }

        let rows = enforcements.prefix(5).map { enforcement -> UIView in
            let row = LawTimelineRowControl()
            row.configure(with: enforcement)
            row.onActivate = { [weak self] in
                self?.onLawSelected?(enforcement)
            }
            return row
        }

        let rowsStack = UIStackView()
        rowsStack.axis = .vertical
        rowsStack.spacing = 0
        for (index, row) in rows.enumerated() {
            rowsStack.addArrangedSubview(row)
            if index < rows.count - 1 {
                rowsStack.addArrangedSubview(HairlineView())
            }
        }

        sectionStackView.contentStackView.addArrangedSubview(
            CardView(
                contentView: rowsStack,
                horizontalPadding: Theme.Spacing.listPadding,
                verticalPadding: 6,
                cornerRadius: Theme.Radius.list
            )
        )
    }
}

private final class DashboardSectionStackView: UIView {
    let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    private let titleLabel = SectionHeaderLabel(text: "")

    private let statusStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        return stackView
    }()

    private let headerStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    init(title: String) {
        super.init(frame: .zero)
        titleLabel.text = title
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(statusStackView)
        headerStackView.addArrangedSubview(UIView())

        addSubview(headerStackView)
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            headerStackView.trailingAnchor.constraint(equalTo: trailingAnchor),

            contentStackView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 8),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func clearContent() {
        contentStackView.arrangedSubviews.forEach { view in
            contentStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        statusStackView.arrangedSubviews.forEach { view in
            statusStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }

    func addEmptyMessage(_ message: String) {
        contentStackView.addArrangedSubview(DashboardEmptyStateView(message: message))
    }

    func addStatusBadge(_ text: String) {
        let label = BadgeLabel(horizontalPadding: 7, verticalPadding: 4)
        label.configure(text: text, style: .muted)
        statusStackView.addArrangedSubview(label)
    }
}

private final class DashboardEmptyStateView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.emptyMessage
        label.textColor = Theme.textMuted
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(message: String) {
        super.init(frame: .zero)
        label.text = message
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = Theme.cellBackgroundColor
        layer.cornerRadius = Theme.Radius.list
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: Theme.Spacing.listPadding),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: Theme.Spacing.listPadding),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -Theme.Spacing.listPadding),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -Theme.Spacing.listPadding)
        ])
    }
}

/// 관심 법안 변동 row: a 34pt icon tile, then title over a colored status line.
private final class StageChangeRowControl: UIControl {
    var onActivate: (() -> Void)?

    private let iconTileView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = Theme.Radius.iconTile
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()

    private let titleLabel = DashboardTextLabel(font: Theme.Font.rowValue, color: Theme.textColor)
    private let statusLabel = DashboardTextLabel(font: Theme.Font.caption, color: Theme.accent)

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleActivation)))

        titleLabel.numberOfLines = 2
        statusLabel.numberOfLines = 1

        iconTileView.addSubview(iconImageView)

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, statusLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2

        let rowStack = UIStackView(arrangedSubviews: [iconTileView, labelsStack])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowStack)

        NSLayoutConstraint.activate([
            iconTileView.widthAnchor.constraint(equalToConstant: 34),
            iconTileView.heightAnchor.constraint(equalToConstant: 34),
            iconImageView.centerXAnchor.constraint(equalTo: iconTileView.centerXAnchor),
            iconImageView.centerYAnchor.constraint(equalTo: iconTileView.centerYAnchor),
            iconImageView.widthAnchor.constraint(equalToConstant: 18),

            rowStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14),
            heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.Spacing.touchTarget)
        ])
    }

    func configure(snapshot: BillSnapshot) {
        titleLabel.text = snapshot.title

        let isCompleted = snapshot.stage == .completed
        let tint = isCompleted ? Theme.success : Theme.accent
        iconTileView.backgroundColor = isCompleted ? Theme.successSoft : Theme.accentSoft
        iconImageView.image = UIImage(
            systemName: isCompleted ? "checkmark" : "arrow.right",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 13, weight: .bold)
        )
        iconImageView.tintColor = tint

        let dateText = BillSnapshot.nonEmpty(snapshot.proposedDate).map { " · \($0)" } ?? ""
        statusLabel.text = "\(snapshot.stage.title) 단계\(dateText)"
        statusLabel.textColor = tint

        accessibilityLabel = "\(snapshot.title), \(snapshot.stage.title)"
    }

    override func accessibilityActivate() -> Bool {
        activate()
        return true
    }

    @objc private func handleActivation() {
        activate()
    }

    private func activate() {
        onActivate?()
    }
}

private final class HotBillCardControl: UIControl {
    var onActivate: (() -> Void)?

    private let titleLabel = DashboardTextLabel(font: Theme.Font.cardHeading, color: Theme.textColor)
    private let metadataLabel = DashboardTextLabel(font: Theme.Font.meta, color: Theme.textMuted)

    private let badgeStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .center
        return stackView
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 8
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleActivation)))
        backgroundColor = Theme.cellBackgroundColor
        layer.cornerRadius = Theme.Radius.list
        layer.masksToBounds = true

        addSubview(stackView)
        stackView.addArrangedSubview(badgeStackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(metadataLabel)

        let padding = Theme.Spacing.listPadding
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -padding)
        ])
    }

    func configure(with hotBill: HotBillSnapshot) {
        titleLabel.text = hotBill.bill.title
        titleLabel.numberOfLines = 2
        metadataLabel.text = hotBill.bill.displayProposer

        badgeStackView.arrangedSubviews.forEach { view in
            badgeStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let stageBadge = BadgeLabel()
        stageBadge.configure(text: hotBill.bill.stage.title, style: hotBill.bill.stage.badgeStyle)
        badgeStackView.addArrangedSubview(stageBadge)

        if let reason = hotBill.reasons.first {
            let reasonBadge = BadgeLabel()
            reasonBadge.configure(text: reason.title, style: .neutral)
            badgeStackView.addArrangedSubview(reasonBadge)
        }
        badgeStackView.addArrangedSubview(UIView())

        let reasonText = hotBill.reasons.map(\.title).joined(separator: ", ")
        accessibilityLabel = reasonText.isEmpty ? hotBill.bill.title : "\(hotBill.bill.title), \(reasonText)"
    }

    override func accessibilityActivate() -> Bool {
        activate()
        return true
    }

    @objc private func handleActivation() {
        activate()
    }

    private func activate() {
        onActivate?()
    }
}

private final class LawTimelineRowControl: UIControl {
    var onActivate: (() -> Void)?

    private let dateBadgeLabel = BadgeLabel()
    private let titleLabel = DashboardTextLabel(font: Theme.Font.rowValue, color: Theme.textColor)
    private let metadataLabel = DashboardTextLabel(font: Theme.Font.meta, color: Theme.textMuted)

    private let chevronImageView: UIImageView = {
        let imageView = UIImageView(
            image: UIImage(
                systemName: "chevron.right",
                withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .bold)
            )
        )
        imageView.tintColor = Theme.textDisabled
        imageView.setContentHuggingPriority(.required, for: .horizontal)
        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        isAccessibilityElement = true
        accessibilityTraits = .button
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleActivation)))

        titleLabel.numberOfLines = 2
        metadataLabel.numberOfLines = 1

        let badgeRow = UIStackView(arrangedSubviews: [dateBadgeLabel, UIView()])
        badgeRow.axis = .horizontal

        let labelsStack = UIStackView(arrangedSubviews: [badgeRow, titleLabel, metadataLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 6

        let rowStack = UIStackView(arrangedSubviews: [labelsStack, chevronImageView])
        rowStack.axis = .horizontal
        rowStack.spacing = 12
        rowStack.alignment = .center
        rowStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rowStack)

        NSLayoutConstraint.activate([
            rowStack.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            rowStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            rowStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            rowStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }

    func configure(with enforcement: LawEnforcementSnapshot) {
        // 완료 초록은 이미 시행된 법률에만. 예정은 진행(액센트)으로 둔다.
        let isEnforced = enforcement.enforcementDate <= Self.dayFormatter.string(from: Date())
        dateBadgeLabel.configure(
            text: "\(enforcement.enforcementDate) 시행",
            style: isEnforced ? .done : .progress
        )
        titleLabel.text = enforcement.lawName
        metadataLabel.text = [
            enforcement.ministry,
            enforcement.lawType,
            enforcement.promulgationDate.map { "공포 \($0)" }
        ].compactMap { $0 }.joined(separator: " · ")
        accessibilityLabel = "\(enforcement.lawName), 시행일 \(enforcement.enforcementDate)"
    }

    override func accessibilityActivate() -> Bool {
        activate()
        return true
    }

    @objc private func handleActivation() {
        activate()
    }

    private func activate() {
        onActivate?()
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()
}

private final class DashboardTextLabel: UILabel {
    init(font: UIFont, color: UIColor) {
        super.init(frame: .zero)
        self.font = font
        textColor = color
        numberOfLines = 0
        lineBreakMode = .byTruncatingTail
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
