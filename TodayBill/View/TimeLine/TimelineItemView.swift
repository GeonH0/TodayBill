//
//  TimelineItemView.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import Foundation

import UIKit

/// One step of the 진행 경과 rail: a dot in a 16pt gutter, a connector down to the next step,
/// and the title/date pair. The step's state is carried by the dot and by type weight, not by a pill.
final class TimelineItemView: UIView {
    private static let railWidth: CGFloat = 16
    private static let dotSize: CGFloat = 11
    private static let bottomSpacing: CGFloat = 20

    private let dotView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = TimelineItemView.dotSize / 2
        return view
    }()

    /// A 4pt accent wash behind the current step's dot - the halo that marks "여기까지 왔다".
    private let haloView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.layer.cornerRadius = TimelineItemView.dotSize / 2 + 4
        view.isHidden = true
        return view
    }()

    private let connectorView: UIView = {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    private let dateLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()

    init(step: TimelineStep, isLast: Bool) {
        super.init(frame: .zero)
        translatesAutoresizingMaskIntoConstraints = false
        setupView(isLast: isLast)
        apply(step)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupView(isLast: Bool) {
        let railView = UIView()
        railView.translatesAutoresizingMaskIntoConstraints = false
        railView.addSubview(haloView)
        railView.addSubview(dotView)
        railView.addSubview(connectorView)

        let labelsStack = UIStackView(arrangedSubviews: [titleLabel, dateLabel])
        labelsStack.axis = .vertical
        labelsStack.spacing = 2
        labelsStack.translatesAutoresizingMaskIntoConstraints = false

        addSubview(railView)
        addSubview(labelsStack)

        connectorView.isHidden = isLast

        NSLayoutConstraint.activate([
            railView.topAnchor.constraint(equalTo: topAnchor),
            railView.leadingAnchor.constraint(equalTo: leadingAnchor),
            railView.bottomAnchor.constraint(equalTo: bottomAnchor),
            railView.widthAnchor.constraint(equalToConstant: Self.railWidth),

            // The dot lines up with the cap-height of the 15pt title, not with its box top.
            dotView.topAnchor.constraint(equalTo: railView.topAnchor, constant: 4),
            dotView.centerXAnchor.constraint(equalTo: railView.centerXAnchor),
            dotView.widthAnchor.constraint(equalToConstant: Self.dotSize),
            dotView.heightAnchor.constraint(equalToConstant: Self.dotSize),

            haloView.centerXAnchor.constraint(equalTo: dotView.centerXAnchor),
            haloView.centerYAnchor.constraint(equalTo: dotView.centerYAnchor),
            haloView.widthAnchor.constraint(equalTo: dotView.widthAnchor, constant: 8),
            haloView.heightAnchor.constraint(equalTo: dotView.heightAnchor, constant: 8),

            connectorView.topAnchor.constraint(equalTo: dotView.bottomAnchor, constant: 4),
            connectorView.centerXAnchor.constraint(equalTo: railView.centerXAnchor),
            connectorView.widthAnchor.constraint(equalToConstant: 2),
            connectorView.bottomAnchor.constraint(equalTo: railView.bottomAnchor),

            labelsStack.topAnchor.constraint(equalTo: topAnchor),
            labelsStack.leadingAnchor.constraint(equalTo: railView.trailingAnchor, constant: 14),
            labelsStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            labelsStack.bottomAnchor.constraint(
                equalTo: bottomAnchor,
                constant: isLast ? 0 : -Self.bottomSpacing
            )
        ])
    }

    private func apply(_ step: TimelineStep) {
        titleLabel.text = step.title
        dateLabel.text = step.dateText

        switch step.status {
        case .completed:
            dotView.backgroundColor = Theme.success
            dotView.layer.borderWidth = 0
            haloView.isHidden = true
            titleLabel.font = Theme.Font.listTitle
            titleLabel.textColor = Theme.textColor
            dateLabel.font = Theme.Font.meta
            dateLabel.textColor = Theme.textMuted
        case .current:
            // Hollow dot in an accent ring - the current step reads as "open", not "filled in".
            dotView.backgroundColor = Theme.cellBackgroundColor
            dotView.layer.borderWidth = 2
            dotView.layer.borderColor = Theme.accent.cgColor
            haloView.isHidden = false
            haloView.backgroundColor = Theme.accentSoft
            titleLabel.font = Theme.Font.sectionHeading
            titleLabel.textColor = Theme.accent
            dateLabel.font = Theme.Font.metaStrong
            dateLabel.textColor = Theme.accent
        case .pending:
            dotView.backgroundColor = Theme.fill
            dotView.layer.borderWidth = 0
            haloView.isHidden = true
            titleLabel.font = UIFont.systemFont(ofSize: 15, weight: .semibold)
            titleLabel.textColor = Theme.textDisabled
            dateLabel.font = Theme.Font.meta
            dateLabel.textColor = Theme.textDisabled
        }

        connectorView.backgroundColor = step.status == .completed ? Theme.success : Theme.fill
        isAccessibilityElement = true
        accessibilityLabel = "\(step.title), \(step.status.title), \(step.dateText)"
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if dotView.layer.borderWidth > 0 {
            dotView.layer.borderColor = Theme.accent.cgColor
        }
    }
}
