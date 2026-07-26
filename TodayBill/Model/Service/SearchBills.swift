//
//  SearchBills.swift
//  TodayBill
//
//  Created by 김건호 on 1/24/25.
//

import Foundation

final class BillsSearchService {
    private let apiClient: OpenAssemblyAPIClient
    private static var cache: [String: [Row]] = [:]

    // MARK: - Initializer
    init(billsService: BillsService) {
        self.apiClient = .shared
    }

    init(apiClient: OpenAssemblyAPIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Search Bills
    func searchBills(pIndex: Int, billName: String, completion: @escaping (Result<[Row], Error>) -> Void) {
        let normalizedTerm = billName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = "\(pIndex)-\(normalizedTerm)"
        if let cachedRows = Self.cache[cacheKey] {
            completion(.success(cachedRows))
            return
        }

        apiClient.searchBills(filter: BillFilter(query: normalizedTerm), page: pIndex) { result in
            if case let .success(rows) = result {
                Self.cache[cacheKey] = rows
            }
            completion(result)
        }
    }
}
