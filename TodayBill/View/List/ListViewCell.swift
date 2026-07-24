//
//  ListViewCell.swift
//  TodayBill
//
//  Created by 김건호 on 1/25/25.
//

import Foundation
import UIKit

protocol ListViewCellDelegate: AnyObject {
    func favoriteButtonTapped(for item: String)
}

final class ListViewCell: UICollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.cardTitle
        label.textColor = Theme.textColor
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "star"), for: .normal)
        button.tintColor = .gray
        button.addAction(
            UIAction(
                handler: { [weak self] _ in
                    guard let self = self, let billID = currentBillID else { return }
                    self.delegate?.favoriteButtonTapped(for: billID)
                }
            ), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()

    private let dateLabel = ListViewCell.makeMetadataLabel()
    private let committeeLabel = ListViewCell.makeMetadataLabel()
    private let proposerLabel = ListViewCell.makeMetadataLabel()

    private let stageLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.smallStrong
        label.textColor = .systemBlue
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        label.textAlignment = .center
        label.layer.cornerRadius = Theme.Radius.small
        label.layer.masksToBounds = true
        label.setContentHuggingPriority(.required, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let metaStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
        stack.distribution = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    weak var delegate: ListViewCellDelegate?
    private var currentItem: StarredBill?
    private var currentSnapshot: BillSnapshot?
    private var currentBillID: String? {
        currentSnapshot?.billID ?? currentItem?.ID
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        contentView.backgroundColor = Theme.cellBackgroundColor
        contentView.layer.cornerRadius = Theme.Radius.small
        contentView.layer.masksToBounds = true
        addSubviews()
        setupConstraints()
    }

    private func addSubviews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(metaStackView)
        metaStackView.addArrangedSubview(stageLabel)
        metaStackView.addArrangedSubview(dateLabel)
        metaStackView.addArrangedSubview(committeeLabel)
        metaStackView.addArrangedSubview(proposerLabel)
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 12),
            titleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8),

            metaStackView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 10),
            metaStackView.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaStackView.trailingAnchor.constraint(lessThanOrEqualTo: favoriteButton.leadingAnchor, constant: -8),
            metaStackView.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -12),

            stageLabel.widthAnchor.constraint(greaterThanOrEqualToConstant: 46),
            stageLabel.heightAnchor.constraint(equalToConstant: 24),

            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -12),
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 12),
            favoriteButton.widthAnchor.constraint(equalToConstant: 30),
            favoriteButton.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    func configure(with bill: StarredBill, isFavorited: Bool) {
        titleLabel.text = bill.name
        currentItem = bill
        currentSnapshot = nil
        stageLabel.text = "저장"
        dateLabel.isHidden = false
        dateLabel.text = "\(bill.age)대"
        committeeLabel.text = "상세에서 단계 확인"
        proposerLabel.text = nil
        contentView.accessibilityLabel = bill.name
        updateFavoriteButton(isFavorited: isFavorited)
    }

    func configure(with snapshot: BillSnapshot, isFavorited: Bool, showsProposedDate: Bool = true) {
        titleLabel.text = snapshot.title
        currentItem = snapshot.toStarredBill()
        currentSnapshot = snapshot
        stageLabel.text = snapshot.stage.title
        dateLabel.isHidden = !showsProposedDate
        dateLabel.text = showsProposedDate ? (snapshot.proposedDate.isEmpty ? "\(snapshot.age)대" : snapshot.proposedDate) : nil
        committeeLabel.text = snapshot.displayCommittee
        proposerLabel.text = snapshot.displayProposer
        contentView.accessibilityLabel = "\(snapshot.title), \(snapshot.stage.title), \(snapshot.displayCommittee)"
        updateFavoriteButton(isFavorited: isFavorited)
    }

    private func updateFavoriteButton(isFavorited: Bool) {
        let imageName = isFavorited ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorited ? .systemYellow : .gray
        favoriteButton.accessibilityLabel = isFavorited ? "즐겨찾기 해제" : "즐겨찾기 추가"
        favoriteButton.accessibilityHint = currentItem?.name
    }

    private func favoriteButtonAction() {
        guard let item = currentBillID else { return }
        delegate?.favoriteButtonTapped(for: item)
    }

    private static func makeMetadataLabel() -> UILabel {
        let label = UILabel()
        label.font = Theme.Font.captionText
        label.textColor = Theme.emptyLabelTextColor
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }
}
