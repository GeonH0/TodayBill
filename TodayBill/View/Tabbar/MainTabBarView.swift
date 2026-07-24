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

final class MainTabBarView: UIView {
    
    weak var delegate: MainTabBarViewDelegate?
    
    private var buttons: [UIButton] = []
    private var titles: [String] = []
    private let contentHeight: CGFloat = 50
    private let selectionBackgroundView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.12)
        view.layer.cornerRadius = 17
        view.isUserInteractionEnabled = false
        return view
    }()
    
    private let separatorView: UIView = {
        let separatorView = UIView()
        separatorView.backgroundColor = Theme.separator
        return separatorView
    }()
    
    private var currentSelectedIndex: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addsubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addsubviews(){
        backgroundColor = Theme.cellBackgroundColor
        addSubview(selectionBackgroundView)
        addSubview(separatorView)
    }
    
    func configure(with images: [UIImage], titles: [String]) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = []
        self.titles = titles
        
        for (index, image) in images.enumerated() {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.image = image.withRenderingMode(.alwaysTemplate)
            config.imagePadding = 0
            config.baseForegroundColor = .gray
            config.contentInsets = NSDirectionalEdgeInsets(top: 7, leading: 0, bottom: 7, trailing: 0)
            
            button.configuration = config
            button.tintColor = .gray
            button.tag = index
            button.setPreferredSymbolConfiguration(
                UIImage.SymbolConfiguration(pointSize: 21, weight: .medium),
                forImageIn: .normal
            )
            button.accessibilityLabel = titles.indices.contains(index) ? titles[index] : nil
            button.addAction(
                UIAction { [weak self] _ in
                    guard let self = self else { return }
                    self.currentSelectedIndex = index
                    self.updateSelectionBackgroundPosition(animated: true)
                    self.updateButtonAppearance()
                    self.delegate?.tabBarView(self, didSelectTabAt: index)
                },
                for: .touchUpInside
            )
            
            buttons.append(button)
            addSubview(button)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
        updateSelectionBackgroundPosition(animated: false)
        updateButtonAppearance()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !buttons.isEmpty else { return }

        separatorView.frame = CGRect(x: 0, y: 0, width: bounds.width, height: 1)

        let buttonWidth = bounds.width / CGFloat(buttons.count)
        let buttonHeight = min(contentHeight, bounds.height)
        for (index, button) in buttons.enumerated() {
            button.frame = CGRect(
                x: CGFloat(index) * buttonWidth,
                y: 1,
                width: buttonWidth,
                height: buttonHeight - 1
            )
            button.imageView?.contentMode = .scaleAspectFit
        }

        updateSelectionBackgroundPosition(animated: false)
    }
    
    private func updateSelectionBackgroundPosition(animated: Bool) {
        guard !buttons.isEmpty else { return }
        
        let buttonWidth = bounds.width / CGFloat(buttons.count)
        let selectedCenterX = CGFloat(currentSelectedIndex) * buttonWidth + buttonWidth / 2
        let selectionFrame = CGRect(
            x: selectedCenterX - 24,
            y: 8,
            width: 48,
            height: 34
        )
        
        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut]) {
                self.selectionBackgroundView.frame = selectionFrame
            }
        } else {
            selectionBackgroundView.frame = selectionFrame
        }
    }
    
    private func updateButtonAppearance() {
        for (index, button) in buttons.enumerated() {
            let isSelected = index == currentSelectedIndex
            button.tintColor = isSelected ? .systemBlue : .gray
            button.configuration?.baseForegroundColor = isSelected ? .systemBlue : .gray
            button.accessibilityTraits = isSelected ? [.button, .selected] : .button
        }
    }
}
