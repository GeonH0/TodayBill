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
        updateFilterSummary()
        contentView.showIdleState()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        updateFilterSummary()
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
        searchResultsViewController.view.backgroundColor = Theme.backgroundColor
        searchResultsViewController.collectionView.backgroundColor = Theme.backgroundColor
        view.addSubview(searchResultsViewController.view)
        searchResultsViewController.onReachedEnd = { [weak self] in
            self?.loadNextPageIfNeeded()
        }
        
        NSLayoutConstraint.activate([
            searchResultsViewController.view.topAnchor.constraint(equalTo: contentView.resultsTopAnchor, constant: 8),
            searchResultsViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchResultsViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            searchResultsViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            
        ])
        searchResultsViewController.didMove(toParent: self)
        searchResultsViewController.view.isHidden = true
    }

    private func bindViewModel() {
        viewModel.onPaginationChange = { [weak self] state in self?.searchResultsViewController.updatePagination(state) }
        viewModel.onSearchCompleted = { [weak self] term in
            guard let self else { return }
            self.recentSearchManager.save(searchTerm: term)
            self.contentView.updateRecentSearches(self.recentSearchManager.load())
        }

        viewModel.onStateChange = { [weak self] state in
            guard let self = self else { return }

            switch state {
            case .idle:
                self.searchResultsViewController.view.isHidden = true
                self.contentView.updateResultCount(nil)
                self.contentView.setResultsVisible(false)
            case .loading(let message):
                self.searchResultsViewController.view.isHidden = true
                self.contentView.updateResultCount(nil)
                self.contentView.setResultsVisible(false)
                self.contentView.showLoadingState(message)
            case .loaded(let snapshots):
                self.searchResultsViewController.updateResults(snapshots)
                self.contentView.updateResultCount(snapshots.count, total: self.viewModel.totalCount, isUsingCache: self.viewModel.isUsingCache)
                self.contentView.showIdleState()
                self.contentView.setResultsVisible(true)
                self.searchResultsViewController.view.isHidden = false
            case .empty(let message):
                self.searchResultsViewController.updateResults([BillSnapshot]())
                self.contentView.updateResultCount(0, total: self.viewModel.totalCount, isUsingCache: self.viewModel.isUsingCache)
                self.contentView.showIdleState()
                self.contentView.setResultsVisible(true)
                self.searchResultsViewController.setEmptyMessage(message)
                self.searchResultsViewController.view.isHidden = false
            case .error(let message):
                self.contentView.showErrorState(message)
                self.searchResultsViewController.view.isHidden = true
            }
        }
    }
    
    private func performSearch(with searchTerm: String) {
        let normalizedTerm = searchTerm.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !normalizedTerm.isEmpty else { viewModel.clearResults(); return }
        contentView.searchBar.text = normalizedTerm
        contentView.searchBar.resignFirstResponder()
        viewModel.search(query: normalizedTerm)
        updateFilterSummary()
    }

    private func loadNextPageIfNeeded() {
        viewModel.loadNextPageIfNeeded()
    }
    
    private func applyFilter(_ filter: BillFilter) {
        viewModel.updateFilter(filter)
        updateFilterSummary()
        if !filter.normalizedQuery.isEmpty { viewModel.search() }
    }

    private func updateFilterSummary() {
        contentView.updateFilterSummary(viewModel.filter)
    }
}

// MARK: - SearchViewDelegate

extension SearchViewController: SearchViewDelegate {
    func showFilters(from sourceView: UIView) {
        let panel = SearchFilterViewController(filter: viewModel.filter)
        panel.onChange = { [weak self] in self?.applyFilter($0) }
        panel.modalPresentationStyle = .popover
        let width = min(340, view.bounds.width - 32)
        let source = sourceView.convert(sourceView.bounds, to: view)
        panel.loadViewIfNeeded()
        panel.sizeToFit(width: width, maximumHeight: max(180, view.safeAreaLayoutGuide.layoutFrame.maxY - source.maxY - 20))
        if let popover = panel.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
            popover.permittedArrowDirections = .up
            popover.backgroundColor = Theme.cellBackgroundColor
            popover.delegate = panel
        }
        present(panel, animated: true)
    }

    func deleteAll() {
        recentSearchManager.deleteAll()
        DispatchQueue.main.async {
            self.contentView.updateRecentSearches([])
        }
    }
    
    func didSelectSearchTerm(_ term: String) { performSearch(with: term) }

    func retrySearch() {
        performSearch(with: viewModel.filter.normalizedQuery.isEmpty ? (contentView.searchBar.text ?? "") : viewModel.filter.normalizedQuery)
    }

}

// MARK: - UISearchBarDelegate

extension SearchViewController: UISearchBarDelegate {
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // Editing invalidates old responses immediately, including while a result is loading.
        viewModel.clearResults()
        updateFilterSummary()
        contentView.setResultsVisible(false)
        contentView.showIdleState()
        searchResultsViewController.view.isHidden = true
    }

    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        performSearch(with: searchBar.text ?? "")
    }
}
