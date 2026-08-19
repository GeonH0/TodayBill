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
        button.tintColor = Theme.textColor
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
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .gray
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
        stack.spacing = 16
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
        label.textColor = Theme.emptyLabelTextColor
        label.font = Theme.Font.statusMessage
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var retryButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.bordered()
        config.title = "다시 시도"
        config.baseForegroundColor = .systemBlue
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)
        button.configuration = config
        button.addAction(
            UIAction(handler: { [weak self] _ in
                self?.delegate?.retryButtonTapped()
            }),
            for: .touchUpInside
        )
        return button
    }()

    private let coreHeaderStack: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 14
        return stack
    }()

    private let stagePillLabel = DetailPillLabel(fontSize: 13, horizontalPadding: 10, verticalPadding: 5)

    private let bodyTitleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 24, weight: .bold)
        label.textColor = Theme.textColor
        label.numberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }()

    private let metadataStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private let proposedDateRow = DetailMetadataRow(title: "제안일")
    private let committeeRow = DetailMetadataRow(title: "위원회")
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
        stack.spacing = 8
        stack.alignment = .leading
        return stack
    }()

    private let timelineTitleLabel = DetailView.makeSectionTitleLabel(text: "진행 타임라인")

    private let timelineView: TimelineView = {
        let view = TimelineView(steps: [])
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let voteSummaryView = DetailVoteSummaryView()

    private let proposalReasonTitleLabel = DetailView.makeSectionTitleLabel(text: "제안 이유")

    var proposalReasonExpandableView: ExpandableLabelView = {
        let view = ExpandableLabelView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let keyContentTitleLabel = DetailView.makeSectionTitleLabel(text: "주요 내용")

    private let keyContentLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
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
        scrollView.addSubview(containerView)
        containerView.addSubview(mainStackView)
        containerView.addSubview(statusStackView)

        statusStackView.addArrangedSubview(loadingIndicator)
        statusStackView.addArrangedSubview(statusLabel)
        statusStackView.addArrangedSubview(retryButton)

        let stageRow = UIStackView(arrangedSubviews: [stagePillLabel, UIView()])
        stageRow.axis = .horizontal
        stageRow.alignment = .leading

        coreHeaderStack.addArrangedSubview(stageRow)
        coreHeaderStack.addArrangedSubview(bodyTitleLabel)
        mainStackView.addArrangedSubview(coreHeaderStack)

        insightSectionStack.addArrangedSubview(DetailView.makeSectionTitleLabel(text: "주목 포인트"))
        insightSectionStack.addArrangedSubview(insightChipStackView)
        mainStackView.addArrangedSubview(insightSectionStack)

        let timelineStack = UIStackView(arrangedSubviews: [timelineTitleLabel, timelineView])
        timelineStack.axis = .vertical
        timelineStack.spacing = 10
        mainStackView.addArrangedSubview(DetailCardView(contentView: timelineStack))

        voteSummaryView.isHidden = true

        let proposalReasonStack = UIStackView(arrangedSubviews: [proposalReasonTitleLabel, proposalReasonExpandableView])
        proposalReasonStack.axis = .vertical
        proposalReasonStack.spacing = 10
        mainStackView.addArrangedSubview(DetailCardView(contentView: proposalReasonStack))

        mainStackView.addArrangedSubview(voteSummaryView)

        metadataStackView.addArrangedSubview(proposedDateRow)
        metadataStackView.addArrangedSubview(committeeRow)
        metadataStackView.addArrangedSubview(proposerRow)
        metadataStackView.addArrangedSubview(cosponsorRow)
        mainStackView.addArrangedSubview(DetailCardView(contentView: metadataStackView))

        let keyContentStack = UIStackView(arrangedSubviews: [keyContentTitleLabel, keyContentLabel])
        keyContentStack.axis = .vertical
        keyContentStack.spacing = 10
        mainStackView.addArrangedSubview(DetailCardView(contentView: keyContentStack))

        mainStackView.addArrangedSubview(detailLinkButton)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            stickyHeaderView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            stickyHeaderView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stickyHeaderView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stickyHeaderView.heightAnchor.constraint(equalToConstant: 56),

            backButton.leadingAnchor.constraint(equalTo: stickyHeaderView.leadingAnchor, constant: 8),
            backButton.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            favoriteButton.trailingAnchor.constraint(equalTo: stickyHeaderView.trailingAnchor, constant: -8),
            favoriteButton.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 44),
            favoriteButton.heightAnchor.constraint(equalToConstant: 44),

            headerTitleLabel.leadingAnchor.constraint(equalTo: backButton.trailingAnchor, constant: 4),
            headerTitleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -4),
            headerTitleLabel.centerYAnchor.constraint(equalTo: stickyHeaderView.centerYAnchor),

            scrollView.topAnchor.constraint(equalTo: stickyHeaderView.bottomAnchor),
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: bottomAnchor),

            containerView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            containerView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            mainStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            mainStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 18),
            mainStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -18),
            mainStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -24),

            detailLinkButton.heightAnchor.constraint(equalToConstant: 48),

            statusStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 32),
            statusStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -32),
            statusStackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }

    func update(with bill: Row, proposalReason: String, keyContent: String) {
        update(with: BillSnapshot(row: bill), proposalReason: proposalReason, keyContent: keyContent)
    }

    func update(with snapshot: BillSnapshot, proposalReason: String?, keyContent: String?) {
        showContent()

        headerTitleLabel.text = snapshot.title
        bodyTitleLabel.text = snapshot.title
        stagePillLabel.configure(text: snapshot.stage.title, color: color(for: snapshot.stage))
        updateFavoriteButton(isFavorite: snapshot.isFavorite)

        proposedDateRow.configure(value: BillSnapshot.nonEmpty(snapshot.proposedDate) ?? "미확인")
        committeeRow.configure(value: snapshot.displayCommittee)
        proposerRow.configure(value: representativeProposerText(for: snapshot))
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
        statusStackView.isHidden = false
        statusLabel.text = message
        retryButton.isHidden = true
        loadingIndicator.startAnimating()
    }

    func showError(_ message: String) {
        mainStackView.isHidden = true
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
            let label = DetailPillLabel(fontSize: 12, horizontalPadding: 9, verticalPadding: 5)
            label.configure(text: reason.title, color: .systemBlue)
            insightChipStackView.addArrangedSubview(label)
        }

        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        insightChipStackView.addArrangedSubview(spacer)
    }

    private func updateFavoriteButton(isFavorite: Bool) {
        let imageName = isFavorite ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorite ? .systemYellow : .gray
        favoriteButton.accessibilityLabel = isFavorite ? "추적 해제" : "추적 추가"
    }

    private func configureDetailLink(url: URL?) {
        detailLinkURL = url

        var config = UIButton.Configuration.filled()
        config.title = url == nil ? "원문 링크 없음" : "원문 보기"
        config.cornerStyle = .fixed
        config.background.cornerRadius = Theme.Radius.medium
        config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16)
        config.baseBackgroundColor = url == nil ? UIColor.systemGray5 : UIColor.systemBlue
        config.baseForegroundColor = url == nil ? Theme.emptyLabelTextColor : .white
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.systemFont(ofSize: 17, weight: .bold)
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

    private func representativeProposerText(for snapshot: BillSnapshot) -> String {
        guard let proposer = BillSnapshot.nonEmpty(snapshot.proposer) else {
            return "미확인"
        }

        let trimmedProposer = proposer.replacingOccurrences(
            of: #"\s*(외|등)\s*\d+\s*인.*$"#,
            with: "",
            options: .regularExpression
        )
        let separators = CharacterSet(charactersIn: ",;ㆍ·\n")
        if let first = trimmedProposer.components(separatedBy: separators)
            .map({ $0.trimmingCharacters(in: .whitespacesAndNewlines) })
            .first(where: { !$0.isEmpty && $0 != "-" }) {
            return first
        }
        return proposer
    }

    private func color(for stage: BillStage) -> UIColor {
        switch stage {
        case .proposed:
            return .systemBlue
        case .committee:
            return .systemTeal
        case .lawReview:
            return .systemIndigo
        case .plenary:
            return .systemOrange
        case .completed:
            return .systemGreen
        case .unknown:
            return .systemGray
        }
    }

    private func makeBodyText(from text: String, isPlaceholder: Bool = false) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        let attributes: [NSAttributedString.Key: Any] = [
            .paragraphStyle: paragraphStyle,
            .font: Theme.Font.bodyText,
            .foregroundColor: isPlaceholder ? Theme.emptyLabelTextColor : Theme.textColor
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }

    private static func makeSectionTitleLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.font = Theme.Font.sectionTitle
        label.textColor = Theme.textColor
        label.numberOfLines = 1
        return label
    }
}

