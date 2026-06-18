//
//  SearchBills.swift
//  TodayBill
//
//  Created by 김건호 on 1/24/25.
//

import Foundation

final class BillsSearchService {
    private let billsService: BillsService
    private let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    private static var cache: [String: [Row]] = [:]

    // MARK: - Initializer
    init(billsService: BillsService) {
        self.billsService = billsService
    }

    // MARK: - Search Bills
    func searchBills(pIndex: Int, billName: String, completion: @escaping (Result<[Row], Error>) -> Void) {
        let normalizedTerm = billName.trimmingCharacters(in: .whitespacesAndNewlines)
        let cacheKey = "\(pIndex)-\(normalizedTerm)"
        if let cachedRows = Self.cache[cacheKey] {
            completion(.success(cachedRows))
            return
        }
        
        guard var urlComponents = URLComponents(string: "https://open.assembly.go.kr/portal/openapi/nzmimeepazxkubdpn") else {
            completion(.failure(URLError(.badURL)))
            return
        }

        // API Key 가져오기
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "serviceKey") as? String else {
            completion(.failure(URLError(.userAuthenticationRequired)))
            return
        }

        // Query Items 설정
        urlComponents.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "Type", value: "json"),
            URLQueryItem(name: "pIndex", value: "\(pIndex)"),
            URLQueryItem(name: "pSize", value: "100"),
            URLQueryItem(name: "AGE", value: "22"),
            URLQueryItem(name: "BILL_NAME", value: normalizedTerm)
        ]

        guard let url = urlComponents.url else {
            completion(.failure(URLError(.badURL)))
            return
        }

        // Request 생성
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("ko-KR,ko;q=0.9,en-US;q=0.8", forHTTPHeaderField: "Accept-Language")

        // URLSession 데이터 요청
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode),
                  let data = data else {
                completion(.failure(URLError(.badServerResponse)))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(Bills.self, from: data)
                let rows = decodedResponse.nzmimeepazxkubdpn.compactMap { $0.row }.flatMap { $0 }
                Self.cache[cacheKey] = rows
                completion(.success(rows))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
