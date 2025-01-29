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
        label.font = .boldSystemFont(ofSize: 16)
        label.textColor = .black
        label.numberOfLines = 0
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
                    guard let self = self, let billID = currentItem?.ID else { return }
                    self.delegate?.favoriteButtonTapped(for: billID)
                }
            ), for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    weak var delegate: ListViewCellDelegate?
    private var currentItem: StarredBill?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.backgroundColor = .white
        contentView.layer.cornerRadius = 8
        contentView.layer.masksToBounds = true
        contentView.layer.borderWidth = 1.0
        contentView.layer.borderColor = UIColor.black.cgColor
        addSubviews()
        setupConstraints()
    }
    
    private func addSubviews() {
        contentView.addSubview(titleLabel)
        contentView.addSubview(favoriteButton)
    }
    
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 8),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(equalTo: favoriteButton.leadingAnchor, constant: -8),
            titleLabel.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -8),
            
            favoriteButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -8),
            favoriteButton.centerYAnchor.constraint(equalTo: contentView.centerYAnchor),
            favoriteButton.widthAnchor.constraint(equalToConstant: 24),
            favoriteButton.heightAnchor.constraint(equalToConstant: 24)
        ])
    }
    
    func configure(with bill: StarredBill, isFavorited: Bool) {
        titleLabel.text = bill.name
        currentItem = bill
        updateFavoriteButton(isFavorited: isFavorited)
    }
    
    private func updateFavoriteButton(isFavorited: Bool) {
        let imageName = isFavorited ? "star.fill" : "star"
        favoriteButton.setImage(UIImage(systemName: imageName), for: .normal)
        favoriteButton.tintColor = isFavorited ? .systemYellow : .gray
    }
    
    private func favoriteButtonAction() {
        guard let item = currentItem?.ID else { return }
        delegate?.favoriteButtonTapped(for: item)
    }
}
