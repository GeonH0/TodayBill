import Foundation


extension ViewController {
    func fetchBill(){
        guard var url = URLComponents(string: "https://open.assembly.go.kr/portal/openapi/nzmimeepazxkubdpn") else {return}
        
        guard let key = Bundle.main.object(forInfoDictionaryKey: "serviceKey") as? String else {return}
        let serviceKey = key
        
        
        
        // 키-값 쌍 생성
        url.queryItems = [
            URLQueryItem(name: "key", value: serviceKey),
            URLQueryItem(name: "Type", value: "json"),
            URLQueryItem(name: "pIndex", value: "1"),
            URLQueryItem(name: "pSize", value: "150"),
            URLQueryItem(name: "AGE", value: "21")
        ]
        
        guard let requestUrl = url.url else { return }
        
        var request = URLRequest(url: requestUrl)
        request.httpMethod = "GET"
        
        let dataTask = URLSession.shared.dataTask(with: request) {[weak self] data,response,error in
            guard error == nil,
                  let self = self,
                  let response = response as? HTTPURLResponse,
                  let data = data
                  /*let bills = try? JSONDecoder().decode(Bills.self, from: data)*/ else {
                print("ERROR: URLSession data task \(error?.localizedDescription ?? "")")
                
                return
            }
            
            switch response.statusCode{
            case (200...299)://성공
//                self.dataBills += [bills]
                if let bills = try? JSONDecoder().decode(Bills.self, from: data) {
                                // Optional 값 처리 후 중첩 컬렉션 평탄화
                                let rows = bills.nzmimeepazxkubdpn.compactMap { $0.row }.flatMap { $0 }
                                self.dataRows += rows
                    DispatchQueue.main.async {
                        
                    }
                            }
                
            case (400...499): //클라이언트 에러
                print("""
                    ERROR: Client ERROR\(response.statusCode)
                    Response: \(response)
                """)
            case(500...599): //서버 에러
                print("""
                    ERROR: Serever ERROR\(response.statusCode)
                    Response: \(response)
                """)
            default:
                print("""
                    ERROR:\(response.statusCode)
                    Response: \(response)
                """)
            }
            }
        dataTask.resume()
        }
        
    }
    




