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

/// Fixed full-width bar with neutral selected icons and a subtle selection pulse.
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

    private lazy var itemStackCenterConstraint = itemStackView.centerYAnchor.constraint(equalTo: centerYAnchor)
    private lazy var itemStackHeightConstraint = itemStackView.heightAnchor.constraint(
        equalToConstant: max(Theme.Spacing.touchTarget, Theme.Metric.tabBarContentHeight)
    )

    /// Portrait content is centered across the bar's full visible background.
    /// Landscape keeps its controls above the home gesture area.
    func setCompact(_ compact: Bool) {
        itemStackCenterConstraint.constant = compact ? -safeAreaInsets.bottom / 2 : 0
        itemStackHeightConstraint.constant = max(Theme.Spacing.touchTarget, Theme.Metric.tabBarContentHeight)
        items.forEach { $0.setCompact(compact) }
    }

    private func addsubviews() {
        backgroundColor = Theme.cellBackgroundColor
        accessibilityIdentifier = "main-tab-bar"
        addSubview(separatorView)
        addSubview(itemStackView)

        NSLayoutConstraint.activate([
            itemStackCenterConstraint,
            itemStackView.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor, constant: 12),
            itemStackView.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor, constant: -12),
            itemStackView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            itemStackView.widthAnchor.constraint(lessThanOrEqualToConstant: Theme.Layout.maxContentWidth),
            itemStackHeightConstraint
        ])

        // Spread across the safe area until the cap above takes over.
        let fullWidth = itemStackView.widthAnchor.constraint(
            equalTo: safeAreaLayoutGuide.widthAnchor,
            constant: -24
        )
        fullWidth.priority = .defaultHigh
        fullWidth.isActive = true
    }

    func configure(symbolNames: [String], titles: [String]) {
        items.forEach {
            itemStackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        items = []

        for (index, symbolName) in symbolNames.enumerated() {
            let title = titles.indices.contains(index) ? titles[index] : ""
            let item = TabItemView(symbolName: symbolName, title: title)
            item.onTap = { [weak self] in
                guard let self = self else { return }
                self.select(at: index)
                self.delegate?.tabBarView(self, didSelectTabAt: index)
            }
            items.append(item)
            itemStackView.addArrangedSubview(item)
        }

        updateItemAppearance()
    }

    /// Lights the item at `index` without notifying the delegate, for tab changes made in code.
    func select(at index: Int, animated: Bool = true) {
        guard items.indices.contains(index), index != currentSelectedIndex else { return }
        layoutIfNeeded()
        currentSelectedIndex = index
        updateItemAppearance(animated: animated)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        separatorView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1)
        itemStackView.layoutIfNeeded()
    }

    private func updateItemAppearance(animated: Bool = false) {
        for (index, item) in items.enumerated() {
            item.setSelected(index == currentSelectedIndex, animated: animated)
        }
    }
}

/// Positions the screen and fixed bar; the bar background also fills the bottom inset.
final class MainTabBarContainerView: UIView {
    let contentView = UIView()
    let tabBar = MainTabBarView()
    private var tabBarHeightConstraint: NSLayoutConstraint!
    private var bottomToBar: NSLayoutConstraint!
    private var bottomToView: NSLayoutConstraint!
    private var barIsHidden = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = Theme.backgroundColor
        contentView.clipsToBounds = true
        contentView.translatesAutoresizingMaskIntoConstraints = false
        tabBar.translatesAutoresizingMaskIntoConstraints = false
        addSubview(contentView)
        addSubview(tabBar)
        tabBarHeightConstraint = tabBar.heightAnchor.constraint(equalToConstant: Theme.Metric.tabBarContentHeight)
        bottomToBar = contentView.bottomAnchor.constraint(equalTo: tabBar.topAnchor)
        bottomToView = contentView.bottomAnchor.constraint(equalTo: bottomAnchor)
        NSLayoutConstraint.activate([
            contentView.topAnchor.constraint(equalTo: topAnchor),
            contentView.leadingAnchor.constraint(greaterThanOrEqualTo: safeAreaLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(lessThanOrEqualTo: safeAreaLayoutGuide.trailingAnchor),
            contentView.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            contentView.widthAnchor.constraint(lessThanOrEqualToConstant: Theme.Layout.maxContentWidth),
            bottomToBar,
            tabBar.leadingAnchor.constraint(equalTo: leadingAnchor),
            tabBar.trailingAnchor.constraint(equalTo: trailingAnchor),
            tabBar.bottomAnchor.constraint(equalTo: bottomAnchor),
            tabBarHeightConstraint
        ])
        let fillWidth = contentView.widthAnchor.constraint(equalTo: safeAreaLayoutGuide.widthAnchor)
        fillWidth.priority = .defaultHigh
        fillWidth.isActive = true
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func layoutSubviews() {
        let compact = traitCollection.verticalSizeClass == .compact
        tabBarHeightConstraint.constant = max(Theme.Spacing.touchTarget, Theme.Layout.tabBarContentHeight(for: traitCollection) + safeAreaInsets.bottom)
        super.layoutSubviews()
        tabBar.setCompact(compact)
    }

    func setTabBarHidden(_ hidden: Bool, animated: Bool) {
        guard barIsHidden != hidden else { return }
        barIsHidden = hidden
        bottomToBar.isActive = !hidden
        bottomToView.isActive = hidden
        tabBar.isHidden = hidden
        if animated {
            UIView.animate(withDuration: 0.22) { self.layoutIfNeeded() }
        } else {
            layoutIfNeeded()
        }
    }
}

/// A 22pt icon over an 11pt label, in a control at least 44pt tall.
private final class TabItemView: UIControl {
    var onTap: (() -> Void)?

