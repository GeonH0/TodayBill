//
//  StarBillViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import UIKit

final class StarBillViewController: UIViewController {
    private let viewModel = FavoritesViewModel()
    private var sections: [BillTrackingSection] = []

    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero, style: .plain)
        tableView.register(TrackingBillCell.self, forCellReuseIdentifier: TrackingBillCell.reuseIdentifier)
        tableView.backgroundColor = Theme.backgroundColor
        tableView.separatorStyle = .none
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 150
        tableView.sectionHeaderTopPadding = Theme.Spacing.section
        tableView.showsVerticalScrollIndicator = false
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 24, right: 0)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

    private let headerView = TrackingHeaderView()

    private let statusStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.isHidden = true
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

    override func viewDidLoad() {
        super.viewDidLoad()
        // The 26/800 title lives in the table header, so the bar carries only the refresh action.
        title = nil
        view.backgroundColor = Theme.backgroundColor
        configureNavigationBarAppearance()
        setupUI()
        bindViewModel()
        viewModel.load(refresh: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.load(refresh: false)
    }

    private func configureNavigationBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.backgroundColor
        appearance.shadowColor = .clear
        navigationItem.standardAppearance = appearance
        navigationItem.scrollEdgeAppearance = appearance
        navigationItem.compactAppearance = appearance
    }

    private func setupUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshButtonTapped)
        )
        navigationItem.rightBarButtonItem?.tintColor = Theme.textSecondary
        navigationItem.rightBarButtonItem?.accessibilityLabel = "새로고침"

        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableHeaderView = headerView

        view.addSubview(tableView)
        view.addSubview(statusStackView)
        statusStackView.addArrangedSubview(loadingIndicator)
        statusStackView.addArrangedSubview(statusLabel)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            statusStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            statusStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            statusStackView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .idle:
                break
            case .loading(let message):
                self.statusLabel.text = message
                self.statusStackView.isHidden = false
                self.loadingIndicator.startAnimating()
            case .loaded(let sections):
                self.sections = sections
                self.updateHeader()
                self.tableView.reloadData()
                self.statusStackView.isHidden = true
                self.loadingIndicator.stopAnimating()
                self.tableView.isHidden = false
            case .empty(let message):
                self.sections = []
                self.updateHeader()
                self.tableView.reloadData()
                self.statusLabel.text = message
                self.statusStackView.isHidden = false
                self.loadingIndicator.stopAnimating()
            case .error(let message):
                self.statusLabel.text = message
                self.statusStackView.isHidden = false
                self.loadingIndicator.stopAnimating()
            }
        }
    }

    @objc private func refreshButtonTapped() {
        viewModel.load(refresh: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutHeader(force: false)
    }

    private func updateHeader() {
        headerView.configure(with: sections.flatMap { $0.snapshots })
        layoutHeader(force: true)
    }

    /// A self-sizing table header has to be measured by hand before the table lays out.
    /// UIKit은 헤더의 폭만 테이블에 맞춰주고 높이는 기존 frame을 그대로 쓴다. 폭이 바뀌면
    /// (기기 접기·펴기, 회전) 이전 폭 기준 높이가 남으므로 그때마다 다시 재야 한다.
    private func layoutHeader(force: Bool) {
        let width = tableView.bounds.width > 0 ? tableView.bounds.width : view.bounds.width
        guard width > 0, force || headerView.frame.width != width else { return }
        let height = headerView.systemLayoutSizeFitting(
            CGSize(width: width, height: UIView.layoutFittingCompressedSize.height),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel
        ).height
        headerView.frame = CGRect(x: 0, y: 0, width: width, height: height)
        tableView.tableHeaderView = headerView
    }
}

extension StarBillViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].snapshots.count
    }

    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let container = UIView()
        container.backgroundColor = Theme.backgroundColor
        let label = SectionHeaderLabel(text: sections[section].title)
        container.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(
                equalTo: container.leadingAnchor,
                constant: Theme.Spacing.screenHorizontal
            ),
            label.trailingAnchor.constraint(
                lessThanOrEqualTo: container.trailingAnchor,
                constant: -Theme.Spacing.screenHorizontal
            ),
            label.topAnchor.constraint(equalTo: container.topAnchor),
            label.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -8)
        ])
        return container
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TrackingBillCell.reuseIdentifier,
            for: indexPath
        ) as? TrackingBillCell else {
            return UITableViewCell()
        }

        let snapshot = sections[indexPath.section].snapshots[indexPath.row]
        cell.configure(with: snapshot)
        cell.onFavoriteTapped = { [weak self] in
            self?.viewModel.toggleFavorite(id: snapshot.billID) {
                self?.viewModel.load(refresh: false)
            }
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let snapshot = sections[indexPath.section].snapshots[indexPath.row]
        viewModel.markStageSeen(id: snapshot.billID)
        let detailViewController = DetailViewController(billID: snapshot.billID, age: snapshot.age)
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}