private final class DetailCardView: UIView {
    init(contentView: UIView) {
        super.init(frame: .zero)
        backgroundColor = Theme.surfaceElevated
        layer.cornerRadius = Theme.Radius.medium
        layer.masksToBounds = true
        addSubview(contentView)
        contentView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            contentView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private final class DetailVoteSummaryView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "본회의 표결 결과"
        label.font = Theme.Font.sectionTitle
        label.textColor = Theme.textColor
        label.numberOfLines = 1
        return label
    }()

    private let resultLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metaTextStrong
        label.textColor = .systemGreen
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 30, weight: .bold)
        label.textColor = Theme.textColor
        return label
    }()

    private let countSuffixLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metaText
        label.textColor = Theme.emptyLabelTextColor
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metaText
        label.textColor = Theme.emptyLabelTextColor
        label.numberOfLines = 1
        return label
    }()

    private let barsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        return stack
    }()

    private let yesRow = VoteCountRow(title: "찬성", color: .systemGreen)
    private let noRow = VoteCountRow(title: "반대", color: .systemRed)
    private let blankRow = VoteCountRow(title: "기권", color: .systemGray)
    private let absentRow = VoteCountRow(title: "불참", color: .systemGray3)

    private let contentStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 12
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
        backgroundColor = Theme.surfaceElevated
        layer.cornerRadius = Theme.Radius.medium
        layer.masksToBounds = true

        addSubview(contentStackView)

        let headerStack = UIStackView(arrangedSubviews: [titleLabel, resultLabel])
        headerStack.axis = .horizontal
        headerStack.alignment = .firstBaseline
        headerStack.spacing = 8

        barsStackView.addArrangedSubview(yesRow)
        barsStackView.addArrangedSubview(noRow)
        barsStackView.addArrangedSubview(blankRow)
        barsStackView.addArrangedSubview(absentRow)

        let countStack = UIStackView(arrangedSubviews: [countLabel, countSuffixLabel, UIView()])
        countStack.axis = .horizontal
        countStack.alignment = .lastBaseline
        countStack.spacing = 6

        contentStackView.addArrangedSubview(headerStack)
        contentStackView.addArrangedSubview(countStack)
        contentStackView.addArrangedSubview(metaLabel)
        contentStackView.addArrangedSubview(barsStackView)

        NSLayoutConstraint.activate([
            contentStackView.topAnchor.constraint(equalTo: topAnchor, constant: 16),
            contentStackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            contentStackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            contentStackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -16)
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

        let denominator = max(summary.memberTotalCount, summary.voteTotalCount, 1)
        yesRow.configure(count: summary.yesCount, denominator: denominator)
        noRow.configure(count: summary.noCount, denominator: denominator)
        blankRow.configure(count: summary.blankCount, denominator: denominator)
        absentRow.configure(count: summary.absentCount, denominator: denominator)
    }
}