    private let imageView = TabIconImageView()
    private let titleLabel = UILabel()

    private let normalImage: UIImage?
    private let selectedImage: UIImage?

    private let contentStack = UIStackView()

    init(symbolName: String, title: String) {
        let lineConfiguration = UIImage.SymbolConfiguration(pointSize: 19, weight: .regular)
        let selectedConfiguration = UIImage.SymbolConfiguration(pointSize: 19, weight: .bold)

        normalImage = UIImage(systemName: symbolName, withConfiguration: lineConfiguration)
        // Prefer the filled counterpart; symbols without one (magnifyingglass) get the heavier stroke.
        selectedImage = symbolName == "magnifyingglass"
            ? UIImage(systemName: symbolName, withConfiguration: selectedConfiguration)
            : UIImage(systemName: "\(symbolName).fill", withConfiguration: selectedConfiguration) ?? normalImage

        super.init(frame: .zero)

        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = title
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false

        contentStack.axis = .vertical
        contentStack.alignment = .center
        contentStack.spacing = 2
        contentStack.isUserInteractionEnabled = false
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        contentStack.addArrangedSubview(imageView)
        contentStack.addArrangedSubview(titleLabel)
        addSubview(contentStack)

        isAccessibilityElement = true
        accessibilityLabel = title
        accessibilityTraits = .button
        addTarget(self, action: #selector(handleTap), for: .touchUpInside)

        // Stable label metrics keep selected/unselected groups centered alike.
        // UIStackView must still be able to collapse this label in landscape.
        let labelHeight = titleLabel.heightAnchor.constraint(equalToConstant: 14)
        labelHeight.priority = UILayoutPriority(999)
        NSLayoutConstraint.activate([
            labelHeight,
            contentStack.centerXAnchor.constraint(equalTo: centerXAnchor),
            contentStack.centerYAnchor.constraint(equalTo: centerYAnchor),
            contentStack.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor),
            contentStack.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            imageView.heightAnchor.constraint(equalToConstant: 22),
            imageView.widthAnchor.constraint(equalToConstant: 22),
            heightAnchor.constraint(greaterThanOrEqualToConstant: Theme.Spacing.touchTarget)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setCompact(_ compact: Bool) {
        titleLabel.isHidden = compact
    }

    func setSelected(_ selected: Bool, animated: Bool) {
        imageView.image = selected ? selectedImage : normalImage
        imageView.tintColor = selected ? Theme.accent : Theme.textDisabled
        titleLabel.font = selected ? Theme.Font.badge : Theme.Font.tabLabel
        titleLabel.textColor = selected ? Theme.accent : Theme.textDisabled
        accessibilityTraits = selected ? [.button, .selected] : .button

        contentStack.layer.removeAllAnimations()
        contentStack.transform = .identity
        guard selected, animated, UIView.areAnimationsEnabled,
              !UIAccessibility.isReduceMotionEnabled else { return }

        contentStack.transform = CGAffineTransform(scaleX: 0.88, y: 0.88)
        UIView.animate(withDuration: 0.32, delay: 0, usingSpringWithDamping: 0.65,
                       initialSpringVelocity: 0, options: [.allowUserInteraction, .beginFromCurrentState]) {
            self.contentStack.transform = .identity
        }
    }

    @objc private func handleTap() {
        onTap?()
    }
}


/// SF Symbols carry alignment insets; use the fixed icon box for stack centering.
private final class TabIconImageView: UIImageView {
    override var alignmentRectInsets: UIEdgeInsets { .zero }
}