/// 관심 법안 헤더: 화면 제목 · 한 줄 요약, 그리고 이번 주 변동을 담은 잉크 카드 하나.
private final class TrackingHeaderView: UIView {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "관심 법안"
        label.font = Theme.Font.screenTitle
        label.textColor = Theme.textColor
        return label
    }()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.rowLabel
        label.textColor = Theme.textMuted
        label.numberOfLines = 0
        return label
    }()

    private let highlightCaptionLabel: UILabel = {
        let label = UILabel()
        label.text = "확인하지 않은 변동"
        label.font = Theme.Font.badge
        label.textColor = Theme.onInkSecondary
        return label
    }()

    private let highlightMessageLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.listTitle
        label.textColor = Theme.onInkPrimary
        label.numberOfLines = 0
        return label
    }()

    private let highlightCardView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.inkSurface
        view.layer.cornerRadius = Theme.Radius.card
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView() {
        backgroundColor = Theme.backgroundColor

        let highlightStack = UIStackView(arrangedSubviews: [highlightCaptionLabel, highlightMessageLabel])
        highlightStack.axis = .vertical
        highlightStack.spacing = 2
        highlightStack.translatesAutoresizingMaskIntoConstraints = false
        highlightCardView.addSubview(highlightStack)

        let titleStack = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel])
        titleStack.axis = .vertical
        titleStack.spacing = 4

        let mainStack = UIStackView(arrangedSubviews: [titleStack, highlightCardView])
        mainStack.axis = .vertical
        mainStack.spacing = Theme.Spacing.section
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        addSubview(mainStack)

        let inset = Theme.Spacing.screenHorizontal
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: inset),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -inset),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4),

            highlightStack.topAnchor.constraint(equalTo: highlightCardView.topAnchor, constant: 18),
            highlightStack.leadingAnchor.constraint(equalTo: highlightCardView.leadingAnchor, constant: 20),
            highlightStack.trailingAnchor.constraint(equalTo: highlightCardView.trailingAnchor, constant: -20),
            highlightStack.bottomAnchor.constraint(equalTo: highlightCardView.bottomAnchor, constant: -18)
        ])
    }

    func configure(with snapshots: [BillSnapshot]) {
        let total = snapshots.count
        let inProgress = snapshots.filter { $0.stage != .completed && $0.stage != .unknown }.count
        subtitleLabel.text = total == 0
            ? "아직 담아둔 법안이 없습니다"
            : "\(total)건 중 \(inProgress)건이 심사 진행 중"

        let changed = snapshots.filter { $0.hasUnseenStageChange }.count
        highlightCardView.isHidden = total == 0
        highlightMessageLabel.text = changed == 0
            ? "확인하지 않은 단계 변경이 없습니다"
            : "\(changed)건의 단계가 바뀌었습니다"
    }
}

/// 관심 법안 카드: 제목 · 메타 · 5단계 진행 막대. 진행률은 색이 아니라 채워진 칸 수가 말한다.
private final class TrackingBillCell: UITableViewCell {
    static let reuseIdentifier = "TrackingBillCell"

    var onFavoriteTapped: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.cardHeading
        label.textColor = Theme.textColor
        label.numberOfLines = 2
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.meta
        label.textColor = Theme.textMuted
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let changeBadgeLabel = BadgeLabel()

    private let progressView = StageProgressView()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "star.fill"), for: .normal)
        button.tintColor = Theme.accent
        button.setContentHuggingPriority(.required, for: .horizontal)
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.onFavoriteTapped?()
        }), for: .touchUpInside)
        return button
    }()

    private let cardView: UIView = {
        let view = UIView()
        view.backgroundColor = Theme.cellBackgroundColor
        view.layer.cornerRadius = Theme.Radius.list
        view.layer.masksToBounds = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onFavoriteTapped = nil
    }

    func configure(with snapshot: BillSnapshot) {
        titleLabel.text = snapshot.title
        titleLabel.textColor = snapshot.stage == .unknown ? Theme.textSecondary : Theme.textColor

        let stageText = "\(snapshot.stage.title) 단계"
        metaLabel.text = [stageText, BillSnapshot.nonEmpty(snapshot.proposedDate)]
            .compactMap { $0 }
            .joined(separator: " · ")

        changeBadgeLabel.isHidden = !snapshot.hasUnseenStageChange
        changeBadgeLabel.configure(text: "변경", style: .progress)

        progressView.configure(with: snapshot.stage)
        accessibilityLabel = "\(snapshot.title), \(snapshot.stage.title)"
    }

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        changeBadgeLabel.translatesAutoresizingMaskIntoConstraints = false
        progressView.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(cardView)

        let headerRow = UIStackView(arrangedSubviews: [titleLabel, changeBadgeLabel, favoriteButton])
        headerRow.axis = .horizontal
        headerRow.spacing = 10
        headerRow.alignment = .top

        let textStack = UIStackView(arrangedSubviews: [headerRow, metaLabel])
        textStack.axis = .vertical
        textStack.spacing = 6

        let mainStack = UIStackView(arrangedSubviews: [textStack, progressView])
        mainStack.axis = .vertical
        mainStack.spacing = 12
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        cardView.addSubview(mainStack)

        let inset = Theme.Spacing.screenHorizontal
        let padding = Theme.Spacing.listPadding

        NSLayoutConstraint.activate([
            cardView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 5),
            cardView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: inset),
            cardView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -inset),
            cardView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -5),

            mainStack.topAnchor.constraint(equalTo: cardView.topAnchor, constant: padding),
            mainStack.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: padding),
            mainStack.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -padding),
            mainStack.bottomAnchor.constraint(equalTo: cardView.bottomAnchor, constant: -padding),

            // 행 전체가 상세 화면을 열기 때문에, 별 버튼은 오탭이 나지 않을 만큼 커야 한다.
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }
}
