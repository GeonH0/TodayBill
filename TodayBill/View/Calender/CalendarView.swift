//
//  CalendarView.swift
//  TodayBill
//
//  Created by 김건호 on 1/31/25.
//

import Foundation
import UIKit

final class CalendarView: UIView {
    
    lazy var dateView: UICalendarView = {
        var view = UICalendarView()
        view.wantsDateDecorations = true
        return view
    }()
    
    weak var delegate: UICalendarViewDelegate?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
        
    private func setupView() {
        addSubview(dateView)
        dateView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dateView.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor),
            dateView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            dateView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            dateView.heightAnchor.constraint(equalToConstant: 450)
        ])
    }
    
    func reloadDateView(date: Date?) {
        if let date = date {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
            dateView.reloadDecorations(forDateComponents: [dateComponents], animated: true)
        }
    }
}
