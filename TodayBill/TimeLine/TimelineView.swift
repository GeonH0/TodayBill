//
//  TimelineView.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import Foundation

import UIKit

class TimelineView: UIView {
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.spacing = 16
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
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 8),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8)
        ])
    }
    
    func updateSteps(_ newSteps: [TimelineStep]) {
        for view in stackView.arrangedSubviews {
            stackView.removeArrangedSubview(view)
            view.removeFromSuperview()
        }
        self.steps = newSteps        
        for (index, step) in newSteps.enumerated() {
            let itemView = TimelineItemView(step: step)
            stackView.addArrangedSubview(itemView)
            
            if index < newSteps.count - 1 {
                let divider = UIView()
                divider.backgroundColor = .lightGray
                divider.translatesAutoresizingMaskIntoConstraints = false
                divider.heightAnchor.constraint(equalToConstant: 1).isActive = true
                stackView.addArrangedSubview(divider)
            }
        }
    }
}
