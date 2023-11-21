//
//  ViewController.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//
import UIKit

class ViewController: UIViewController {
    var dataBills : [Bills] = []
    
    
    
    lazy var dateView: UICalendarView = {
        var view = UICalendarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsDateDecorations = true
        return view
    }()
    
    var selectedDate: DateComponents? = nil

    override func viewDidLoad() {
        super.viewDidLoad()
        fetchBill()
        applyConstraints()
        setCalendar()
        reloadDateView(date: Date())
    }

    fileprivate func setCalendar() {
        dateView.delegate = self

        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        dateView.selectionBehavior = dateSelection
    }
    
    fileprivate func applyConstraints() {
        view.addSubview(dateView)
        
        let dateViewConstraints = [
            dateView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            dateView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            dateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ]
        NSLayoutConstraint.activate(dateViewConstraints)
    }
    
    func reloadDateView(date: Date?) {
        if let date = date {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
            // selectedDate 업데이트를 reloadDateView 이전으로 이동
            selectedDate = dateComponents
            dateView.reloadDecorations(forDateComponents: [dateComponents], animated: true)
        }
    }
    
    
    
}

extension ViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    // UICalendarView
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        return nil
    }


    
    // 달력에서 날짜 선택했을 경우
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selection.setSelected(dateComponents, animated: true)
        
        selectedDate = dateComponents

        reloadDateView(date: Calendar.current.date(from: dateComponents!))
        
        if let date = Calendar.current.date(from: dateComponents!) {
            
            let modalViewController = BillModalViewController(date: date)
            if let sheet = modalViewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
            }
            present(modalViewController, animated: true)
        }
    }
    
   
}

extension ViewController {
    func fetchBill(){
        guard var url = URLComponents(string: "https://open.assembly.go.kr/portal/openapi/nzmimeepazxkubdpn") else {return}
        
        guard let key = Bundle.main.object(forInfoDictionaryKey: "serviceKey") as? String else {return}
        let serviceKey = key
        print(key)
        
        
        
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
                  let data = data,
                  let bills = try? JSONDecoder().decode(Bills.self, from: data) else {
                print("ERROR: URLSession data task \(error?.localizedDescription ?? "")")
                
                return
            }
            
            switch response.statusCode{
            case (200...299)://성공
                self.dataBills += [bills]
                print(dataBills)
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
    



