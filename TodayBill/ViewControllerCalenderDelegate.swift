//
//  ViewControllerCalenderDelegate.swift
//  TodayBill
//
//  Created by 김건호 on 11/27/23.
//

import Foundation
import UIKit

extension ViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    

    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let selectedDate = Calendar.current.date(from: dateComponents) else {
            return nil
        }

        let count = countOfBillsForSelectedDate(selectedDate: selectedDate)

        return nil
    }


    // 달력에서 날짜 선택했을 경우
    // 달력에서 날짜 선택했을 경우
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selection.setSelected(dateComponents, animated: true)
        
//        // 달력에서 달이 변경될 때마다 pIndex를 증가시키고 fetchBill을 호출
//        currentPIndex += 1
//        fetchBill(pIndex: currentPIndex)
        
        selectedDate = dateComponents
        reloadDateView(date: Calendar.current.date(from: dateComponents!))
        
        if let date = Calendar.current.date(from: dateComponents!) {
            let filteredData = filterDataForSelectedDate(selectedDate: date)
            let modalViewController = BillModalViewController(date: date, dataRows: filteredData, favoriteData: favoriteData)
            modalViewController.delegate = self  // delegate 설정
            if let sheet = modalViewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
            present(modalViewController, animated: true)
        }
    }
    func calendarView(_ calendarView: UICalendarView, didDisplayMonth month: Int) {
        currentPIndex += 1
        fetchBill(pIndex: currentPIndex)
        print("CHANGE")
    }


    
    func filterDataForSelectedDate(selectedDate: Date) -> [Row] {
        let formattedDate = dateFormattedString(from: selectedDate)

        let filteredData = dataRows.filter {
            return $0.PROPOSE_DT == formattedDate
        }

        return filteredData
    }
    
    func favoriteDataUpdated(_ favoriteData: [Row]) {
        updateFavoriteCollectionView(favoriteData)
    }
    
    func updateFavoriteCollectionView(_ favoriteData: [Row]) {
        self.favoriteData = favoriteData  // 즐겨찾기 데이터를 업데이트
        favoriteCollectionView.reloadData()  // 컬렉션 뷰를 업데이트
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

