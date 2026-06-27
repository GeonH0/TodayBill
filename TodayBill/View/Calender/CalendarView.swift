//
//  CalendarView.swift
//  TodayBill
//
//  Created by 김건호 on 1/31/25.
//

import Foundation
import UIKit

final class CalendarView: UIView {
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let contentStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 18
        stackView.translatesAutoresizingMaskIntoConstraints = false
        return stackView
    }()

    let dashboardView = HomeDashboardPanelView()

    private let calendarSectionView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let calendarTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "날짜별 법안"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = Theme.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    lazy var dateView: UICalendarView = {
        var view = UICalendarView()
        view.wantsDateDecorations = true
        view.backgroundColor = Theme.cellBackgroundColor
        view.layer.cornerRadius = 12
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let selectedDateTitleLabel: UILabel = {
        let label = UILabel()
        label.text = "선택 날짜 법안"
        label.font = .systemFont(ofSize: 20, weight: .bold)
        label.textColor = Theme.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    let listContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        contentStackView.addArrangedSubview(dashboardView)
        contentStackView.addArrangedSubview(calendarSectionView)
        contentStackView.addArrangedSubview(selectedDateTitleLabel)
        contentStackView.addArrangedSubview(listContainerView)

        calendarSectionView.addSubview(calendarTitleLabel)
        calendarSectionView.addSubview(dateView)

        listHeightConstraint = listContainerView.heightAnchor.constraint(equalToConstant: 260)
        listHeightConstraint?.priority = .defaultHigh

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            contentStackView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 18),
            contentStackView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 18),
            contentStackView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -18),
            contentStackView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -24),
            contentStackView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor, constant: -36),

            calendarTitleLabel.topAnchor.constraint(equalTo: calendarSectionView.topAnchor),
            calendarTitleLabel.leadingAnchor.constraint(equalTo: calendarSectionView.leadingAnchor, constant: 2),
            calendarTitleLabel.trailingAnchor.constraint(equalTo: calendarSectionView.trailingAnchor, constant: -2),

            dateView.topAnchor.constraint(equalTo: calendarTitleLabel.bottomAnchor, constant: 10),
            dateView.leadingAnchor.constraint(equalTo: calendarSectionView.leadingAnchor),
            dateView.trailingAnchor.constraint(equalTo: calendarSectionView.trailingAnchor),
            dateView.heightAnchor.constraint(equalToConstant: 360),
            dateView.bottomAnchor.constraint(equalTo: calendarSectionView.bottomAnchor),

            listHeightConstraint!
        ])
    }

    func updateDashboard(_ dashboard: HomeDashboard) {
        dashboardView.configure(with: dashboard)
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
}

final class HomeDashboardPanelView: UIView {
    var onBillSelected: ((BillSnapshot) -> Void)?
    var onLawSelected: ((LawEnforcementSnapshot) -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "오늘의 법안"
        label.font = .systemFont(ofSize: 28, weight: .bold)
        label.textColor = Theme.textColor
        label.numberOfLines = 1
        return label
    }()

