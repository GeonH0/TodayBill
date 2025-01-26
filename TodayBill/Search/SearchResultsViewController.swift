//
//  SearchResultsViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/25/25.
//

import Foundation
import UIKit

final class SearchResultsViewController: ListViewController {
    private var searchResults: [String]

    // MARK: - Initializer
    init(searchResults: [String]) {
        self.searchResults = searchResults
        super.init(items: searchResults)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Update Results
    func updateResults(_ results: [String]) {
        self.searchResults = results
        self.updateItems(searchResults)
    }
}
