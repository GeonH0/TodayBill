//
//  TimelineItemView.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import Foundation

import UIKit

class TimelineItemView: UIView {
    private let circleView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = 7
        view.layer.masksToBounds = true
        return view
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.rowTitle
        label.textColor = Theme.textColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.metaText
        label.textColor = Theme.emptyLabelTextColor
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let statusLabel: UILabel = {
        let label = UILabel()
        label.font = Theme.Font.smallStrong
        label.textAlignment = .center
        label.layer.cornerRadius = Theme.Radius.small
        label.layer.masksToBounds = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    init(step: TimelineStep) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView(with: step)
    }
    
    private func setupView(with step: TimelineStep) {
        let statusColor = color(for: step.status)
        circleView.backgroundColor = statusColor
        titleLabel.text = step.title
        dateLabel.text = step.dateText
        statusLabel.text = step.status.title
        statusLabel.textColor = statusColor
        statusLabel.backgroundColor = statusColor.withAlphaComponent(0.12)
        
        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 4
        labelsStack.translatesAutoresizingMaskIntoConstraints = false
        labelsStack.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        let horizontalStack = UIStackView(arrangedSubviews: [circleView, labelsStack, statusLabel])
        horizontalStack.axis = .horizontal
        horizontalStack.spacing = 10
        horizontalStack.alignment = .center
        horizontalStack.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(horizontalStack)
        
        NSLayoutConstraint.activate([
            circleView.widthAnchor.constraint(equalToConstant: 14),
            circleView.heightAnchor.constraint(equalToConstant: 14),
            statusLabel.widthAnchor.constraint(equalToConstant: 44),
            statusLabel.heightAnchor.constraint(equalToConstant: 26),
            
            horizontalStack.topAnchor.constraint(equalTo: topAnchor),
            horizontalStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            horizontalStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            horizontalStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    private func color(for status: TimelineStepStatus) -> UIColor {
        switch status {
        case .completed:
            return .systemGreen
        case .current:
            return .systemBlue
        case .pending:
            return .systemGray
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
