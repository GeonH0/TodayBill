//
//  ViewControllerCalenderDelegate.swift
//  TodayBill
//
//  Created by 김건호 on 11/27/23.
//

import Foundation
import UIKit

extension CalenderViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    // MARK: - 달력 날짜 장식
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
        guard let selectedDate = Calendar.current.date(from: dateComponents) else { return nil }
        
        // 해당 날짜의 법안 수를 계산
        let count = countOfBillsForSelectedDate(selectedDate: selectedDate)
        if count > 0 {
            return .image(UIImage(systemName: "doc.text.fill"), color: .systemBlue, size: .medium)
        }
        return nil
    }
    
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selection.setSelected(dateComponents, animated: true)
        selectedDate = dateComponents

        // 선택한 날짜를 Date로 변환
        guard let date = Calendar.current.date(from: dateComponents!) else { return }
        
    }

    // MARK: - 데이터 필터링
    func filterDataForSelectedDate(selectedDate: Date) -> [Row] {
        let formattedDate = dateFormattedString(from: selectedDate)
        return dataRows.filter { $0.PROPOSE_DT == formattedDate }
    }

    // MARK: - 법안 개수 계산
    func countOfBillsForSelectedDate(selectedDate: Date) -> Int {
        let formattedDate = dateFormattedString(from: selectedDate)
        return dataRows.filter { $0.PROPOSE_DT == formattedDate }.count
    }

    // MARK: - 날짜 형식 변환
    func dateFormattedString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        return formatter.string(from: date)
    }
}
