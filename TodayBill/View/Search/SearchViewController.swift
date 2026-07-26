//
//  SearchViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import UIKit

final class SearchViewController: UIViewController {
    private let contentView = SearchView()
    private let recentSearchManager = RecentSearchManager()
    private let viewModel = SearchViewModel()
    private var searchResultsViewController: SearchResultsViewController!
    private var pendingSearchCompletion: ((Bool) -> Void)?
    
    override func loadView() {
        view = contentView
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        contentView.delegate = self
        contentView.searchBar.delegate = self
        contentView.updateRecentSearches(recentSearchManager.load())
        setupSearchResultsView()
        bindViewModel()
        contentView.updateFilterSummary(viewModel.filter.activeSummary)
        contentView.showIdleState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    private func setupUI() {
        view.backgroundColor = Theme.backgroundColor
    }
    
    private func setupSearchResultsView() {
        searchResultsViewController = SearchResultsViewController(searchResults: [])
        addChild(searchResultsViewController)
        searchResultsViewController.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(searchResultsViewController.view)
        searchResultsViewController.onReachedEnd = { [weak self] in
            self?.loadNextPageIfNeeded()
        }
        
        NSLayoutConstraint.activate([
            searchResultsViewController.collectionView.topAnchor.constraint(equalTo: contentView.resultsTopAnchor, constant: 8),
            searchResultsViewController.collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsViewController.collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsViewController.collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            
        ])
        searchResultsViewController.view.isHidden = true
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .idle:
                self.searchResultsViewController.view.isHidden = true
                self.contentView.setResultsVisible(false)
            case .loading(let message):
                self.searchResultsViewController.view.isHidden = true
                self.contentView.setResultsVisible(false)
                self.contentView.showLoadingState(message)
            case .loaded(let snapshots):
                self.searchResultsViewController.updateResults(snapshots)
                self.contentView.showIdleState()
                self.contentView.setResultsVisible(true)
                self.searchResultsViewController.view.isHidden = false
                self.pendingSearchCompletion?(true)
                self.pendingSearchCompletion = nil
            case .empty(let message):
                self.searchResultsViewController.updateResults([BillSnapshot]())
                self.contentView.showIdleState()
                self.contentView.setResultsVisible(true)
                self.searchResultsViewController.setEmptyMessage(message)
                self.searchResultsViewController.view.isHidden = false
                self.pendingSearchCompletion?(true)
                self.pendingSearchCompletion = nil
            case .error(let message):
                self.contentView.showErrorState(message)
                self.searchResultsViewController.view.isHidden = true
                self.pendingSearchCompletion?(false)
                self.pendingSearchCompletion = nil
            }
        }
    }
    
    private func performSearch(with searchTerm: String, reset: Bool = true, completion: @escaping (Bool) -> Void) {
        let normalizedTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTerm.isEmpty else {
            completion(false)
            return
        }

        pendingSearchCompletion = completion
        if reset {
            viewModel.search(query: normalizedTerm, reset: true)
        } else {
            viewModel.loadNextPageIfNeeded()
        }
    }
    
    private func loadNextPageIfNeeded() {
        viewModel.loadNextPageIfNeeded()
    }
    
    private func mergeUniqueBills(_ bills: [StarredBill]) -> [StarredBill] {
        var seenIDs = Set<String>()
        return bills.filter { bill in
            guard !seenIDs.contains(bill.ID) else { return false }
            seenIDs.insert(bill.ID)
            return true
        }
    }

    private func updateFilter(_ transform: (inout BillFilter) -> Void) {
        var filter = viewModel.filter
        transform(&filter)
        viewModel.updateFilter(filter)
        contentView.updateFilterSummary(filter.activeSummary)

        if !filter.normalizedQuery.isEmpty {
            viewModel.search(reset: true)
        }
    }
}

// MARK: - SearchViewDelegate

extension SearchViewController: SearchViewDelegate {
    func deleteAll() {
        recentSearchManager.deleteAll()
        DispatchQueue.main.async {
            self.contentView.updateRecentSearches([])
        }
    }
    
