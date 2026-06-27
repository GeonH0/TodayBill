//
//  HTMLScraper.swift
//  TodayBill
//
//  Created by 김건호 on 2/22/25.
//

import Foundation
import SwiftSoup

final class AssemblySummaryClient {
    private static var summaryCache: [String: BillSummary] = [:]
    private let userAgent = OpenAssemblyAPIClient.userAgent

    func fetchSummary(from urlString: String, completion: @escaping (Result<BillSummary, Error>) -> Void) {
        fetchSummaryContent(from: urlString) { rawText in
            guard let rawText else {
                completion(.failure(URLError(.cannotParseResponse)))
                return
            }
            completion(.success(BillSummary.split(rawText: rawText)))
        }
    }
    
    func fetchSummaryContent(from urlString: String, completion: @escaping (String?) -> Void) {
        if let cachedSummary = Self.summaryCache[urlString] {
            completion(cachedSummary.rawText)
            return
        }
        
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("ko-KR,ko;q=0.9,en-US;q=0.8", forHTTPHeaderField: "Accept-Language")
        
        let task = URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self else { return }
            // 네트워크 에러 처리
            if let error = error {
                print("❌ Error fetching data: \(error.localizedDescription)")
                completion(nil)
                return
            }
                        
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                print("❌ Data conversion error")
                completion(nil)
                return
            }
            
            do {
                let document: Document = try SwiftSoup.parse(htmlString)
                if let contentText = try self.extractLegacySummary(from: document) {
                    Self.summaryCache[urlString] = BillSummary.split(rawText: contentText)
                    completion(contentText)
                } else if let detailURL = response?.url {
                    self.fetchBillInfoFragment(
                        detailURL: detailURL,
                        document: document,
                        cacheKey: urlString,
                        completion: completion
                    )
                } else {
                    print("❌ Summary content not found")
                    completion(nil)
                }
            } catch {
                print("❌ SwiftSoup parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
    
    private func fetchBillInfoFragment(
        detailURL: URL,
        document: Document,
        cacheKey: String,
        completion: @escaping (String?) -> Void
    ) {
        do {
            guard let csrfToken = try document.select("meta[name=_csrf]").first()?.attr("content"),
                  var components = URLComponents(url: detailURL, resolvingAgainstBaseURL: false) else {
                print("❌ Missing CSRF token or detail URL")
                completion(nil)
                return
            }
            
            components.path = "/bill/bi/bill/detail/billInfo.do"
            components.query = nil
            guard let fragmentURL = components.url else {
                completion(nil)
                return
            }
            
            var parameters = try extractHiddenFormParameters(from: document)
            parameters["_csrf"] = csrfToken
            
            var request = URLRequest(url: fragmentURL)
            request.httpMethod = "POST"
            request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
            request.setValue("ko-KR,ko;q=0.9,en-US;q=0.8", forHTTPHeaderField: "Accept-Language")
            request.setValue("text/html, */*", forHTTPHeaderField: "Accept")
            request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
            request.setValue(csrfToken, forHTTPHeaderField: "X-CSRF-TOKEN")
            request.setValue("application/x-www-form-urlencoded; charset=UTF-8", forHTTPHeaderField: "Content-Type")
            request.setValue(detailURL.absoluteString, forHTTPHeaderField: "Referer")
            request.httpBody = formURLEncodedBody(parameters)
            
            URLSession.shared.dataTask(with: request) { data, _, error in
                if let error = error {
                    print("❌ Error fetching bill info fragment: \(error.localizedDescription)")
                    completion(nil)
                    return
                }
                
                guard let data = data,
                      let htmlString = String(data: data, encoding: .utf8) else {
                    print("❌ Bill info fragment conversion error")
                    completion(nil)
                    return
                }
                
                do {
                    let fragmentDocument = try SwiftSoup.parse(htmlString)
                    guard let contentText = try self.extractFragmentSummary(from: fragmentDocument) else {
                        print("❌ prntSummary not found")
                        completion(nil)
                        return
                    }
                    
                    Self.summaryCache[cacheKey] = BillSummary.split(rawText: contentText)
                    completion(contentText)
                } catch {
                    print("❌ Bill info fragment parsing error: \(error.localizedDescription)")
                    completion(nil)
                }
            }.resume()
        } catch {
            print("❌ Detail page parsing error: \(error.localizedDescription)")
            completion(nil)
        }
    }

    func parseLegacySummaryHTML(_ html: String) -> BillSummary? {
        do {
            let document = try SwiftSoup.parse(html)
            guard let rawText = try extractLegacySummary(from: document) else { return nil }
            return BillSummary.split(rawText: rawText)
        } catch {
            return nil
        }
    }

    func parseFragmentSummaryHTML(_ html: String) -> BillSummary? {
        do {
            let document = try SwiftSoup.parse(html)
            guard let rawText = try extractFragmentSummary(from: document) else { return nil }
            return BillSummary.split(rawText: rawText)
        } catch {
            return nil
        }
    }
    
    private func extractLegacySummary(from document: Document) throws -> String? {
        guard let contentDiv = try document.select("div#summaryContentDiv").first() else {
            return nil
        }
        return cleanSummaryText(try contentDiv.text())
    }
    
    private func extractFragmentSummary(from document: Document) throws -> String? {
        guard let content = try document.select("#prntSummary").first() else {
            return nil
        }
        return cleanSummaryText(try content.text())
    }
    
    private func extractHiddenFormParameters(from document: Document) throws -> [String: String] {
        var parameters: [String: String] = [:]
        let inputs = try document.select("#form input[type=hidden]")
        for input in inputs.array() {
            let name = try input.attr("name")
            guard !name.isEmpty else { continue }
            parameters[name] = try input.attr("value")
        }
        return parameters
    }
    
    private func cleanSummaryText(_ text: String) -> String {
        var contentText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let marker = "제안이유 및 주요내용"
        if contentText.hasPrefix(marker) {
            contentText = contentText.replacingOccurrences(of: marker, with: "")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return contentText
    }
    
    private func formURLEncodedBody(_ parameters: [String: String]) -> Data? {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._* ")
        let body = parameters
            .map { key, value in
                let encodedKey = key.addingPercentEncoding(withAllowedCharacters: allowed)?
                    .replacingOccurrences(of: " ", with: "+") ?? key
                let encodedValue = value.addingPercentEncoding(withAllowedCharacters: allowed)?
                    .replacingOccurrences(of: " ", with: "+") ?? value
                return "\(encodedKey)=\(encodedValue)"
            }
            .joined(separator: "&")
        return body.data(using: .utf8)
    }
}

final class HTMLScraper {
    private let client = AssemblySummaryClient()

    func fetchSummaryContent(from urlString: String, completion: @escaping (String?) -> Void) {
        client.fetchSummaryContent(from: urlString, completion: completion)
    }
}
