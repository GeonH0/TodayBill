//
//  TimelineView.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import Foundation

import UIKit

/// Vertical 진행 경과 rail. Steps are joined by a continuous connector instead of being
/// separated by dividers, so the sequence reads as one path.
final class TimelineView: UIView {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 0
        return stackView
    }()

    private var steps: [TimelineStep] = []

    init(steps: [TimelineStep]) {
        self.steps = steps
        super.init(frame: .zero)
        setupStackView()
        updateSteps(steps)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupStackView() {
        addSubview(stackView)

        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func updateSteps(_ newSteps: [TimelineStep]) {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        self.steps = newSteps

        for (index, step) in newSteps.enumerated() {
            let itemView = TimelineItemView(step: step, isLast: index == newSteps.count - 1)
            stackView.addArrangedSubview(itemView)
        }
    }
}
