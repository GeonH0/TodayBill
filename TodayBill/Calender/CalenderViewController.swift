//
//  ViewController.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//
import UIKit

class CalenderViewController: UIViewController {
    private let contentView = CalendarView()
    private let billsService = BillsService()
    private var todayListViewController: TodayBillsViewController!
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "발의된 법안 없음"
        label.textColor = .gray
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private var currentPIndex: Int = 1
    private var age: Int = 22
    private var billsByDate: [String: [StarredBill]] = [:]
    
    var selectedDate: String?
    
    override func loadView() {
        view = contentView
        view.backgroundColor = .white
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        todayListViewController = TodayBillsViewController(todayBills: [])
        setupCalendar()
        setupConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupConstraints() {
        addChild(todayListViewController)
        todayListViewController.view.translatesAutoresizingMaskIntoConstraints = false
        emptyLabel.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(todayListViewController.view)
        view.addSubview(emptyLabel)
        
        NSLayoutConstraint.activate([
            todayListViewController.collectionView.topAnchor.constraint(equalTo: contentView.dateView.bottomAnchor),
            todayListViewController.collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            todayListViewController.collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            todayListViewController.collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -55),
            emptyLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            emptyLabel.centerYAnchor.constraint(equalTo: todayListViewController.view.centerYAnchor)
            
        ])
    }
    
    private func setupCalendar() {
        contentView.dateView.delegate = self
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        contentView.dateView.selectionBehavior = dateSelection
    }
    
    private func fetchBills(for date: Date) {
        guard let formattedDate = formatDate(date) else {
            print("날짜 변환 실패")
            return
        }
        
        selectedDate = formattedDate
        
        loadBills { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let rows):
                    self.processBills(rows)
                    self.handlePagination(rows, for: date)
                    
                case .failure(let error):
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }

    private func formatDate(_ date: Date) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
    
    private func loadBills(completion: @escaping (Result<[Row], Error>) -> Void) {
        billsService.fetchBills(pIndex: currentPIndex, age: age, completion: completion)
    }

    private func processBills(_ rows: [Row]) {
        for row in rows {
            let dateKey = row.PROPOSE_DT
            let starredBill = StarredBill(ID: row.BILL_ID, age: Int(row.AGE)!, name: row.BILL_NAME)
            
            // 중복 방지: 같은 법안이 두 번 저장되지 않도록 Set 활용
            if !(billsByDate[dateKey, default: []].contains { $0.ID == starredBill.ID }) {
                billsByDate[dateKey, default: []].append(starredBill)
            }
        }
        
        let todayBills = billsByDate[selectedDate ?? ""] ?? []
        todayListViewController.updateBills(bills: todayBills)
        emptyLabel.isHidden = !todayBills.isEmpty
    }

    private func handlePagination(_ rows: [Row], for date: Date) {
        guard let oldestDate = rows.map({ $0.PROPOSE_DT }).min() else { return }

        if oldestDate <= "2020-05-30" {
            return // 2020년 5월 30일 이전의 법안은 요청하지 않음
        }
        
        if oldestDate <= "2024-05-30" {
            if age == 22 {
                age = 21
                currentPIndex = 1
                fetchBills(for: date)
            } else {
                currentPIndex += 1
            }
        } else {
            currentPIndex += 1
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "법안 불러오기 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }    
}

extension CalenderViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return }
        fetchBills(for: date)
    }
}
