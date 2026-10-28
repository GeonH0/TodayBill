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

/// 법안 카드: 배지 줄 · 법안명 16/700 · 메타 13/500. One card, three lines of hierarchy.
final class ListViewCell: UICollectionViewCell {
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.cardHeading
        label.textColor = Theme.textColor
        label.numberOfLines = 0
        label.adjustsFontForContentSizeCategory = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private lazy var favoriteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "star"), for: .normal)
        button.tintColor = Theme.textDisabled
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

    private let metaLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.meta
        label.textColor = Theme.textMuted
        label.numberOfLines = 1
        label.lineBreakMode = .byTruncatingTail
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let stageBadgeLabel = BadgeLabel()
    private let committeeBadgeLabel = BadgeLabel()

    private let badgeStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.spacing = 6
        stack.alignment = .center
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
        contentView.layer.cornerRadius = Theme.Radius.list
        contentView.layer.masksToBounds = true
        addSubviews()
        setupConstraints()
    }

    private func addSubviews() {
        contentView.addSubview(badgeStackView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(favoriteButton)
        contentView.addSubview(metaLabel)
        badgeStackView.addArrangedSubview(stageBadgeLabel)
        badgeStackView.addArrangedSubview(committeeBadgeLabel)
        badgeStackView.addArrangedSubview(UIView())
    }

    private func setupConstraints() {
        let padding = Theme.Spacing.listPadding

        NSLayoutConstraint.activate([
            badgeStackView.topAnchor.constraint(equalTo: contentView.topAnchor, constant: padding),
            badgeStackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: padding),
            badgeStackView.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8),

            titleLabel.topAnchor.constraint(equalTo: badgeStackView.bottomAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: badgeStackView.leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -padding),

            metaLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            metaLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            metaLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            metaLabel.bottomAnchor.constraint(lessThanOrEqualTo: contentView.bottomAnchor, constant: -padding),

            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            favoriteButton.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            favoriteButton.widthAnchor.constraint(equalToConstant: 32),
            favoriteButton.heightAnchor.constraint(equalToConstant: 32)
        ])
    }

    func configure(with bill: StarredBill, isFavorited: Bool) {
        titleLabel.text = bill.name
        currentItem = bill
        currentSnapshot = nil
        stageBadgeLabel.configure(text: "저장", style: .neutral)
        committeeBadgeLabel.configure(text: "\(bill.age)대", style: .neutral)
        committeeBadgeLabel.isHidden = false
        metaLabel.text = "상세에서 단계 확인"
        contentView.accessibilityLabel = bill.name
        updateFavoriteButton(isFavorited: isFavorited)
    }

    func configure(with snapshot: BillSnapshot, isFavorited: Bool, showsProposedDate: Bool = true) {
        titleLabel.text = snapshot.title
        currentItem = snapshot.toStarredBill()
        currentSnapshot = snapshot
        stageBadgeLabel.configure(text: snapshot.stage.title, style: snapshot.stage.badgeStyle)

        let committee = snapshot.displayCommittee
        committeeBadgeLabel.isHidden = committee.isEmpty
        committeeBadgeLabel.configure(text: committee, style: .neutral)

        // 발의자 · 제안일 - the date is dropped where the section header already states it.
        let dateText = showsProposedDate
            ? BillSnapshot.nonEmpty(snapshot.proposedDate) ?? "\(snapshot.age)대"
            : nil
        metaLabel.text = [BillSnapshot.nonEmpty(snapshot.displayProposer), dateText]
            .compactMap { $0 }
            .joined(separator: " · ")

        contentView.accessibilityLabel = "\(snapshot.title), \(snapshot.stage.title), \(snapshot.displayCommittee)"
        updateFavoriteButton(isFavorited: isFavorited)
    }

    private func updateFavoriteButton(isFavorited: Bool) {
        let imageName = isFavorited ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorited ? Theme.accent : Theme.textDisabled
        favoriteButton.accessibilityLabel = isFavorited ? "즐겨찾기 해제" : "즐겨찾기 추가"
        favoriteButton.accessibilityHint = currentItem?.name
    }
}