private final class VoteCountRow: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metaText
        label.textColor = Theme.emptyLabelTextColor
        return label
    }()

    private let countLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metaTextStrong
        label.textColor = Theme.textColor
        label.textAlignment = .right
        return label
    }()

    private let progressView = UIProgressView(progressViewStyle: .bar)

    init(title: String, color: UIColor) {
        super.init(frame: .zero)
        titleLabel.text = title
        progressView.progressTintColor = color
        progressView.trackTintColor = Theme.separator
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        let labelStack = UIStackView(arrangedSubviews: [titleLabel, countLabel])
        labelStack.axis = .horizontal
        labelStack.spacing = 8

        let stack = UIStackView(arrangedSubviews: [labelStack, progressView])
        stack.axis = .vertical
        stack.spacing = 5
        stack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor),
            progressView.heightAnchor.constraint(equalToConstant: 4)
        ])
    }

    func configure(count: Int, denominator: Int) {
        countLabel.text = "\(count)"
        progressView.setProgress(Float(count) / Float(max(denominator, 1)), animated: false)
    }
}

private final class DetailMetadataRow: UIStackView {
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metaTextStrong
        label.textColor = Theme.emptyLabelTextColor
        label.setContentHuggingPriority(.required, for: .horizontal)
        return label
    }()

    private let valueLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.rowValue
        label.textColor = Theme.textColor
        label.numberOfLines = 0
        return label
    }()

    init(title: String) {
        super.init(frame: .zero)
        axis = .horizontal
        alignment = .firstBaseline
        spacing = 12
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

private final class DetailPillLabel: UILabel {
    private let textInsets: UIEdgeInsets

    init(fontSize: CGFloat, horizontalPadding: CGFloat, verticalPadding: CGFloat) {
        self.textInsets = UIEdgeInsets(
            top: verticalPadding,
            left: horizontalPadding,
            bottom: verticalPadding,
            right: horizontalPadding
        )
        super.init(frame: .zero)
        font = .systemFont(ofSize: fontSize, weight: .semibold)
        numberOfLines = 1
        layer.cornerRadius = Theme.Radius.small
        layer.masksToBounds = true
        setContentHuggingPriority(.required, for: .horizontal)
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
        super.drawText(in: rect.inset(by: textInsets))
    }

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(
            width: size.width + textInsets.left + textInsets.right,
            height: size.height + textInsets.top + textInsets.bottom
        )
    }
}
