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
    private let searchBills = BillsSearchService(billsService: BillsService())
    private var searchResultsViewController: SearchResultsViewController!
    private var currentIndex: Int = 1
    private var currentSearchTerm: String?
    private var isLoadingSearch = false
    private var canLoadMoreResults = true
    
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
            searchResultsViewController.collectionView.topAnchor.constraint(equalTo: contentView.searchBar.bottomAnchor),
            searchResultsViewController.collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsViewController.collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsViewController.collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            
        ])
        searchResultsViewController.view.isHidden = true
    }
    
    private func performSearch(with searchTerm: String, reset: Bool = true, completion: @escaping (Bool) -> Void) {
        let normalizedTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTerm.isEmpty, !isLoadingSearch else {
            completion(false)
            return
        }
        
        if reset {
            currentIndex = 1
            currentSearchTerm = normalizedTerm
            canLoadMoreResults = true
            searchResultsViewController.view.isHidden = true
            contentView.setResultsVisible(false)
            contentView.showLoadingState("검색 중입니다.")
        }
        
        isLoadingSearch = true
        searchBills.searchBills(pIndex: currentIndex, billName: normalizedTerm) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoadingSearch = false
                switch result {
                case .success(let rows):
                    let resultTitles: [StarredBill] = rows.map {
                        StarredBill(
                            ID: $0.BILL_ID,
                            age: Int($0.AGE) ?? 0,
                            name: $0.BILL_NAME
                        )
                    }
                    
                    if reset {
                        self.searchResultsViewController.updateResults(resultTitles)
                    } else {
                        let mergedResults = self.mergeUniqueBills(self.searchResultsViewController.items + resultTitles)
                        self.searchResultsViewController.updateResults(mergedResults)
                    }
                    
                    self.canLoadMoreResults = !rows.isEmpty
                    self.contentView.showIdleState()
                    self.contentView.setResultsVisible(true)
                    self.searchResultsViewController.view.isHidden = false
                    completion(true)
                    
                case .failure(let error):
                    if reset {
                        self.contentView.showErrorState("검색에 실패했습니다.\n\(error.localizedDescription)")
                        self.searchResultsViewController.view.isHidden = true
                    } else {
                        self.canLoadMoreResults = false
                    }
                    completion(false)
                }
            }
        }
    }
    
    private func loadNextPageIfNeeded() {
        guard canLoadMoreResults, !isLoadingSearch, let currentSearchTerm = currentSearchTerm else { return }
        currentIndex += 1
        performSearch(with: currentSearchTerm, reset: false) { [weak self] success in
            if !success {
                self?.currentIndex = max(1, (self?.currentIndex ?? 1) - 1)
            }
        }
    }
    
    private func mergeUniqueBills(_ bills: [StarredBill]) -> [StarredBill] {
        var seenIDs = Set<String>()
        return bills.filter { bill in
            guard !seenIDs.contains(bill.ID) else { return false }
            seenIDs.insert(bill.ID)
            return true
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
        let retryTerm = currentSearchTerm ?? contentView.searchBar.text ?? ""
        performSearch(with: retryTerm) { _ in }
    }
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            DispatchQueue.main.async {
                self.currentSearchTerm = nil
                self.canLoadMoreResults = true
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
