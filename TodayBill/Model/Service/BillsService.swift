//
//  BillsService.swift
//  TodayBill
//
//  Created by 김건호 on 1/24/25.
//

import Foundation

enum OpenAssemblyAPIClientError: Error {
    case missingAPIKey
    case invalidURL
    case invalidResponse
}

final class OpenAssemblyAPIClient {
    static let shared = OpenAssemblyAPIClient()

    private let baseURL = "https://open.assembly.go.kr/portal/openapi/nzmimeepazxkubdpn"
    static let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func makeRequest(queryItems: [URLQueryItem]) throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw OpenAssemblyAPIClientError.invalidURL
        }

        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "serviceKey") as? String else {
            throw OpenAssemblyAPIClientError.missingAPIKey
        }

        let baseItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "Type", value: "json")
        ]
        urlComponents.queryItems = baseItems + queryItems

        guard let url = urlComponents.url else {
            throw OpenAssemblyAPIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(Self.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("ko-KR,ko;q=0.9,en-US;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        return request
    }

    func fetchBills(page: Int, age: Int, completion: @escaping (Result<[Row], Error>) -> Void) {
        fetchRows(
            queryItems: [
                URLQueryItem(name: "pIndex", value: "\(page)"),
                URLQueryItem(name: "pSize", value: "1000"),
                URLQueryItem(name: "AGE", value: "\(age)")
            ],
            completion: completion
        )
    }

    func searchBills(filter: BillFilter, page: Int, completion: @escaping (Result<[Row], Error>) -> Void) {
        var queryItems = [
            URLQueryItem(name: "pIndex", value: "\(page)"),
            URLQueryItem(name: "pSize", value: "100"),
            URLQueryItem(name: "AGE", value: "22")
        ]

        let normalizedQuery = filter.normalizedQuery
        if !normalizedQuery.isEmpty {
            queryItems.append(URLQueryItem(name: "BILL_NAME", value: normalizedQuery))
        }

        fetchRows(queryItems: queryItems, completion: completion)
    }

    func fetchDetail(id: String, age: Int, completion: @escaping (Result<[Row], Error>) -> Void) {
        fetchRows(
            queryItems: [
                URLQueryItem(name: "pIndex", value: "1"),
                URLQueryItem(name: "pSize", value: "1"),
                URLQueryItem(name: "AGE", value: "\(age)"),
                URLQueryItem(name: "BILL_ID", value: id)
            ],
            completion: completion
        )
    }

    private func fetchRows(queryItems: [URLQueryItem], completion: @escaping (Result<[Row], Error>) -> Void) {
        let request: URLRequest
        do {
            request = try makeRequest(queryItems: queryItems)
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode),
                  let data = data else {
                completion(.failure(OpenAssemblyAPIClientError.invalidResponse))
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

final class OpenAssemblyVoteAPIClient {
    static let shared = OpenAssemblyVoteAPIClient()

    private let baseURL = "https://open.assembly.go.kr/portal/openapi/ncocpgfiaoituanbr"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func fetchVoteSummary(
        billID: String,
        age: Int,
        completion: @escaping (Result<BillVoteSummary?, Error>) -> Void
    ) {
        guard var urlComponents = URLComponents(string: baseURL) else {
            completion(.failure(OpenAssemblyAPIClientError.invalidURL))
            return
        }

        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "serviceKey") as? String else {
            completion(.failure(OpenAssemblyAPIClientError.missingAPIKey))
            return
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "Key", value: apiKey),
            URLQueryItem(name: "Type", value: "json"),
            URLQueryItem(name: "pIndex", value: "1"),
            URLQueryItem(name: "pSize", value: "1"),
            URLQueryItem(name: "AGE", value: "\(age)"),
            URLQueryItem(name: "BILL_ID", value: billID)
        ]

        guard let url = urlComponents.url else {
            completion(.failure(OpenAssemblyAPIClientError.invalidURL))
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(OpenAssemblyAPIClient.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("ko-KR,ko;q=0.9,en-US;q=0.8", forHTTPHeaderField: "Accept-Language")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")

        session.dataTask(with: request) { data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode),
                  let data else {
                completion(.failure(OpenAssemblyAPIClientError.invalidResponse))
                return
            }

            do {
                let decodedResponse = try JSONDecoder().decode(BillVoteResponse.self, from: data)
                let summary = decodedResponse.ncocpgfiaoituanbr
                    .compactMap { $0.row }
                    .flatMap { $0 }
                    .first?
                    .summary
                completion(.success(summary))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }
}

enum LawInfoAPIClientError: LocalizedError {
    case missingAPIKey
    case invalidURL
    case invalidResponse
    case apiMessage(String)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "법제처 API 인증값이 설정되지 않았습니다."
        case .invalidURL:
            return "법제처 API URL을 만들 수 없습니다."
        case .invalidResponse:
            return "법제처 API 응답을 해석할 수 없습니다."
        case .apiMessage(let message):
            return message
        }
    }
}

final class LawInfoAPIClient {
    static let shared = LawInfoAPIClient()

    private let baseURL = "https://www.law.go.kr/DRF/lawSearch.do"
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func makeRequest(range: LawEnforcementDateRange) throws -> URLRequest {
        guard var urlComponents = URLComponents(string: baseURL) else {
            throw LawInfoAPIClientError.invalidURL
        }

        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "LawInfoServiceKey") as? String,
              !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !apiKey.contains("$(") else {
            throw LawInfoAPIClientError.missingAPIKey
        }

        urlComponents.queryItems = [
            URLQueryItem(name: "OC", value: apiKey),
            URLQueryItem(name: "target", value: "eflaw"),
            URLQueryItem(name: "type", value: "JSON"),
            URLQueryItem(name: "display", value: "30"),
            URLQueryItem(name: "page", value: "1"),
            URLQueryItem(name: "nw", value: "2"),
            URLQueryItem(name: "sort", value: "efasc"),
            URLQueryItem(name: "efYd", value: "\(Self.apiDateFormatter.string(from: range.start))~\(Self.apiDateFormatter.string(from: range.end))")
        ]

        guard let url = urlComponents.url else {
            throw LawInfoAPIClientError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(OpenAssemblyAPIClient.userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("application/json, text/xml, */*", forHTTPHeaderField: "Accept")
        request.setValue("ko-KR,ko;q=0.9,en-US;q=0.8", forHTTPHeaderField: "Accept-Language")
        return request
    }

    func fetchLawEnforcements(
        range: LawEnforcementDateRange,
        completion: @escaping (Result<[LawEnforcementSnapshot], Error>) -> Void
    ) {
        let request: URLRequest
        do {
            request = try makeRequest(range: range)
        } catch {
            completion(.failure(error))
            return
        }

        session.dataTask(with: request) { [weak self] data, response, error in
            if let error {
                completion(.failure(error))
                return
            }

            guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode),
                  let data else {
                completion(.failure(LawInfoAPIClientError.invalidResponse))
                return
            }

            do {
                let contentType = response.value(forHTTPHeaderField: "Content-Type")
                let snapshots = try self?.decodeLawEnforcements(from: data, contentType: contentType) ?? []
                completion(.success(snapshots))
            } catch {
                completion(.failure(error))
            }
        }.resume()
    }

    func decodeLawEnforcements(from data: Data, contentType: String? = nil) throws -> [LawEnforcementSnapshot] {
        let trimmed = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        if contentType?.localizedCaseInsensitiveContains("xml") == true || trimmed.hasPrefix("<") {
            return try decodeXMLLawEnforcements(from: data)
        }

        let object = try JSONSerialization.jsonObject(with: data)
        let dictionaries = collectLawDictionaries(from: object)
        if dictionaries.isEmpty,
           let message = apiMessage(from: object) {
            throw LawInfoAPIClientError.apiMessage(message)
        }
        return dictionaries.compactMap(makeSnapshot(from:))
    }

    private func decodeXMLLawEnforcements(from data: Data) throws -> [LawEnforcementSnapshot] {
        let parser = XMLParser(data: data)
        let delegate = LawInfoXMLParserDelegate()
        parser.delegate = delegate

        guard parser.parse() else {
            throw parser.parserError ?? LawInfoAPIClientError.invalidResponse
        }

        if delegate.items.isEmpty,
           let message = delegate.apiMessage {
            throw LawInfoAPIClientError.apiMessage(message)
        }
        return delegate.items.compactMap(makeSnapshot(from:))
    }

    private func collectLawDictionaries(from object: Any) -> [[String: Any]] {
        if let dictionary = object as? [String: Any] {
            if containsLawFields(dictionary) {
                return [dictionary]
            }
            return dictionary.values.flatMap { collectLawDictionaries(from: $0) }
        }

        if let array = object as? [Any] {
            return array.flatMap { collectLawDictionaries(from: $0) }
        }

        return []
    }

    private func containsLawFields(_ dictionary: [String: Any]) -> Bool {
        stringValue(from: dictionary, keys: Self.lawNameKeys) != nil ||
            stringValue(from: dictionary, keys: Self.enforcementDateKeys) != nil
    }

    private func apiMessage(from object: Any) -> String? {
        guard let dictionary = object as? [String: Any] else { return nil }
        if let message = stringValue(from: dictionary, keys: ["msg", "resultMsg", "message", "MESSAGE", "result"]) {
            return message
        }
        return dictionary.values.compactMap(apiMessage(from:)).first
    }

    private func makeSnapshot(from dictionary: [String: Any]) -> LawEnforcementSnapshot? {
        guard let lawName = stringValue(from: dictionary, keys: Self.lawNameKeys),
              let enforcementDate = stringValue(from: dictionary, keys: Self.enforcementDateKeys) else {
            return nil
        }

        let lawID = stringValue(from: dictionary, keys: Self.lawIDKeys) ?? ""
        let mst = stringValue(from: dictionary, keys: Self.mstKeys) ?? lawID
        return LawEnforcementSnapshot(
            lawID: lawID,
            mst: mst,
            lawName: lawName,
            promulgationDate: normalizedDisplayDate(stringValue(from: dictionary, keys: Self.promulgationDateKeys)),
            enforcementDate: normalizedDisplayDate(enforcementDate) ?? enforcementDate,
            ministry: stringValue(from: dictionary, keys: Self.ministryKeys),
            lawType: stringValue(from: dictionary, keys: Self.lawTypeKeys),
            detailURL: normalizedDetailURL(stringValue(from: dictionary, keys: Self.detailURLKeys)),
            matchedBillID: nil,
            updatedAt: Date()
        )
    }

    private func makeSnapshot(from dictionary: [String: String]) -> LawEnforcementSnapshot? {
        let objectDictionary = dictionary.reduce(into: [String: Any]()) { result, item in
            result[item.key] = item.value
        }
        return makeSnapshot(from: objectDictionary)
    }

    private func stringValue(from dictionary: [String: Any], keys: [String]) -> String? {
        for key in keys {
            if let value = dictionary[key] as? String,
               let nonEmpty = BillSnapshot.nonEmpty(value) {
                return nonEmpty
            }

            if let value = dictionary[key] as? NSNumber {
                return value.stringValue
            }
        }
        return nil
    }

    private func normalizedDisplayDate(_ value: String?) -> String? {
        guard let value = BillSnapshot.nonEmpty(value) else { return nil }
        let digits = value.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard digits.count == 8 else { return value }
        let year = digits.prefix(4)
        let month = digits.dropFirst(4).prefix(2)
        let day = digits.suffix(2)
        return "\(year)-\(month)-\(day)"
    }

    private func normalizedDetailURL(_ value: String?) -> URL? {
        guard let value = BillSnapshot.nonEmpty(value) else { return nil }
        if let url = URL(string: value), url.scheme != nil {
            return url
        }

        let normalizedPath = value.hasPrefix("/") ? value : "/\(value)"
        return URL(string: "https://www.law.go.kr\(normalizedPath)")
    }

    private static let apiDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyyMMdd"
        return formatter
    }()

    private static let lawIDKeys = ["법령ID", "법령아이디", "lawId", "lawID", "ID"]
    private static let mstKeys = ["법령일련번호", "MST", "mst", "법령MST"]
    private static let lawNameKeys = ["법령명한글", "법령명", "lawName", "법령명_한글"]
    private static let promulgationDateKeys = ["공포일자", "공포일", "promulgationDate"]
    private static let enforcementDateKeys = ["시행일자", "시행일", "efYd", "enforcementDate"]
    private static let ministryKeys = ["소관부처명", "소관부처", "ministry"]
    private static let lawTypeKeys = ["법령구분명", "법종구분", "법종", "lawType"]
    private static let detailURLKeys = ["법령상세링크", "상세링크", "법령URL", "detailURL"]
}

private final class LawInfoXMLParserDelegate: NSObject, XMLParserDelegate {
    private let itemElementNames: Set<String> = ["law", "eflaw", "item"]
    private var currentItem: [String: String]?
    private var currentElementName: String?
    private var currentText = ""

    private(set) var items: [[String: String]] = []
    private(set) var apiMessage: String?

    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String: String] = [:]
    ) {
        if itemElementNames.contains(elementName.lowercased()) {
            currentItem = [:]
        }
        currentElementName = elementName
        currentText = ""
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        currentText += string
    }

    func parser(
        _ parser: XMLParser,
        didEndElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?
    ) {
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedElementName = elementName.lowercased()

        if itemElementNames.contains(lowercasedElementName) {
            if let currentItem,
               !currentItem.isEmpty {
                items.append(currentItem)
            }
            currentItem = nil
        } else if !trimmed.isEmpty {
            if currentItem != nil {
                currentItem?[elementName] = trimmed
            } else if ["msg", "result", "resultMsg"].contains(lowercasedElementName) {
                apiMessage = trimmed
            }
        }

        currentElementName = nil
        currentText = ""
    }
}

final class BillsService {
    private let apiClient: OpenAssemblyAPIClient

    init(apiClient: OpenAssemblyAPIClient = .shared) {
        self.apiClient = apiClient
    }

    // MARK: - Fetch Bills
    func fetchBills(pIndex: Int, age: Int, completion: @escaping (Result<[Row], Error>) -> Void) {
        apiClient.fetchBills(page: pIndex, age: age, completion: completion)
    }
}
