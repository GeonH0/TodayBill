//
//  StarBillManager.swift
//  TodayBill
//
//  Created by 김건호 on 1/28/25.
//

import Foundation

final class StarBillManager {
    static let shared = StarBillManager()
    private let starredBillsKey = "starredBills"
    private var cachedBills: [String: Row] = [:]

    private init() {}
    
    func loadStarredBills() -> [StarredBill] {
        if let data = UserDefaults.standard.data(forKey: starredBillsKey),
           let bills = try? JSONDecoder().decode([StarredBill].self, from: data) {
            return bills
        }
        return []
    }
    
    func addBillToStarred(_ bill: StarredBill) {
        var starredBills = loadStarredBills()
        if !starredBills.contains(where: { $0.ID == bill.ID }) {
            starredBills.append(bill)
            saveStarredBills(starredBills)
        }
    }

    func removeBillFromStarred(by id: String) {
        saveStarredBills(loadStarredBills().filter { $0.ID != id })
    }

    func cacheBill(_ bill: Row) {
        cachedBills[bill.BILL_ID] = bill
    }
    
    func getBillFromCache(by id: String) -> Row? {
        return cachedBills[id]
    }

    func saveStarredBills(_ bills: [StarredBill]) {
        if let data = try? JSONEncoder().encode(bills) {
            UserDefaults.standard.set(data, forKey: starredBillsKey)
        }
    }
}
