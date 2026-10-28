//
//  DetailView.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import UIKit

protocol DetailViewDelegate: AnyObject {
    func backButtonTapped()
    func favoriteButtonTapped()
    func detailLinkButtonTapped(with url: URL)
    func retryButtonTapped()
}

/// 법안 상세. Header block (배지 · 제목 · 메타) sits directly on the grey background;
/// everything below is a white card. The 원문 보기 action is pinned to the bottom rather
/// than scrolling away at the end of the page.
final class DetailView: UIView {

    private let stickyHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var backButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = Theme.textSecondary
        button.accessibilityLabel = "뒤로가기"
        button.addAction(
            UIAction(handler: { [weak self] _ in
                self?.delegate?.backButtonTapped()
            }),
            for: .touchUpInside
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let headerTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.navTitle
        label.textColor = Theme.textColor
        label.textAlignment = .center
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.alpha = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.addAction(
            UIAction(handler: { [weak self] _ in
                self?.delegate?.favoriteButtonTapped()
            }),
            for: .touchUpInside
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.alwaysBounceVertical = true
        scrollView.showsVerticalScrollIndicator = false
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        return scrollView
    }()

    private let containerView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let mainStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = Theme.Spacing.section
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let statusStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.isHidden = true
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        return indicator
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.textMuted
        label.font = Theme.Font.statusMessage
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "다시 시도"
        config.baseForegroundColor = Theme.accent
        config.background.backgroundColor = Theme.accentSoft
        config.background.cornerRadius = Theme.Radius.chip
        config.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 18, bottom: 10, trailing: 18)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.Font.chip
            return outgoing
        }
        button.configuration = config
        button.addAction(
            UIAction(handler: { [weak self] _ in
                self?.delegate?.retryButtonTapped()
            }),
            for: .touchUpInside
        )
        return button
    }()

    // MARK: Header block

    private let coreHeaderStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
        return stack
    }()

    private let stageBadgeLabel = BadgeLabel(horizontalPadding: 9)
    private let ageBadgeLabel = BadgeLabel(horizontalPadding: 9)

    private let bodyTitleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.detailTitle
        label.textColor = Theme.textColor
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let headerMetaLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.rowLabel
        label.textColor = Theme.textSecondary
        label.numberOfLines = 0
        return label
    }()

    // MARK: Cards

    private let metadataStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()

    private let proposedDateRow = DetailMetadataRow(title: "제안일")
    private let committeeRow = DetailMetadataRow(title: "소관위원회")
    private let proposerRow = DetailMetadataRow(title: "대표발의자")
    private let cosponsorRow = DetailMetadataRow(title: "공동발의 수")

    private let insightSectionStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 10
        return stack
    }()

    private let insightChipStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .leading
        return stack
    }()

    private let timelineView: TimelineView = {
        let view = TimelineView(steps: [])
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let voteSummaryView = DetailVoteSummaryView()

    var proposalReasonExpandableView: ExpandableLabelView = {
        let view = ExpandableLabelView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let keyContentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    // MARK: Sticky action

    private let bottomBarView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.backgroundColor
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private lazy var detailLinkButton: UIButton = {
        let button = UIButton(type: .system)
        button.addAction(
            UIAction(handler: { [weak self] _ in
                guard let url = self?.detailLinkURL else { return }
                self?.delegate?.detailLinkButtonTapped(with: url)
            }),
            for: .touchUpInside
        )
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private var detailLinkURL: URL?

    weak var delegate: DetailViewDelegate?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViewHierarchy()
        setupConstraints()
        updateFavoriteButton(isFavorite: false)
        configureDetailLink(url: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupViewHierarchy() {
        backgroundColor = Theme.backgroundColor

        addSubview(stickyHeaderView)
        stickyHeaderView.addSubview(backButton)
        stickyHeaderView.addSubview(headerTitleLabel)
        stickyHeaderView.addSubview(favoriteButton)

        addSubview(scrollView)
        addSubview(bottomBarView)
        bottomBarView.addSubview(detailLinkButton)

        scrollView.addSubview(containerView)
        containerView.addSubview(mainStackView)
        containerView.addSubview(statusStackView)

        statusStackView.addArrangedSubview(loadingIndicator)
        statusStackView.addArrangedSubview(statusLabel)
        statusStackView.addArrangedSubview(retryButton)

        let badgeRow = UIStackView(arrangedSubviews: [stageBadgeLabel, ageBadgeLabel, UIView()])
        badgeRow.axis = .horizontal
        badgeRow.spacing = 6
        badgeRow.alignment = .center

        coreHeaderStack.addArrangedSubview(badgeRow)
        coreHeaderStack.addArrangedSubview(bodyTitleLabel)
        coreHeaderStack.addArrangedSubview(headerMetaLabel)
        mainStackView.addArrangedSubview(coreHeaderStack)

        insightSectionStack.addArrangedSubview(Self.makeSectionTitleLabel(text: "주목 포인트"))
        insightSectionStack.addArrangedSubview(insightChipStackView)
        mainStackView.addArrangedSubview(CardView(contentView: insightSectionStack))

        mainStackView.addArrangedSubview(
            CardView(contentView: Self.makeSection(title: "진행 경과", content: timelineView, spacing: 16))
        )

        mainStackView.addArrangedSubview(
            CardView(contentView: Self.makeSection(title: "제안 이유", content: proposalReasonExpandableView))
        )

        voteSummaryView.isHidden = true
        mainStackView.addArrangedSubview(voteSummaryView)

        metadataStackView.addArrangedSubview(proposedDateRow)
        metadataStackView.addArrangedSubview(HairlineView())
        metadataStackView.addArrangedSubview(committeeRow)
        metadataStackView.addArrangedSubview(HairlineView())
        metadataStackView.addArrangedSubview(proposerRow)
        metadataStackView.addArrangedSubview(HairlineView())
        metadataStackView.addArrangedSubview(cosponsorRow)
        // Rows carry their own 15pt vertical padding, so the card only needs side gutters.
        mainStackView.addArrangedSubview(
            CardView(
                contentView: metadataStackView,
                horizontalPadding: Theme.Spacing.cardPadding,
                verticalPadding: 5
            )
        )

        mainStackView.addArrangedSubview(
            CardView(contentView: Self.makeSection(title: "주요 내용", content: keyContentLabel))
        )
    }

    private func setupConstraints() {
        let screenInset = Theme.Spacing.screenHorizontal

        NSLayoutConstraint.activate([
            stickyHeaderView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stickyHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stickyHeaderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stickyHeaderView.heightAnchor.constraint(equalToConstant: 48),

            backButton.leadingAnchor.constraint(equalTo: stickyHeaderView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: Theme.Spacing.touchTarget),
            backButton.heightAnchor.constraint(equalToConstant: Theme.Spacing.touchTarget),

            favoriteButton.trailingAnchor.constraint(equalTo: stickyHeaderView.trailingAnchor, constant: -8),
            favoriteButton.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: Theme.Spacing.touchTarget),
            favoriteButton.heightAnchor.constraint(equalToConstant: Theme.Spacing.touchTarget),

            headerTitleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            headerTitleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -4),
            headerTitleLabel.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: stickyHeaderView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomBarView.topAnchor),

            bottomBarView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bottomBarView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bottomBarView.bottomAnchor.constraint(equalTo: bottomAnchor),

            detailLinkButton.topAnchor.constraint(equalTo: bottomBarView.topAnchor, constant: 12),
            detailLinkButton.leadingAnchor.constraint(equalTo: bottomBarView.leadingAnchor, constant: screenInset),
            detailLinkButton.trailingAnchor.constraint(equalTo: bottomBarView.trailingAnchor, constant: -screenInset),
            detailLinkButton.bottomAnchor.constraint(
                equalTo: safeAreaLayoutGuide.bottomAnchor,
                constant: -12
            ),
            detailLinkButton.heightAnchor.constraint(equalToConstant: 54),

            containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 4),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: screenInset),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -screenInset),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),

            statusStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            statusStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            statusStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }

    func update(with bill: Row, proposalReason: String, keyContent: String) {
        update(
            with: BillSnapshot(row: bill),
            proposalReason: proposalReason,
            keyContent: keyContent,
            representative: nil
        )
    }

    func update(
        with snapshot: BillSnapshot,
        proposalReason: String?,
        keyContent: String?,
        representative: Representative? = nil
    ) {
        showContent()

        headerTitleLabel.text = snapshot.title
        bodyTitleLabel.attributedText = Self.makeTitleText(snapshot.title)
        stageBadgeLabel.configure(text: snapshot.stage.title, style: snapshot.stage.badgeStyle)
        ageBadgeLabel.configure(text: "제\(snapshot.age)대 국회", style: .neutral)
        headerMetaLabel.text = headerMetaText(for: snapshot)
        updateFavoriteButton(isFavorite: snapshot.isFavorite)

        proposedDateRow.configure(value: BillSnapshot.nonEmpty(snapshot.proposedDate) ?? "미확인")
        committeeRow.configure(value: snapshot.displayCommittee)
        proposerRow.configure(
            value: RepresentativeLookup.displayText(
                proposer: snapshot.proposer,
                representative: representative
            )
        )
        cosponsorRow.configure(value: "\(max(snapshot.cosponsorCount - 1, 0))명")

        configureInsights(snapshot.detailInsightReasons())
        timelineView.updateSteps(snapshot.detailTimelineSteps)

        let proposalText = BillSnapshot.nonEmpty(proposalReason) ?? "요약 준비 중"
        proposalReasonExpandableView.configure(with: proposalText)

        let keyText = BillSnapshot.nonEmpty(keyContent) ?? "요약 준비 중"
        keyContentLabel.attributedText = makeBodyText(from: keyText, isPlaceholder: keyText == "요약 준비 중")

        configureDetailLink(url: validatedDetailURL(from: snapshot.detailLink))
    }

    func updateVoteSummary(_ summary: BillVoteSummary?) {
        guard let summary, summary.hasVotes else {
            voteSummaryView.isHidden = true
            return
        }

        voteSummaryView.isHidden = false
        voteSummaryView.configure(with: summary)
    }

    func showLoading(_ message: String) {
        mainStackView.isHidden = true
        bottomBarView.isHidden = true
        statusStackView.isHidden = false
        statusLabel.text = message
        retryButton.isHidden = true
        loadingIndicator.startAnimating()
    }

    func showError(_ message: String) {
        mainStackView.isHidden = true
        bottomBarView.isHidden = true
        statusStackView.isHidden = false
        statusLabel.text = message
        retryButton.isHidden = false
        loadingIndicator.stopAnimating()
    }

    func showSummaryUnavailable(for bill: Row) {
        update(
            with: bill,
            proposalReason: "원문에서 요약 정보를 가져오지 못했습니다.",
            keyContent: "국회 원문 보기에서 원문을 확인할 수 있습니다."
        )
    }

    func showSummaryUnavailable(for snapshot: BillSnapshot) {
        update(
            with: snapshot,
            proposalReason: "원문에서 요약 정보를 가져오지 못했습니다.",
            keyContent: "국회 원문 보기에서 원문을 확인할 수 있습니다."
        )
    }

    private func showContent() {
        mainStackView.isHidden = false
        bottomBarView.isHidden = false
        statusStackView.isHidden = true
        loadingIndicator.stopAnimating()
    }

    private func configureInsights(_ reasons: [HotBillReason]) {
        insightChipStackView.arrangedSubviews.forEach { view in
            insightChipStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        insightSectionStack.isHidden = reasons.isEmpty
        reasons.forEach { reason in
            let badge = BadgeLabel(horizontalPadding: 9)
            badge.configure(text: reason.title, style: .progress)
            insightChipStackView.addArrangedSubview(badge)
        }

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        insightChipStackView.addArrangedSubview(spacer)
    }

    private func updateFavoriteButton(isFavorite: Bool) {
        let imageName = isFavorite ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorite ? Theme.accent : Theme.textDisabled
        favoriteButton.accessibilityLabel = isFavorite ? "추적 해제" : "추적 추가"
    }

    private func configureDetailLink(url: URL?) {
        detailLinkURL = url

        var config = UIButton.Configuration.filled()
        config.title = url == nil ? "원문 링크 없음" : "원문 보기"
        config.cornerStyle = .fixed
        config.background.cornerRadius = Theme.Radius.button
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.baseBackgroundColor = url == nil ? Theme.fill : Theme.accent
        config.baseForegroundColor = url == nil ? Theme.textMuted : .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.Font.button
            return outgoing
        }

        detailLinkButton.configuration = config
        detailLinkButton.isEnabled = url != nil
        detailLinkButton.accessibilityLabel = config.title
    }

    private func validatedDetailURL(from value: String) -> URL? {
        guard let url = URL(string: value),
              let scheme = url.scheme?.lowercased(),
              ["http", "https"].contains(scheme),
              url.host != nil else {
            return nil
        }
        return url
    }

    /// "김서연 의원 등 12인 · 의안번호 2201847"
    private func headerMetaText(for snapshot: BillSnapshot) -> String {
        let billNoText = BillSnapshot.nonEmpty(snapshot.billNo).map { "의안번호 \($0)" }
        return [BillSnapshot.nonEmpty(snapshot.displayProposer), billNoText]
            .compactMap { $0 }
            .joined(separator: " · ")
    }

    private func makeBodyText(from text: String, isPlaceholder: Bool = false) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Theme.Metric.bodyLineSpacing
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: Theme.Font.body,
            .foregroundColor: isPlaceholder ? Theme.textMuted : Theme.textSecondary
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }

    /// The 24pt title is set at line-height 1.35 with tight tracking, per the type spec.
    private static func makeTitleText(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 24 * 0.35
        return NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: Theme.Font.detailTitle,
                .foregroundColor: Theme.textColor,
                .kern: -0.5
            ]
        )
    }

    private static func makeSectionTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Theme.Font.sectionHeading
        label.textColor = Theme.textColor
        label.numberOfLines = 1
        return label
    }

    private static func makeSection(title: String, content: UIView, spacing: CGFloat = 10) -> UIStackView {
        let stack = UIStackView(arrangedSubviews: [makeSectionTitleLabel(text: title), content])
        stack.axis = .vertical
        stack.spacing = spacing
        return stack
    }
}

