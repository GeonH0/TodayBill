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
        
        NSLayoutConstraint.activate([
            searchResultsViewController.collectionView.topAnchor.constraint(equalTo: contentView.searchBar.bottomAnchor),
            searchResultsViewController.collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsViewController.collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsViewController.collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -55)
            
        ])
        searchResultsViewController.view.isHidden = true
    }
    
    private func performSearch(with searchTerm: String, completion: @escaping (Bool) -> Void) {
        searchBills.searchBills(pIndex: currentIndex, billName: searchTerm) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let rows):
                    let resultTitles: [StarredBill] = rows.map {
                        StarredBill(
                            ID: $0.BILL_ID,
                            age: Int($0.AGE)!,
                            name: $0.BILL_NAME
                        )
                    }
                    
                    self.searchResultsViewController.updateResults(resultTitles)
                    self.searchResultsViewController.view.isHidden = false
                    completion(true)
                    
                case .failure(let error):
                    self.showErrorAlert(message: error.localizedDescription)
                    completion(false)
                }
            }
        }
    }
    
    private func showErrorAlert(message: String) {
        let alert = UIAlertController(title: "검색 실패", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
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
}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchText.isEmpty {
            DispatchQueue.main.async {
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
