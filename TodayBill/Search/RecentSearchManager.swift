//
//  RecentSearchManager.swift
//  TodayBill
//
//  Created by 김건호 on 1/24/25.
//

import Foundation

struct RecentSearchManager {
    private let userDefaultsKey = "RecentSearches"
    private let maxSearches = 20
        
    func save(searchTerm: String) {
        var searches = load()
        searches.removeAll { $0 == searchTerm }
        searches.insert(searchTerm, at: 0)
        if searches.count > maxSearches {
            searches.removeLast()
        }
        UserDefaults.standard.set(searches, forKey: userDefaultsKey)
    }
    
    func load() -> [String] {
        return UserDefaults.standard.stringArray(forKey: userDefaultsKey) ?? []
    }
    
    func deleteAll() {
        UserDefaults.standard.removeObject(forKey: userDefaultsKey)
    }
}