    func didSelectSearchTerm(_ term: String) {
        performSearch(with: term) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.recentSearchManager.save(searchTerm: term)
                DispatchQueue.main.async {
                    self.contentView.searchBar.text = term
                    self.contentView.updateRecentSearches(self.recentSearchManager.load())
                }
            }
        }
    }
    
    func retrySearch() {
        let retryTerm = viewModel.filter.normalizedQuery.isEmpty ? (contentView.searchBar.text ?? "") : viewModel.filter.normalizedQuery
        performSearch(with: retryTerm) { _ in }
    }

    func showFilters() {
        let alert = UIAlertController(title: "검색 필터", message: nil, preferredStyle: .actionSheet)

        let statusActions: [(String, BillStage?)] = [
            ("전체 상태", nil),
            ("제안", .proposed),
            ("위원회", .committee),
            ("법사위", .lawReview),
            ("본회의", .plenary),
            ("완료", .completed)
        ]

        statusActions.forEach { title, stage in
            alert.addAction(UIAlertAction(title: title, style: .default) { [weak self] _ in
                self?.updateFilter { $0.status = stage }
            })
        }

        alert.addAction(UIAlertAction(title: "소관 위원회 입력", style: .default) { [weak self] _ in
            self?.presentCommitteeFilterAlert()
        })

        if let committee = viewModel.filter.committee, !committee.isEmpty {
            alert.addAction(UIAlertAction(title: "위원회 필터 해제 (\(committee))", style: .default) { [weak self] _ in
                self?.updateFilter { $0.committee = nil }
            })
        }

        alert.addAction(UIAlertAction(title: viewModel.filter.favoriteOnly ? "즐겨찾기만 해제" : "즐겨찾기만 보기", style: .default) { [weak self] _ in
            self?.updateFilter { $0.favoriteOnly.toggle() }
        })

        alert.addAction(UIAlertAction(title: "최근 30일", style: .default) { [weak self] _ in
            self?.updateFilter { $0.dateRange = BillDateRange.recent(days: 30) }
        })

        alert.addAction(UIAlertAction(title: "최근 1년", style: .default) { [weak self] _ in
            self?.updateFilter { $0.dateRange = BillDateRange.recent(days: 365) }
        })

        alert.addAction(UIAlertAction(title: "전체 기간", style: .default) { [weak self] _ in
            self?.updateFilter { $0.dateRange = .all }
        })

        alert.addAction(UIAlertAction(title: viewModel.filter.sortOrder == .latest ? "오래된순" : "최신순", style: .default) { [weak self] _ in
            self?.updateFilter { $0.sortOrder = $0.sortOrder == .latest ? .oldest : .latest }
        })

        alert.addAction(UIAlertAction(title: "필터 초기화", style: .destructive) { [weak self] _ in
            self?.updateFilter {
                $0.status = nil
                $0.favoriteOnly = false
                $0.dateRange = .all
                $0.sortOrder = .latest
            }
        })
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))

        if let popover = alert.popoverPresentationController {
            popover.sourceView = contentView
            popover.sourceRect = CGRect(x: contentView.bounds.midX, y: contentView.safeAreaInsets.top + 56, width: 1, height: 1)
        }

        present(alert, animated: true)
    }

    private func presentCommitteeFilterAlert() {
        let alert = UIAlertController(title: "소관 위원회", message: "예: 교육, 환경노동, 법제사법", preferredStyle: .alert)
        alert.addTextField { [weak self] textField in
            textField.placeholder = "위원회명"
            textField.text = self?.viewModel.filter.committee
            textField.clearButtonMode = .whileEditing
        }
        alert.addAction(UIAlertAction(title: "적용", style: .default) { [weak self, weak alert] _ in
            let value = alert?.textFields?.first?.text?.trimmingCharacters(in: .whitespacesAndNewlines)
            self?.updateFilter { $0.committee = value?.isEmpty == false ? value : nil }
        })
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        present(alert, animated: true)
    }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            DispatchQueue.main.async {
                self.viewModel.clearResults()
                self.contentView.setResultsVisible(false)
                self.contentView.showIdleState()
                self.searchResultsViewController.view.isHidden = true
            }
        }
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerm = searchBar.text, !searchTerm.isEmpty else {
            DispatchQueue.main.async {
                self.searchResultsViewController.view.isHidden = true
            }
            return
        }
        searchBar.resignFirstResponder()
        performSearch(with: searchTerm) { [weak self] success in
            guard let self = self else { return }
            if success {
                self.recentSearchManager.save(searchTerm: searchTerm)
                DispatchQueue.main.async {
                    self.contentView.updateRecentSearches(self.recentSearchManager.load())
                }
            }
        }
    }
}
