//
//import Foundation
//
//class FetchBill {
//    
//    func fetchBill() {
//        let session = URLSession(configuration: .default)
//        var urlComponents = URLComponents(string: "https://itunes.apple.com/search")!
//        var keyQuery = URLQueryItem(name: "key", value: "7e233d4fbea04f17b0e3218ccb604750")
//        var typeQuery = URLQueryItem(name: "Type", value: "json")
//        var pIndexQuery = URLQueryItem(name: "pIndex", value: "\(1)") // 정수를 문자열로 변환
//        var pSizeQuery = URLQueryItem(name: "pSize", value: "\(500)") // 정수를 문자열로 변환
//        var ageQuery = URLQueryItem(name: "AGE", value: "\(21)") // 정수를 문자열로 변환
//        urlComponents.queryItems?.append(keyQuery)
//        urlComponents.queryItems?.append(typeQuery)
//        urlComponents.queryItems?.append(pIndexQuery)
//        urlComponents.queryItems?.append(pSizeQuery)
//        urlComponents.queryItems?.append(ageQuery)
//    
//        guard let requestURL = urlComponents.url else {
//            debugPrint("Failed to create URL from components.")
//            return
//        }
//        let dataTask = session.dataTask(with: requestURL) { (data, response, error) in
//
//            // 에러가 존재하면 종료
//            guard error == nil else {
//                print("Error: \(error!)")
//                return
//            }
//
//            // HTTP 응답 코드가 200번대여야 성공적인 네트워크라 판단
//            let successsRange = 200..<300
//            guard let statusCode = (response as? HTTPURLResponse)?.statusCode,
//                  successsRange.contains(statusCode) else {
//                print("Invalid response")
//                return
//            }
//
//            // 데이터가 nil이 아닌 경우에만 처리
//            guard let resultData = data else {
//                print("No data received")
//                return
//            }
//
//            // 데이터가 있으면 문자열로 변환
//            if let resultString = String(data: resultData, encoding: .utf8) {
//                print(resultString)
//                print(resultData)
//
//            } else {
//                print("Failed to convert data to string")
//            }
//        }
//
//        // 네트워크 통신 실행
//        dataTask.resume()
//
//        
//        
//    }
//}

