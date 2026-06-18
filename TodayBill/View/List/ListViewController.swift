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
    private let detailBillService = DetailBillService()
    private var emptyMessage: String?
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.textColor = Theme.emptyLabelTextColor
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textAlignment = .center
        label.numberOfLines = 0
        label.isHidden = true
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    lazy var collectionView: ListView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 16
        layout.sectionInset = UIEdgeInsets(top: 16, left: 20, bottom: 16, right: 20)

        let collectionView = ListView(cellType: ListViewCell.self, layout: layout)
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
    }()
    
    init(items: [StarredBill]) {
        self.items = items
        let starredBills = StarBillManager.shared.loadStarredBills().map { $0.ID }
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
        view.addSubview(emptyLabel)
        view.backgroundColor = Theme.backgroundColor
        
        NSLayoutConstraint.activate([
            emptyLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            emptyLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            emptyLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        updateEmptyState()
    }
    
    func setEmptyMessage(_ message: String?) {
        emptyMessage = message
        updateEmptyState()
    }
    
    func updateItems(_ newItems: [StarredBill]) {
        self.items = newItems
        collectionView.reloadData()
        updateEmptyState()
    }
    
    func favoriteButtonTapped(for itemID: String) {        
        if favoriteItems.contains(itemID) {
            favoriteItems.remove(itemID)
            StarBillManager.shared.removeBillFromStarred(by: itemID)
            
            if let index = items.firstIndex(where: { $0.ID == itemID }) {
                items.remove(at: index)
                collectionView.deleteItems(at: [IndexPath(item: index, section: 0)])
                updateEmptyState()
            } else {
                collectionView.reloadData()
                updateEmptyState()
            }
        } else {
            favoriteItems.insert(itemID)
            if let bill = items.first(where: { $0.ID == itemID }) {
                StarBillManager.shared.addBillToStarred(bill)
            }
            collectionView.reloadData()
            updateEmptyState()
        }
    }
    
    func updateFavoriteItems() {
        let starredBills = StarBillManager.shared.loadStarredBills().map { $0.ID }
        self.favoriteItems = Set(starredBills)
        collectionView.reloadData()
        updateEmptyState()
    }
    
    func didDisplayItem(at indexPath: IndexPath) {
    }
    
    private func updateEmptyState() {
        emptyLabel.text = emptyMessage
        emptyLabel.isHidden = emptyMessage == nil || !items.isEmpty
    }
}

extension ListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ListViewCellDelegate {
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
        let detailVC = DetailViewController(billID: selectedBill.ID, age: selectedBill.age)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        didDisplayItem(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - 40
        let billName = items[indexPath.row].name as NSString
        let textWidth = width - 56
        let textHeight = billName.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.boldSystemFont(ofSize: 16)],
            context: nil
        ).height
        return CGSize(width: width, height: max(72, ceil(textHeight) + 28))
    }
}
