//
//  TodayBillsViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/31/25.
//

import Foundation
import UIKit

final class TodayBillsViewController: ListViewController {
    private var todayBills: [StarredBill]
    
    init(todayBills: [StarredBill]) {
        self.todayBills = todayBills
        super.init(items: todayBills)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionViewConstraints()
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
    
    func updateBills(bills: [StarredBill]) {
        todayBills = bills
        self.favoriteItems = Set(StarBillManager.shared.loadStarredBills().map { $0.ID })
        self.updateItems(todayBills)
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
