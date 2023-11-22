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

            if count > 0 {
                return .customView {
                    let label = UILabel()
                    label.text = "\(count)"
                    label.textAlignment = .center
                    label.textColor = .blue
                    label.layer.cornerRadius = label.frame.size.width / 2
                    label.clipsToBounds = true
                    print(count)
                    return label
                }
            }

            return nil
        }

    // 달력에서 날짜 선택했을 경우
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selection.setSelected(dateComponents, animated: true)
        
        selectedDate = dateComponents

        reloadDateView(date: Calendar.current.date(from: dateComponents!))
        
        if let date = Calendar.current.date(from: dateComponents!) {
            
            let modalViewController = BillModalViewController(date: date,dataBills: dataBills)
            if let sheet = modalViewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20
                sheet.prefersScrollingExpandsWhenScrolledToEdge = true
            }
            present(modalViewController, animated: true)
        }
    }
    
    func countOfBillsForSelectedDate(selectedDate: Date) -> Int {
        let formattedDate = dateFormattedString(from: selectedDate)

        let billsForSelectedDate = dataBills.compactMap { bills in
            return bills.nzmimeepazxkubdpn.flatMap { bill in
                let selectedBills = bill.row?.filter {
//                    print("PROPOSE_DT: \($0.PROPOSE_DT), formattedDate: \(formattedDate)")
                    return $0.PROPOSE_DT == formattedDate
                }
                return selectedBills
            }
        }.flatMap { $0 }

//        print("Bills for \(formattedDate): \(billsForSelectedDate)")

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
