//
//  DetailBillService.swift
//  TodayBill
//
//  Created by 김건호 on 2/1/25.
//

import Foundation

final class DetailBillService {    
    private let apiClient: OpenAssemblyAPIClient
    private static var cache: [String: [Row]] = [:]

    init(apiClient: OpenAssemblyAPIClient = .shared) {
        self.apiClient = apiClient
    }
    
    func fetchBills(ID: String, age: Int, completion: @escaping (Result<[Row], Error>) -> Void) {
        let cacheKey = "\(age)-\(ID)"
        if let cachedRows = Self.cache[cacheKey] {
            completion(.success(cachedRows))
            return
        }

        apiClient.fetchDetail(id: ID, age: age) { result in
            if case let .success(rows) = result {
                Self.cache[cacheKey] = rows
            }
            completion(result)
        }
    }

}
