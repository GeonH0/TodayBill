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

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        contentView.delegate = self
        contentView.searchBar.delegate = self

        // 초기 검색 기록 로드
        contentView.updateRecentSearches(recentSearchManager.load())
    }

    private func setupUI() {
        view.backgroundColor = .white
    }
}

// MARK: - SearchViewDelegate
extension SearchViewController: SearchViewDelegate {
    func deleteAll() {
        recentSearchManager.deleteAll()
        contentView.updateRecentSearches([])
    }

    func didSelectSearchTerm(_ term: String) {
        print("Performing search for: \(term)")
    }
}

// MARK: - UISearchBarDelegate
extension SearchViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchTerm = searchBar.text?.trimmingCharacters(in: .whitespacesAndNewlines), !searchTerm.isEmpty else {
            return
        }        
        recentSearchManager.save(searchTerm: searchTerm)
        contentView.updateRecentSearches(recentSearchManager.load())
        print("Performing search for: \(searchTerm)")
        searchBar.resignFirstResponder()
    }
}
