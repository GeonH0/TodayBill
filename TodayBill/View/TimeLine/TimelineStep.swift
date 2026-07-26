//
//  TimelineStep.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import Foundation

enum TimelineStepStatus: String, Codable, Equatable {
    case completed
    case current
    case pending

    var title: String {
        switch self {
        case .completed:
            return "완료"
        case .current:
            return "현재"
        case .pending:
            return "대기"
        }
    }
}

struct TimelineStep: Equatable {
    let title: String
    let dateText: String
    let status: TimelineStepStatus
}
