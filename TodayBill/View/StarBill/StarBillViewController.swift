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
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.register(TrackingBillCell.self, forCellReuseIdentifier: TrackingBillCell.reuseIdentifier)
        tableView.backgroundColor = Theme.backgroundColor
        tableView.separatorStyle = .none
        tableView.translatesAutoresizingMaskIntoConstraints = false
        return tableView
    }()

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
        label.font = .systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "추적"
        view.backgroundColor = Theme.backgroundColor
        setupUI()
        bindViewModel()
        viewModel.load(refresh: true)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
        viewModel.load(refresh: false)
    }

    private func setupUI() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "arrow.clockwise"),
            style: .plain,
            target: self,
            action: #selector(refreshButtonTapped)
        )

        tableView.dataSource = self
        tableView.delegate = self

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
                self.tableView.reloadData()
                self.statusStackView.isHidden = true
                self.loadingIndicator.stopAnimating()
                self.tableView.isHidden = false
            case .empty(let message):
                self.sections = []
                self.tableView.reloadData()
                self.statusLabel.text = message
                self.statusStackView.isHidden = false
                self.loadingIndicator.stopAnimating()
                self.tableView.isHidden = true
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
}

extension StarBillViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].snapshots.count
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        sections[section].title
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        118
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

private final class TrackingBillCell: UITableViewCell {
    static let reuseIdentifier = "TrackingBillCell"

    var onFavoriteTapped: (() -> Void)?

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = Theme.textColor
        label.numberOfLines = 2
        return label
    }()

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .medium)
        label.textColor = Theme.emptyLabelTextColor
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        return label
    }()

    private let stageLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .systemBlue
        return label
    }()

    private let changeBadgeLabel: UILabel = {
        let label = UILabel()
        label.text = "변경"
        label.font = .systemFont(ofSize: 12, weight: .bold)
        label.textColor = .white
        label.backgroundColor = .systemRed
        label.textAlignment = .center
        label.layer.cornerRadius = 6
        label.layer.masksToBounds = true
        label.isHidden = true
        return label
    }()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "star.fill"), for: .normal)
        button.tintColor = .systemYellow
        button.addAction(UIAction(handler: { [weak self] _ in
            self?.onFavoriteTapped?()
        }), for: .touchUpInside)
        return button
    }()

    private let verticalStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 8
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let stageStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 8
        stack.alignment = .center
        return stack
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
        metaLabel.text = "\(snapshot.proposedDate) · \(snapshot.displayCommittee) · \(snapshot.displayProposer)"
        stageLabel.text = "현재 단계: \(snapshot.stage.title)"
        changeBadgeLabel.isHidden = !snapshot.hasUnseenStageChange
        accessibilityLabel = "\(snapshot.title), \(snapshot.stage.title)"
    }

    private func setupUI() {
        backgroundColor = .clear
        selectionStyle = .default
        contentView.backgroundColor = Theme.cellBackgroundColor
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true

        favoriteButton.translatesAutoresizingMaskIntoConstraints = false
        changeBadgeLabel.translatesAutoresizingMaskIntoConstraints = false

        contentView.addSubview(verticalStackView)
        contentView.addSubview(favoriteButton)
        verticalStackView.addArrangedSubview(titleLabel)
        verticalStackView.addArrangedSubview(metaLabel)
        verticalStackView.addArrangedSubview(stageStackView)
        stageStackView.addArrangedSubview(stageLabel)
        stageStackView.addArrangedSubview(changeBadgeLabel)

        NSLayoutConstraint.activate([
            verticalStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 14),
            verticalStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 14),
            verticalStackView.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -12),
            verticalStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -14),

            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32),

            changeBadgeLabel.widthAnchor.constraint(equalToConstant: 42),
            changeBadgeLabel.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
}
