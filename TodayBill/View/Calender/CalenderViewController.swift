//
//  ViewController.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//
import UIKit

final class CalenderViewController: UIViewController {
    private let contentView = CalendarView()
    private let billsRepository = BillsRepository()
    private var todayListViewController: TodayBillsViewController!
    private var selectedDate: String?
    private var isUserSelectingDate = false
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "발의된 법안 없음"
        label.textColor = Theme.emptyLabelTextColor
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    override func loadView() {
        view = contentView
        view.backgroundColor = Theme.backgroundColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        todayListViewController = TodayBillsViewController(todayBills: [])
        setupCalendar()
        setupConstraints()
        fetchBills(for: Date(), isInitialLoad: true)
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
    
    /// isInitialLoad가 true이면 앱 최초 실행 시 최신 날짜로 UI를 업데이트합니다.
    private func fetchBills(for date: Date, isInitialLoad: Bool) {
        billsRepository.fetchBills(for: date, isUserSelectingDate: !isInitialLoad) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let bills):
                    
                    if isInitialLoad, let latest = self.billsRepository.getLatestAvailableDate() {
                        self.selectedDate = latest
                        self.updateUICalendarSelection(to: latest)
                    }
                    
                    self.todayListViewController.updateBills(bills: bills)
                    self.emptyLabel.isHidden = !bills.isEmpty
                    
                case .failure(let error):
                    self.showErrorAlert(message: error.localizedDescription)
                }
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "법안 불러오기 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
    
    private func updateUICalendarSelection(to dateString: String) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        
        guard let date = formatter.date(from: dateString) else { return }

        if let calendarSelection = contentView.dateView.selectionBehavior as? UICalendarSelectionSingleDate {
            let components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            calendarSelection.setSelected(components, animated: true)
        }
    }
}

extension CalenderViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return }
        fetchBills(for: date, isInitialLoad: false)
    }
}
