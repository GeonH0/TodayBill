//
//  SearchBills.swift
//  TodayBill
//
//  Created by 김건호 on 1/24/25.
//

import Foundation

final class BillsSearchService {
    private let billsService: BillsService

    // MARK: - Initializer
    init(billsService: BillsService) {
        self.billsService = billsService
    }

    // MARK: - Search Bills
    func searchBills(pIndex: Int, billName: String, completion: @escaping (Result<[Row], Error>) -> Void) {
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
            URLQueryItem(name: "BILL_NAME", value: billName)
        ]

        guard let url = urlComponents.url else {
            completion(.failure(URLError(.badURL)))
            return
        }

        // Request 생성
        var request = URLRequest(url: url)
        request.httpMethod = "GET"

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
                completion(.success(rows))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}
