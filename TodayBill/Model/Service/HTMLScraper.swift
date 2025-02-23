//
//  HTMLScraper.swift
//  TodayBill
//
//  Created by 김건호 on 2/22/25.
//

import Foundation
import SwiftSoup

final class HTMLScraper {
    func fetchSummaryContent(from urlString: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: urlString) else {
            print("❌ Invalid URL: \(urlString)")
            completion(nil)
            return
        }
                
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
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
                // id가 "summaryContentDiv"인 요소 선택
                if let contentDiv: Element = try document.select("div#summaryContentDiv").first() {
                    var contentText = try contentDiv.text()
                    let marker = "제안이유 및 주요내용"
                    if contentText.hasPrefix(marker) {
                        contentText = contentText.replacingOccurrences(of: marker, with: "")
                            .trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    completion(contentText)
                } else {
                    print("❌ summaryContentDiv not found")
                    completion(nil)
                }
            } catch {
                print("❌ SwiftSoup parsing error: \(error.localizedDescription)")
                completion(nil)
            }
        }
        task.resume()
    }
}
