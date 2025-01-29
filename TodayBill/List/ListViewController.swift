//
//  ListViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/25/25.
//

import Foundation

import UIKit

class ListViewController: UIViewController {
    var items: [StarredBill]
    var favoriteItems: Set<String> = []
    
    lazy var collectionView: ListView = {
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = CGSize(width: view.frame.width - 40, height: 60)
        layout.minimumLineSpacing = 16

        let collectionView = ListView(cellType: ListViewCell.self, layout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    init(items: [StarredBill]) {
        self.items = items
        let starredBills = StarBillManager.shared.loadStarredBills().map { $0.name }
        self.favoriteItems = Set(starredBills)
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    private func setupUI() {
        view.addSubview(collectionView)
        view.backgroundColor = .white
    }
    
    func updateItems(_ newItems: [StarredBill]) {
        self.items = newItems
        collectionView.reloadData()
    }
    
    func favoriteButtonTapped(for itemID: String) {        
        if favoriteItems.contains(itemID) {
            favoriteItems.remove(itemID)
            StarBillManager.shared.removeBillFromStarred(by: itemID)
            
            if let index = items.firstIndex(where: { $0.ID == itemID }) {
                items.remove(at: index)
                print(index)
                collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
            } else {
                collectionView.reloadData()
            }
        } else {
            favoriteItems.insert(itemID)
            if let bill = items.first(where: { $0.ID == itemID }) {
                StarBillManager.shared.addBillToStarred(bill)
            }
            collectionView.reloadData()
        }
    }
    
    func updateFavoriteItems() {
        let starredBills = StarBillManager.shared.loadStarredBills().map { $0.ID }
        self.favoriteItems = Set(starredBills)
        collectionView.reloadData()
    }
}

extension ListViewController: UICollectionViewDataSource, UICollectionViewDelegate,ListViewCellDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: ListViewCell.self),
            for: indexPath
        ) as? ListViewCell else {
            return UICollectionViewCell()
        }

        let item = items[indexPath.row]
        let isFavorited = favoriteItems.contains(item.ID)
                
        cell.configure(with: item, isFavorited: isFavorited)
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedBill = items[indexPath.row]
        print("Selected ID: \(selectedBill.ID), Name: \(selectedBill.name)")
    }
}
