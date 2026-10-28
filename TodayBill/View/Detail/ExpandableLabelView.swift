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
    private static let collapsedLineCount = 3

    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 4
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()

    private let textContainerView: UIView = {
        let view = UIView()
        view.clipsToBounds = true
        return view
    }()
    
    private let label: UILabel = {
        let lbl = UILabel()
        lbl.numberOfLines = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        lbl.font = Theme.Font.body
        lbl.textColor = Theme.textSecondary
        return lbl
    }()
    
    private let toggleButton: UIButton = {
        let btn = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.title = "더 보기"
        config.baseForegroundColor = Theme.accent
        config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 0, bottom: 0, trailing: 0)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = Theme.Font.link
            return outgoing
        }
        btn.configuration = config
        btn.contentHorizontalAlignment = .leading
        btn.isHidden = true
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()
    
    weak var delegate: ExpandableLabelViewDelegate?
    
    private var isExpanded = false
    private var textNeedsExpansion = false
    private var fullTextHeight: CGFloat = 0
    private var collapsedTextHeight: CGFloat = 0
    private var measuredWidth: CGFloat = 0
    private var textHeightConstraint: NSLayoutConstraint!
    
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
        stackView.addArrangedSubview(textContainerView)
        stackView.addArrangedSubview(toggleButton)
        textContainerView.addSubview(label)

        textHeightConstraint = textContainerView.heightAnchor.constraint(equalToConstant: 0)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            label.topAnchor.constraint(equalTo: textContainerView.topAnchor),
            label.leadingAnchor.constraint(equalTo: textContainerView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: textContainerView.trailingAnchor),
            textHeightConstraint
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateTextMeasurementsIfNeeded()
    }
    
    func toggleExpanded() {
        guard textNeedsExpansion else { return }

        let layoutRoot = window ?? superview ?? self
        layoutRoot.layoutIfNeeded()

        isExpanded.toggle()
        textHeightConstraint.constant = isExpanded ? fullTextHeight : collapsedTextHeight
        toggleButton.configuration?.title = isExpanded ? "접기" : "더 보기"

        guard !UIAccessibility.isReduceMotionEnabled else {
            layoutRoot.layoutIfNeeded()
            return
        }

        UIView.animate(
            withDuration: 0.3,
            delay: 0,
            options: [.curveEaseInOut, .beginFromCurrentState, .allowUserInteraction]
        ) {
            layoutRoot.layoutIfNeeded()
        }
    }
    
    func configure(with text: String) {
        // Body copy is set at line-height 1.65, matching the type spec.
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = Theme.Metric.bodyLineSpacing
        label.attributedText = NSAttributedString(
            string: text,
            attributes: [
                .paragraphStyle: paragraphStyle,
                .font: Theme.Font.body,
                .foregroundColor: Theme.textSecondary
            ]
        )
        isExpanded = false
        toggleButton.configuration?.title = "더 보기"
        measuredWidth = 0
        setNeedsLayout()
    }
    
    private func updateTextMeasurementsIfNeeded() {
        let availableWidth = textContainerView.bounds.width
        guard availableWidth > 0 else {
            toggleButton.isHidden = true
            return
        }

        guard abs(availableWidth - measuredWidth) > 0.5 || fullTextHeight == 0 else { return }
        measuredWidth = availableWidth

        let fullSize = label.sizeThatFits(
            CGSize(width: availableWidth, height: .greatestFiniteMagnitude)
        )
        fullTextHeight = ceil(fullSize.height)
        collapsedTextHeight = min(
            fullTextHeight,
            ceil(
                label.font.lineHeight * CGFloat(Self.collapsedLineCount)
                    + Theme.Metric.bodyLineSpacing * CGFloat(Self.collapsedLineCount - 1)
            )
        )
        textNeedsExpansion = fullTextHeight > collapsedTextHeight + 1
        toggleButton.isHidden = !textNeedsExpansion
        textHeightConstraint.constant = isExpanded ? fullTextHeight : collapsedTextHeight
    }
}
