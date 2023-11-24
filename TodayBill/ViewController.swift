//
//  ViewController.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//
import UIKit

class ViewController: UIViewController {
    
    var dataRows = [Row]()
    
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
    
    func applyConstraints() {
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
            selectedDate = dateComponents
            dateView.reloadDecorations(forDateComponents: [dateComponents], animated: true)
        }
    }
}

extension ViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let selectedDate = Calendar.current.date(from: dateComponents) else {
                return nil
            }

            let count = countOfBillsForSelectedDate(selectedDate: selectedDate)


            return nil
        }

    // 달력에서 날짜 선택했을 경우
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selection.setSelected(dateComponents, animated: true)
        
        selectedDate = dateComponents
        

        reloadDateView(date: Calendar.current.date(from: dateComponents!))
        
        if let date = Calendar.current.date(from: dateComponents!) {
            let filteredData = filterDataForSelectedDate(selectedDate: date)
            let modalViewController = BillModalViewController(date: date,dataRows: filteredData)
            if let sheet = modalViewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
            present(modalViewController, animated: true)
        }
    }
    
    func filterDataForSelectedDate(selectedDate: Date) -> [Row] {
        let formattedDate = dateFormattedString(from: selectedDate)

        let filteredData = dataRows.filter {
            return $0.PROPOSE_DT == formattedDate
        }

        return filteredData
    }
    
    func countOfBillsForSelectedDate(selectedDate: Date) -> Int {
        let formattedDate = dateFormattedString(from: selectedDate)

        let billsForSelectedDate = dataRows.filter {
            return $0.PROPOSE_DT == formattedDate
        }

        return billsForSelectedDate.count
    }


    
    func dateFormattedString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")

        return dateFormatter.string(from: date)
    }
}
