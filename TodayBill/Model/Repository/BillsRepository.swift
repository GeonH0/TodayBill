//
//  BillsRepository.swift
//  TodayBill
//
//  Created by 김건호 on 2/18/25.
//

import Foundation

enum BillsRepositoryError: Error {
    case dateConversionFailed
}

final class BillsRepository {
    private let billsService = BillsService()
    private let coreDataManager = CoreDataManager.shared
    private var pageIndexByAge: [Int: Int] = [22: 1, 21: 1]
    private var age: Int = 22
    var selectedDate: String?
    
    func fetchBills(for date: Date, isUserSelectingDate: Bool, completion: @escaping (Result<[StarredBill], Error>) -> Void) {
        guard let formattedDate = formatDate(date) else {
            completion(.failure(BillsRepositoryError.dateConversionFailed))
            return
        }
        
        selectedDate = formattedDate
        
        if let cached = fetchCachedBills(for: formattedDate) {
            completion(.success(cached))
            return
        }
        
        fetchBillsFromNetwork(for: date, isUserSelectingDate: isUserSelectingDate, formattedDate: formattedDate, completion: completion)
    }
    
    private func fetchCachedBills(for formattedDate: String) -> [StarredBill]? {
        let cachedBills = coreDataManager.fetchBills(for: formattedDate)
        return cachedBills.isEmpty ? nil : cachedBills
    }

    private func fetchBillsFromNetwork(
        for date: Date,
        isUserSelectingDate: Bool,
        formattedDate: String,
        completion: @escaping (Result<[StarredBill], Error>) -> Void
    ) {
        loadBills { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let rows):
                self.processFetchedRows(rows)
                self.handlePagination(rows, for: date) {
                    self.finalizeFetchedBills(for: formattedDate, isUserSelectingDate: isUserSelectingDate, completion: completion)
                }
                
            case .failure(let error):
                if let cached = self.fetchCachedBills(for: formattedDate) {
                    completion(.success(cached))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    private func processFetchedRows(_ rows: [Row]) {
        let entities = rows.map { $0.toBillEntity(context: CoreDataManager.shared.context) }
        coreDataManager.saveAll(entities)
    }

    private func finalizeFetchedBills(
        for formattedDate: String,
        isUserSelectingDate: Bool,
        completion: @escaping (Result<[StarredBill], Error>) -> Void
    ) {
        var bills = coreDataManager.fetchBills(for: formattedDate)
        
        if !isUserSelectingDate, let latest = getLatestAvailableDate(), bills.isEmpty {
            selectedDate = latest
            bills = coreDataManager.fetchBills(for: latest)
        }
        
        completion(.success(bills))
    }
    
    // API 호출
    private func loadBills(completion: @escaping (Result<[Row], Error>) -> Void) {
        let currentPIndex = pageIndexByAge[age] ?? 1
        billsService.fetchBills(pIndex: currentPIndex, age: age, completion: completion)
    }
    
    
    /// 페이징 처리를 위한 로직: oldestDate를 기준으로 age나 pIndex를 조정
    private func handlePagination(_ rows: [Row], for date: Date, completion: @escaping () -> Void) {
        
        guard let oldestDate = rows.map({ $0.PROPOSE_DT }).min() else {
            completion()
            return
        }
        
        // 2020년 5월 30일 이전 법안은 더 이상 요청하지 않음
        if oldestDate <= "2020-05-30" {
            completion()
            return
        }
        
        // 2024년 5월 30일 이전이면 22대에서 21대로 전환
        if oldestDate <= "2024-05-30" {
            if age == 22 {
                age = 21
                let currentPIndex = pageIndexByAge[age] ?? 1
                // 재귀적으로 다시 fetch
                fetchBills(for: date, isUserSelectingDate: true) { _ in
                    completion()
                }
                return
            } else if age == 21 {
                age = 22
                let currentPIndex = pageIndexByAge[age] ?? 1
                fetchBills(for: date, isUserSelectingDate: true) { _ in
                    completion()
                }
                return
            }
        } else {
            pageIndexByAge[age]! += 1
        }
        completion()
    }
    
    private func formatDate(_ date: Date) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
    
    /// 저장된 법안 중 최신 날짜를 반환
    func getLatestAvailableDate() -> String? {
        return self.coreDataManager.getLastestAvailableDate()
    }
}