    private let summaryStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 10
        stackView.distribution = .fillEqually
        return stackView
    }()

    private let newProposalStatView = DashboardStatView()
    private let stageChangeStatView = DashboardStatView()
    private let enforcementStatView = DashboardStatView()

    private let stageSectionStackView = DashboardSectionStackView(title: "진행 변경")
    private let hotSectionStackView = DashboardSectionStackView(title: "주목할 법안")
    private let lawSectionStackView = DashboardSectionStackView(title: "시행 예정/최근 시행")

    private let hotScrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        return scrollView
    }()

    private let hotStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 12
        return stackView
    }()

    private let mainStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 18
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

        summaryStackView.addArrangedSubview(newProposalStatView)
        summaryStackView.addArrangedSubview(stageChangeStatView)
        summaryStackView.addArrangedSubview(enforcementStatView)

        hotScrollView.addSubview(hotStackView)
        hotStackView.translatesAutoresizingMaskIntoConstraints = false
        hotSectionStackView.contentStackView.addArrangedSubview(hotScrollView)

        mainStackView.addArrangedSubview(titleLabel)
        mainStackView.addArrangedSubview(summaryStackView)
        mainStackView.addArrangedSubview(stageSectionStackView)
        mainStackView.addArrangedSubview(hotSectionStackView)
        mainStackView.addArrangedSubview(lawSectionStackView)

        NSLayoutConstraint.activate([
            mainStackView.topAnchor.constraint(equalTo: topAnchor),
            mainStackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            hotScrollView.heightAnchor.constraint(equalToConstant: 150),
            hotStackView.topAnchor.constraint(equalTo: hotScrollView.contentLayoutGuide.topAnchor),
            hotStackView.leadingAnchor.constraint(equalTo: hotScrollView.contentLayoutGuide.leadingAnchor),
            hotStackView.trailingAnchor.constraint(equalTo: hotScrollView.contentLayoutGuide.trailingAnchor),
            hotStackView.bottomAnchor.constraint(equalTo: hotScrollView.contentLayoutGuide.bottomAnchor),
            hotStackView.heightAnchor.constraint(equalTo: hotScrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    func configure(with dashboard: HomeDashboard) {
        newProposalStatView.configure(title: "새 발의", count: dashboard.newProposals.count, tintColor: .systemBlue)
        stageChangeStatView.configure(title: "진행 변경", count: dashboard.stageChanges.count, tintColor: .systemIndigo)
        enforcementStatView.configure(title: "시행 예정", count: upcomingLawCount(from: dashboard.lawEnforcements), tintColor: .systemGreen)

        configureStageChanges(dashboard.stageChanges)
        configureHotBills(dashboard.hotBills)
        configureLawEnforcements(dashboard.lawEnforcements, failed: dashboard.failedSections.contains(.lawEnforcements))
    }

    private func configureStageChanges(_ snapshots: [BillSnapshot]) {
        stageSectionStackView.clearContent()
        guard !snapshots.isEmpty else {
            stageSectionStackView.addEmptyMessage("관심 법안의 새로운 진행 변경이 없습니다.")
            return
        }

        snapshots.prefix(3).forEach { snapshot in
            let row = DashboardBillRowControl()
            row.configure(snapshot: snapshot)
            row.onActivate = { [weak self] in
                self?.onBillSelected?(snapshot)
            }
            stageSectionStackView.contentStackView.addArrangedSubview(row)
        }
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
            card.widthAnchor.constraint(equalToConstant: 280).isActive = true
        }
    }

    private func configureLawEnforcements(_ enforcements: [LawEnforcementSnapshot], failed: Bool) {
        lawSectionStackView.clearContent()
        if failed {
            lawSectionStackView.addStatusBadge("시행일 정보를 불러오지 못했어요")
        }

        guard !enforcements.isEmpty else {
            lawSectionStackView.addEmptyMessage("시행 예정 법률 항목이 없습니다.")
            return
        }

        enforcements.prefix(5).forEach { enforcement in
            let row = LawTimelineRowControl()
            row.configure(with: enforcement)
            row.onActivate = { [weak self] in
                self?.onLawSelected?(enforcement)
            }
            lawSectionStackView.contentStackView.addArrangedSubview(row)
        }
    }

    private func upcomingLawCount(from enforcements: [LawEnforcementSnapshot]) -> Int {
        let today = Self.dayFormatter.string(from: Date())
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

private final class DashboardStatView: UIView {
    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 26, weight: .bold)
        label.textColor = Theme.textColor
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.75
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 12, weight: .semibold)
        label.textColor = Theme.emptyLabelTextColor
        label.numberOfLines = 1
        return label
    }()

    private let accentView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 3
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 4
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
        backgroundColor = UIColor.white.withAlphaComponent(0.78)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.withAlphaComponent(0.06).cgColor

        addSubview(accentView)
        addSubview(stackView)
        stackView.addArrangedSubview(countLabel)
        stackView.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            accentView.topAnchor.constraint(equalTo: topAnchor),
            accentView.leadingAnchor.constraint(equalTo: leadingAnchor),
            accentView.trailingAnchor.constraint(equalTo: trailingAnchor),
            accentView.heightAnchor.constraint(equalToConstant: 5),

            stackView.topAnchor.constraint(equalTo: accentView.bottomAnchor, constant: 10),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12),
            heightAnchor.constraint(greaterThanOrEqualToConstant: 88)
        ])
    }

    func configure(title: String, count: Int, tintColor: UIColor) {
        titleLabel.text = title
        countLabel.text = "\(count)"
        accentView.backgroundColor = tintColor
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

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 18, weight: .bold)
        label.textColor = Theme.textColor
        return label
    }()

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
        let spacer = UIView()
        headerStackView.addArrangedSubview(titleLabel)
        headerStackView.addArrangedSubview(statusStackView)
        headerStackView.addArrangedSubview(spacer)

        addSubview(headerStackView)
        addSubview(contentStackView)

        NSLayoutConstraint.activate([
            headerStackView.topAnchor.constraint(equalTo: topAnchor),
            headerStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            headerStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),

            contentStackView.topAnchor.constraint(equalTo: headerStackView.bottomAnchor, constant: 10),
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
        let label = DashboardStatusBadgeLabel()
        label.text = text
        label.translatesAutoresizingMaskIntoConstraints = false
        statusStackView.addArrangedSubview(label)
        NSLayoutConstraint.activate([
            label.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}

private final class DashboardEmptyStateView: UIView {
    private let label: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = Theme.emptyLabelTextColor
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
        backgroundColor = UIColor.white.withAlphaComponent(0.55)
        layer.cornerRadius = 8
        addSubview(label)

        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            label.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            label.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -14)
        ])
    }
}

private final class DashboardBillRowControl: UIControl {
    var onActivate: (() -> Void)?

