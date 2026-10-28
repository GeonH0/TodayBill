//
//  MainTabBarView.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import Foundation

import UIKit

protocol MainTabBarViewDelegate: AnyObject {
    func tabBarView(_ tabBarView: MainTabBarView, didSelectTabAt index: Int)
}

/// White bar with a 1px top line - no floating pill, no tinted capsule. The selected tab
/// switches the icon from line to fill (or to a heavier stroke where no filled symbol exists)
/// so the state survives without relying on the accent color alone.
final class MainTabBarView: UIView {

    weak var delegate: MainTabBarViewDelegate?

    private var items: [TabItemView] = []
    private var currentSelectedIndex: Int = 0

    private let separatorView: UIView = {
        let separatorView = UIView()
        separatorView.backgroundColor = Theme.border
        return separatorView
    }()

    private let itemStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.alignment = .fill
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addsubviews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private lazy var itemStackHeightConstraint = itemStackView.heightAnchor.constraint(
        equalToConstant: Theme.Metric.tabBarContentHeight - 9
    )

    /// Drops the labels and shortens the bar when the screen is short.
    func setCompact(_ compact: Bool) {
        let content = compact ? 44 : Theme.Metric.tabBarContentHeight
        itemStackHeightConstraint.constant = content - 9
        items.forEach { $0.setCompact(compact) }
    }

    private func addsubviews() {
        backgroundColor = Theme.cellBackgroundColor
        addSubview(separatorView)
        addSubview(itemStackView)

        NSLayoutConstraint.activate([
            itemStackView.topAnchor.constraint(equalTo: topAnchor, constant: 9),
            itemStackView.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 12),
            itemStackView.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -12),
            itemStackHeightConstraint
        ])
    }

    func configure(symbolNames: [String], titles: [String]) {
        items.forEach { $0.removeFromSuperview() }
        items = []

        for (index, symbolName) in symbolNames.enumerated() {
            let title = titles.indices.contains(index) ? titles[index] : ""
            let item = TabItemView(symbolName: symbolName, title: title)
            item.onTap = { [weak self] in
                guard let self = self else { return }
                self.currentSelectedIndex = index
                self.updateItemAppearance()
                self.delegate?.tabBarView(self, didSelectTabAt: index)
            }
            items.append(item)
            itemStackView.addArrangedSubview(item)
        }

        updateItemAppearance()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        separatorView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1)
    }

    private func updateItemAppearance() {
        for (index, item) in items.enumerated() {
            item.setSelected(index == currentSelectedIndex)
        }
    }
}

/// A 25pt icon over an 11pt label, in a control at least 44pt tall.
private final class TabItemView: UIControl {
    var onTap: (() -> Void)?

    private let imageView = UIImageView()
    private let titleLabel = UILabel()

    private let normalImage: UIImage?
    private let selectedImage: UIImage?

    private lazy var imageTopConstraint = imageView.topAnchor.constraint(
        equalTo: topAnchor,
        constant: 3
    )

    init(symbolName: String, title: String) {
        let lineConfiguration = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        let selectedConfiguration = UIImage.SymbolConfiguration(pointSize: 19, weight: .bold)

        normalImage = UIImage(systemName: symbolName, withConfiguration: lineConfiguration)
        // Prefer the filled counterpart; symbols without one (magnifyingglass) get the heavier stroke.
        selectedImage = UIImage(systemName: "\(symbolName).fill", withConfiguration: selectedConfiguration)
            ?? UIImage(systemName: symbolName, withConfiguration: selectedConfiguration)

        super.init(frame: .zero)

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        addSubview(imageView)
        addSubview(titleLabel)

        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        NSLayoutConstraint.activate([
            imageTopConstraint,
            imageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 25),

            titleLabel.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 4),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),

            heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.Spacing.touchTarget)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCompact(_ compact: Bool) {
        titleLabel.isHidden = compact
        imageTopConstraint.constant = compact ? 9 : 3
    }

    func setSelected(_ selected: Bool) {
        imageView.image = selected ? selectedImage : normalImage
        imageView.tintColor = selected ? Theme.accent : Theme.textDisabled
        titleLabel.font = selected ? Theme.Font.badge : Theme.Font.tabLabel
        titleLabel.textColor = selected ? Theme.accent : Theme.textDisabled
        accessibilityTraits = selected ? [.button, .selected] : .button
    }

    @objc private func handleTap() {
        onTap?()
    }
}