/// 본회의 표결 결과: one headline number, one stacked bar, one legend.
private final class DetailVoteSummaryView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "본회의 표결 결과"
        label.font = Theme.Font.sectionHeading
        label.textColor = Theme.textColor
        label.numberOfLines = 1
        return label
    }()

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.captionStrong
        label.textColor = Theme.success
        label.textAlignment = .right
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metricL
        label.textColor = Theme.textColor
        return label
    }()

    private let countSuffixLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.rowValue
        label.textColor = Theme.textMuted
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.meta
        label.textColor = Theme.textMuted
        label.numberOfLines = 1
        return label
    }()

    private let barStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 3
        stack.distribution = .fill
        return stack
    }()

    private let legendStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 16
        stack.alignment = .center
        return stack
    }()

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 16
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

        addSubview(contentStackView)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, UIView(), resultLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .firstBaseline
        headerStack.spacing = 8

        let countStack = UIStackView(arrangedSubviews: [countLabel, countSuffixLabel, UIView()])
        countStack.axis = .horizontal
        countStack.alignment = .lastBaseline
        countStack.spacing = 6

        contentStackView.addArrangedSubview(headerStack)
        contentStackView.addArrangedSubview(countStack)
        contentStackView.addArrangedSubview(barStackView)
        contentStackView.addArrangedSubview(legendStackView)
        contentStackView.addArrangedSubview(metaLabel)
        contentStackView.setCustomSpacing(8, after: barStackView)

        let padding = Theme.Spacing.cardPadding
        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: padding),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: padding),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -padding),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -padding),
            barStackView.heightAnchor.constraint(equalToConstant: 8)
        ])
    }

    func configure(with summary: BillVoteSummary) {
        resultLabel.text = summary.result
        resultLabel.isHidden = BillSnapshot.nonEmpty(summary.result) == nil
        countLabel.text = "\(summary.yesCount)"
        countSuffixLabel.text = "/ 재적 \(summary.memberTotalCount)"

        let dateText = BillSnapshot.nonEmpty(summary.processedDate)
            .map { " · \($0)" } ?? ""
        metaLabel.text = "총투표 \(summary.voteTotalCount)명\(dateText)"

        // 찬성 초록 · 반대 중간 회색 · 기권 옅은 회색 - opposition is a lightness step, not a red.
        let segments: [(String, Int, UIColor)] = [
            ("찬성", summary.yesCount, Theme.success),
            ("반대", summary.noCount, Theme.textDisabled),
            ("기권", summary.blankCount, Theme.fill)
        ]
        rebuildBar(with: segments)
        rebuildLegend(with: segments)
    }

    private func rebuildBar(with segments: [(String, Int, UIColor)]) {
        barStackView.arrangedSubviews.forEach { view in
            barStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        let total = max(segments.reduce(0) { $0 + $1.1 }, 1)
        for (_, count, color) in segments where count > 0 {
            let segment = UIView()
            segment.backgroundColor = color
            segment.layer.cornerRadius = 4
            segment.layer.masksToBounds = true
            barStackView.addArrangedSubview(segment)
            // Widths are proportional to the vote split, so the bar is the chart.
            segment.widthAnchor.constraint(
                equalTo: barStackView.widthAnchor,
                multiplier: CGFloat(count) / CGFloat(total),
                constant: -2
            ).isActive = true
        }
    }

    private func rebuildLegend(with segments: [(String, Int, UIColor)]) {
        legendStackView.arrangedSubviews.forEach { view in
            legendStackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }

        for (title, count, color) in segments {
            legendStackView.addArrangedSubview(VoteLegendItemView(title: title, count: count, color: color))
        }
        legendStackView.addArrangedSubview(UIView())
    }
}

