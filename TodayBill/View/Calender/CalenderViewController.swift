//
//  ViewController.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//
import UIKit

final class CalenderViewController: UIViewController {
    private let contentView = CalendarView()
    private let viewModel = HomeViewModel()
    private var todayListViewController: TodayBillsViewController!
    private var selectedDate: String?
    private var requestedDate: Date?
    private var isUserSelectingDate = false
    private var currentDashboard: HomeDashboard?

    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "발의된 법안 없음"
        label.textColor = Theme.emptyLabelTextColor
        label.textAlignment = .center
        label.font = Theme.Font.statusMessage
        label.isHidden = true
        return label
    }()

    private let separator: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
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
        setupDashboardActions()
        bindViewModel()
        fetchBills(for: Date(), isInitialLoad: true)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateSelectedListHeight()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        todayListViewController.updateFavoriteItems()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    private func setupConstraints() {
        addChild(todayListViewController)
        todayListViewController.view.translatesAutoresizingMaskIntoConstraints = false
        todayListViewController.collectionView.isScrollEnabled = false
        todayListViewController.setEmptyMessage("선택한 날짜에 표시할 법안이 없습니다.")

        contentView.listContainerView.addSubview(todayListViewController.view)

        NSLayoutConstraint.activate([
            todayListViewController.view.topAnchor.constraint(equalTo: contentView.listContainerView.topAnchor),
            todayListViewController.view.leadingAnchor.constraint(equalTo: contentView.listContainerView.leadingAnchor),
            todayListViewController.view.trailingAnchor.constraint(equalTo: contentView.listContainerView.trailingAnchor),
            todayListViewController.view.bottomAnchor.constraint(equalTo: contentView.listContainerView.bottomAnchor)
        ])
        todayListViewController.didMove(toParent: self)
    }

    private func setupCalendar() {
        contentView.dateView.delegate = self
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        contentView.dateView.selectionBehavior = dateSelection
    }

    private func setupDashboardActions() {
        contentView.dashboardView.onBillSelected = { [weak self] snapshot in
            self?.pushDetail(for: snapshot)
        }

        contentView.dashboardView.onLawSelected = { [weak self] enforcement in
            self?.openLawEnforcement(enforcement)
        }
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .idle:
                break
            case .loading:
                self.emptyLabel.isHidden = true
            case .loaded(let dashboard):
                self.currentDashboard = dashboard
                self.contentView.updateDashboard(dashboard)
                let snapshots = self.selectedSnapshots(from: dashboard)
                if let requestedDateString = self.formattedDate(self.requestedDate), self.isUserSelectingDate {
                    self.selectedDate = requestedDateString
                } else if let latestDate = snapshots.first?.proposedDate {
                    self.selectedDate = latestDate
                    self.updateUICalendarSelection(to: latestDate)
                }
                self.todayListViewController.updateBills(snapshots: snapshots)
                self.contentView.updateSelectedDateTitle(self.selectedDateTitle())
                self.updateSelectedListHeight()
            case .empty(let message):
                self.currentDashboard = nil
                self.contentView.updateDashboard(HomeDashboard())
                self.todayListViewController.updateBills(snapshots: [])
                self.todayListViewController.setEmptyMessage(message)
                self.updateSelectedListHeight()
            case .error(let message):
                self.showErrorAlert(message: message)
            }
        }
    }

    /// isInitialLoad가 true이면 앱 최초 실행 시 최신 날짜로 UI를 업데이트합니다.
    private func fetchBills(for date: Date, isInitialLoad: Bool) {
        requestedDate = date
        isUserSelectingDate = !isInitialLoad
        viewModel.load(date: date)
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

    private func pushDetail(for snapshot: BillSnapshot) {
        let detailVC = DetailViewController(billID: snapshot.billID, age: snapshot.age)
        navigationController?.pushViewController(detailVC, animated: true)
    }

    private func openLawEnforcement(_ enforcement: LawEnforcementSnapshot) {
        if let matchedBillID = enforcement.matchedBillID,
           let snapshot = BillRepository.shared.cachedSnapshot(id: matchedBillID) {
            pushDetail(for: snapshot)
            return
        }

        guard let url = enforcement.detailURL else {
            showErrorAlert(message: "법령 원문 링크가 없습니다.")
            return
        }
        UIApplication.shared.open(url)
    }

    private func selectedDateTitle() -> String {
        guard let selectedDate else { return "선택 날짜 법안" }
        return "\(selectedDate) 법안"
    }

    private func selectedSnapshots(from dashboard: HomeDashboard) -> [BillSnapshot] {
        guard isUserSelectingDate,
              let requestedDateString = formattedDate(requestedDate) else {
            return dashboard.selectedDateBills
        }
        return CoreDataManager.shared.fetchSnapshots(for: requestedDateString)
    }

    private func formattedDate(_ date: Date?) -> String? {
        guard let date else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func updateSelectedListHeight() {
        guard todayListViewController != nil else { return }
        let width = max(0, contentView.listContainerView.bounds.width)
        let height = todayListViewController.contentHeight(for: width)
        contentView.updateListHeight(height)
    }
}

extension CalenderViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        guard let dateComponents = dateComponents,
              let date = Calendar.current.date(from: dateComponents) else { return }
        fetchBills(for: date, isInitialLoad: false)
    }
}
