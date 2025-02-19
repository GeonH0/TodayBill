//
//  StarBillViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import Foundation
import UIKit

final class StarBillViewController: ListViewController {
    private var starBills: [StarredBill]
        
    init(starBills: [StarredBill]) {
        self.starBills = starBills
        super.init(items: starBills)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitleOverlay()
        loadStarredBills()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let updatedBills = StarBillManager.shared.loadStarredBills()
        updateStarBills(updatedBills)
        navigationItem.title = "즐겨찾기"
    }
    
    private func setupTitleOverlay() {        
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: view.topAnchor),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -55)
        ])
    }
    
    func updateStarBills(_ starBills: [StarredBill]){
        self.starBills = starBills
        self.favoriteItems = Set(starBills.map { $0.ID })
        self.updateItems(starBills)
    }
    
    private func loadStarredBills() {
        let starredBillModels = StarBillManager.shared.loadStarredBills()
        self.starBills = starredBillModels
        updateItems(starredBillModels)
        updateFavoriteItems()
    }
    
    override func favoriteButtonTapped(for itemID: String) {
        if let index = starBills.firstIndex(where: { $0.ID == itemID }) {
            starBills.remove(at: index)
            favoriteItems.remove(itemID)
            StarBillManager.shared.removeBillFromStarred(by: itemID)
            collectionView.performBatchUpdates({
                items.remove(at: index)
                collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            }, completion: nil)
        }
    }
}