private final class VoteLegendItemView: UIView {
    init(title: String, count: Int, color: UIColor) {
        super.init(frame: .zero)

        let dotView = UIView()
        dotView.backgroundColor = color
        dotView.layer.cornerRadius = 4
        dotView.translatesAutoresizingMaskIntoConstraints = false

        let label = UILabel()
        label.text = "\(title) \(count)"
        label.font = Theme.Font.caption
        label.textColor = Theme.textSecondary

        let stack = UIStackView(arrangedSubviews: [dotView, label])
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stack)

        NSLayoutConstraint.activate([
            dotView.widthAnchor.constraint(equalToConstant: 8),
            dotView.heightAnchor.constraint(equalToConstant: 8),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

/// Key on the left in muted 14/600, value on the right in 14/700 - split rows, hairline between.
private final class DetailMetadataRow: UIStackView {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.rowLabel
        label.textColor = Theme.textMuted
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.setContentCompressionResistancePriority(.required, for: .horizontal)
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.rowValue
        label.textColor = Theme.textColor
        label.textAlignment = .right
        label.numberOfLines = 0
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .firstBaseline
        spacing = 12
        isLayoutMarginsRelativeArrangement = true
        layoutMargins = UIEdgeInsets(top: 15, left: 0, bottom: 15, right: 0)
        nameLabel.text = title
        addArrangedSubview(nameLabel)
        addArrangedSubview(valueLabel)
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(value: String) {
        valueLabel.text = value
    }
}