    private let stageLabel = DashboardPillLabel()
    private let titleLabel = DashboardTextLabel(font: .systemFont(ofSize: 15, weight: .semibold), color: Theme.textColor)
    private let metadataLabel = DashboardTextLabel(font: .systemFont(ofSize: 12, weight: .medium), color: Theme.emptyLabelTextColor)

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
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
        backgroundColor = UIColor.white.withAlphaComponent(0.72)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.withAlphaComponent(0.05).cgColor

        addSubview(stackView)
        stackView.addArrangedSubview(stageLabel)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(metadataLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    func configure(snapshot: BillSnapshot) {
        stageLabel.configure(text: snapshot.stage.title, color: .systemIndigo)
        titleLabel.text = snapshot.title
        metadataLabel.text = "\(snapshot.displayCommittee) · \(snapshot.proposedDate)"
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

    private let titleLabel = DashboardTextLabel(font: .systemFont(ofSize: 16, weight: .bold), color: Theme.textColor)
    private let metadataLabel = DashboardTextLabel(font: .systemFont(ofSize: 12, weight: .medium), color: Theme.emptyLabelTextColor)

    private let reasonStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 6
        stackView.alignment = .leading
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
        backgroundColor = UIColor.white.withAlphaComponent(0.82)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.systemBlue.withAlphaComponent(0.18).cgColor

        addSubview(stackView)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(metadataLabel)
        stackView.addArrangedSubview(reasonStackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 14),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 14),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -14),
            stackView.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor, constant: -14)
        ])
    }

    func configure(with hotBill: HotBillSnapshot) {
        titleLabel.text = hotBill.bill.title
        titleLabel.numberOfLines = 3
        metadataLabel.text = "\(hotBill.bill.stage.title) · \(hotBill.bill.displayCommittee)"

        reasonStackView.arrangedSubviews.forEach { view in
            reasonStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        hotBill.reasons.prefix(2).forEach { reason in
            let horizontalPadding: CGFloat = reason == .recentlyProposed ? 5 : 6
            let label = DashboardPillLabel(fontSize: 10, horizontalPadding: horizontalPadding, verticalPadding: 3)
            label.configure(text: reason.title, color: .systemBlue)
            reasonStackView.addArrangedSubview(label)
        }
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        reasonStackView.addArrangedSubview(spacer)

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

    private let dateLabel = DashboardPillLabel()
    private let titleLabel = DashboardTextLabel(font: .systemFont(ofSize: 15, weight: .semibold), color: Theme.textColor)
    private let metadataLabel = DashboardTextLabel(font: .systemFont(ofSize: 12, weight: .medium), color: Theme.emptyLabelTextColor)
    private let linkLabel = DashboardTextLabel(font: .systemFont(ofSize: 12, weight: .semibold), color: .systemBlue)

    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 6
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
        backgroundColor = UIColor.white.withAlphaComponent(0.72)
        layer.cornerRadius = 8
        layer.borderWidth = 1
        layer.borderColor = UIColor.black.withAlphaComponent(0.05).cgColor

        addSubview(stackView)
        stackView.addArrangedSubview(dateLabel)
        stackView.addArrangedSubview(titleLabel)
        stackView.addArrangedSubview(metadataLabel)
        stackView.addArrangedSubview(linkLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 12),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12)
        ])
    }

    func configure(with enforcement: LawEnforcementSnapshot) {
        dateLabel.configure(text: enforcement.enforcementDate, color: .systemGreen)
        titleLabel.text = enforcement.lawName
        metadataLabel.text = [
            enforcement.ministry,
            enforcement.lawType,
            enforcement.promulgationDate.map { "공포 \($0)" }
        ].compactMap { $0 }.joined(separator: " · ")
        linkLabel.text = enforcement.matchedBillID == nil ? "법령 원문 보기" : "연결된 법안 보기"
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
}

private final class DashboardPillLabel: UILabel {
    private var contentInsets: UIEdgeInsets

    init(fontSize: CGFloat = 11, horizontalPadding: CGFloat = 7, verticalPadding: CGFloat = 4) {
        self.contentInsets = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
        super.init(frame: .zero)
        font = .systemFont(ofSize: fontSize, weight: .semibold)
        numberOfLines = 1
        textAlignment = .center
        layer.cornerRadius = 7
        layer.masksToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(text: String, color: UIColor) {
        self.text = text
        textColor = color
        backgroundColor = color.withAlphaComponent(0.12)
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

private final class DashboardStatusBadgeLabel: UILabel {
    private let contentInsets = UIEdgeInsets(top: 4, left: 7, bottom: 4, right: 7)

    override init(frame: CGRect) {
        super.init(frame: frame)
        font = .systemFont(ofSize: 10, weight: .semibold)
        textColor = .systemRed
        backgroundColor = UIColor.systemRed.withAlphaComponent(0.12)
        textAlignment = .center
        numberOfLines = 1
        layer.cornerRadius = 7
        layer.masksToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
