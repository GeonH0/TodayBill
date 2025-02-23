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
    private let label: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 3
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = UIFont.systemFont(ofSize: 16)
        lbl.textColor = UIColor.darkText
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    private func setupViews() {
        addSubview(label)
        addSubview(toggleButton)
        
        // label 제약조건
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        // toggleButton 제약조건 (label 바로 아래)
        NSLayoutConstraint.activate([
            toggleButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4),
            toggleButton.leadingAnchor.constraint(equalTo: leadingAnchor),
            toggleButton.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        toggleButton.addAction(
            UIAction(
                handler: { [weak self] _ in
                    self?.delegate?.toggleExpanded()
                }
            ),
            for: .touchUpInside
        )
    }
    
    func toggleExpanded() {
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
    }
}
