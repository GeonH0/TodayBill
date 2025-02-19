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

    // MARK: - Initializer
    init(searchResults: [StarredBill]) {
        self.searchResults = searchResults
        super.init(items: searchResults)
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
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    // MARK: - Update Results
    
    func updateResults(_ results: [StarredBill]) {
        self.searchResults = results
        self.favoriteItems = Set(StarBillManager.shared.loadStarredBills().map { $0.ID })
        self.updateItems(searchResults)
    }
    
    override func favoriteButtonTapped(for itemID: String) {
        if favoriteItems.contains(itemID) {
            favoriteItems.remove(itemID)
            StarBillManager.shared.removeBillFromStarred(by: itemID)
        } else {
            favoriteItems.insert(itemID)
            if let bill = items.first(where: { $0.ID == itemID }) {
                StarBillManager.shared.addBillToStarred(bill)
            }
        }
        collectionView.reloadData()
    }
}
