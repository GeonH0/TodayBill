//
//  StarredBill.swift
//  TodayBill
//
//  Created by 김건호 on 1/28/25.
//

import Foundation

struct StarredBill: Codable {
    let ID: String
    let age: Int
    let name: String
}

extension StarredBill {
    static func dummyStarredBill() -> StarredBill {
        return StarredBill(
            ID: "1",
            age: 22,
            name: "testname"
        )
    }
}
