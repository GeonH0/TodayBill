//
//  ExpandableLabelView.swift
//  TodayBill
//
//  Created by 김건호 on 2/23/25.
//

import Foundation

import UIKit

protocol ExpandableLabelViewDelegate: AnyObject {
    func toggleExpanded()
}

final class ExpandableLabelView: UIView {
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    private let label: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 3
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = Theme.Font.bodyText
        lbl.textColor = Theme.textColor
        return lbl
    }()
    
    private let toggleButton: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("더 보기", for: .normal)
        btn.setTitleColor(Theme.emptyLabelTextColor, for: .normal)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    weak var delegate: ExpandableLabelViewDelegate?
    
    private var isExpanded = false
    private var textNeedsExpansion = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        addSubview(stackView)
        stackView.addArrangedSubview(label)
        stackView.addArrangedSubview(toggleButton)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        toggleButton.addAction(
            UIAction(
                handler: { [weak self] _ in
                    self?.delegate?.toggleExpanded()
                }
            ),
            for: .touchUpInside
        )
        updateToggleVisibility()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateToggleVisibility()
    }
    
    func toggleExpanded() {
        guard textNeedsExpansion else { return }
        isExpanded.toggle()
        label.numberOfLines = isExpanded ? 0 : 3
        let title = isExpanded ? "접기" : "더 보기"
        toggleButton.setTitle(title, for: .normal)
        UIView.animate(withDuration: 0.25) {
            self.layoutIfNeeded()
        }
    }
    
    func configure(with text: String) {
        label.text = text
        isExpanded = false
        label.numberOfLines = 3
        toggleButton.setTitle("더 보기", for: .normal)
        setNeedsLayout()
        layoutIfNeeded()
        updateToggleVisibility()
    }
    
    private func updateToggleVisibility() {
        guard label.bounds.width > 0 else {
            toggleButton.isHidden = true
            return
        }
        
        let originalNumberOfLines = label.numberOfLines
        label.numberOfLines = 0
        let fullSize = label.sizeThatFits(
            CGSize(width: label.bounds.width, height: .greatestFiniteMagnitude)
        )
        label.numberOfLines = originalNumberOfLines
        
        let collapsedHeight = ceil(label.font.lineHeight * 3)
        textNeedsExpansion = fullSize.height > collapsedHeight + 1
        toggleButton.isHidden = !textNeedsExpansion
    }
}
