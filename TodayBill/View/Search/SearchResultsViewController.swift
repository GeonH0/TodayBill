//
//  SearchResultsViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/25/25.
//

import Foundation
import UIKit

final class SearchResultsViewController: ListViewController {
    private var searchResults: [StarredBill]
    var onReachedEnd: (() -> Void)?
    private let pageLabel = UILabel()
    private let pageButton = UIButton(type: .system)
    private let pageSpinner = UIActivityIndicatorView(style: .medium)
    private let footer = UIStackView()


    // MARK: - Initializer
    init(searchResults: [StarredBill]) {
        self.searchResults = searchResults
        super.init(items: searchResults)
        setEmptyMessage("검색 결과가 없습니다.")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViewConstraints()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.favoriteItems = Set(StarBillManager.shared.loadStarredBills().map { $0.ID })
        collectionView.reloadData()
    }
    
    private func setupCollectionViewConstraints() {
        footer.axis = .vertical
        footer.alignment = .center
        footer.spacing = 4
        footer.translatesAutoresizingMaskIntoConstraints = false
        pageLabel.font = .preferredFont(forTextStyle: .caption1)
        pageLabel.adjustsFontForContentSizeCategory = true
        pageLabel.textColor = Theme.textMuted
        pageLabel.numberOfLines = 0
        pageLabel.textAlignment = .center
        pageButton.tintColor = Theme.accent
        pageButton.accessibilityIdentifier = "search-next-page"
        pageButton.addAction(UIAction { [weak self] _ in self?.onReachedEnd?() }, for: .touchUpInside)
        pageButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        [pageLabel, pageSpinner, pageButton].forEach { footer.addArrangedSubview($0) }
        view.addSubview(footer)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: footer.topAnchor),
            footer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20),
            footer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -20),
            footer.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        updatePagination(.hidden)
    }

    func updatePagination(_ state: SearchPaginationState) {
        loadViewIfNeeded()
        pageSpinner.stopAnimating()
        pageSpinner.isHidden = true
        pageLabel.isHidden = true
        pageButton.isHidden = true
        switch state {
        case .hidden: break
        case .loading:
            pageSpinner.isHidden = false
            pageSpinner.startAnimating()
        case .more:
            pageButton.isHidden = false
            pageButton.setTitle("결과 더 불러오기", for: .normal)
        case .retry(let message):
            pageLabel.text = message
            pageLabel.isHidden = false
            pageButton.isHidden = false
            pageButton.setTitle("다음 결과 다시 시도", for: .normal)
        case .cached:
            pageLabel.text = "연결할 수 없어 저장된 검색 결과를 표시합니다."
            pageLabel.isHidden = false
        }
    }

    // MARK: - Update Results
    
    func updateResults(_ results: [StarredBill]) {
        self.searchResults = results
        self.favoriteItems = Set(StarBillManager.shared.loadStarredBills().map { $0.ID })
        self.updateItems(searchResults)
    }

    func updateResults(_ snapshots: [BillSnapshot]) {
        self.searchResults = snapshots.map { $0.toStarredBill() }
        self.updateSnapshots(snapshots)
    }
    
    override func favoriteButtonTapped(for itemID: String) {
        super.favoriteButtonTapped(for: itemID)
    }
    
    override func didDisplayItem(at indexPath: IndexPath) {
        guard !items.isEmpty, indexPath.item >= items.count - 5 else { return }
        onReachedEnd?()
    }
}
