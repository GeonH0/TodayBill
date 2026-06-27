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
    var snapshotItems: [BillSnapshot] = []
    var favoriteItems: Set<String> = []
    private let detailBillService = DetailBillService()
    private let billRepository = BillRepository.shared
    private var emptyMessage: String?
    private var usesSnapshots = false
    private var horizontalContentInset: CGFloat = 20
    private var showsSnapshotProposedDate = true
    
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
        layout.sectionInset = UIEdgeInsets(
            top: 16,
            left: horizontalContentInset,
            bottom: 16,
            right: horizontalContentInset
        )

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

    func setHorizontalContentInset(_ inset: CGFloat) {
        horizontalContentInset = max(0, inset)
        if let layout = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.sectionInset = UIEdgeInsets(
                top: layout.sectionInset.top,
                left: horizontalContentInset,
                bottom: layout.sectionInset.bottom,
                right: horizontalContentInset
            )
            layout.invalidateLayout()
        }
        collectionView.reloadData()
    }

    func setShowsSnapshotProposedDate(_ isShown: Bool) {
        showsSnapshotProposedDate = isShown
        collectionView.reloadData()
    }
    
    func updateItems(_ newItems: [StarredBill]) {
        self.usesSnapshots = false
        self.snapshotItems = []
        self.items = newItems
        collectionView.reloadData()
        updateEmptyState()
    }

    func updateSnapshots(_ snapshots: [BillSnapshot]) {
        self.usesSnapshots = true
        self.snapshotItems = snapshots
        self.items = snapshots.map { $0.toStarredBill() }
        self.favoriteItems = Set(CoreDataManager.shared.fetchFavoriteSnapshots().map { $0.billID })
        collectionView.reloadData()
        updateEmptyState()
    }
    
    func favoriteButtonTapped(for itemID: String) {        
        if usesSnapshots {
            billRepository.toggleFavorite(id: itemID) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    switch result {
                    case .success(let updated):
                        if updated.isFavorite {
                            self.favoriteItems.insert(itemID)
                        } else {
                            self.favoriteItems.remove(itemID)
                        }
                        if let index = self.snapshotItems.firstIndex(where: { $0.billID == itemID }) {
                            self.snapshotItems[index] = updated
                            self.items[index] = updated.toStarredBill()
                        }
                        self.collectionView.reloadData()
                        self.updateEmptyState()
                    case .failure:
                        self.collectionView.reloadData()
                    }
                }
            }
            return
        }

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
        let coreDataFavorites = CoreDataManager.shared.fetchFavoriteSnapshots().map { $0.billID }
        let userDefaultsFavorites = StarBillManager.shared.loadStarredBills().map { $0.ID }
        self.favoriteItems = Set(coreDataFavorites + userDefaultsFavorites)
        collectionView.reloadData()
        updateEmptyState()
    }
    
    func didDisplayItem(at indexPath: IndexPath) {
    }

    func contentHeight(for width: CGFloat) -> CGFloat {
        let itemCount = usesSnapshots ? snapshotItems.count : items.count
        guard itemCount > 0 else { return 180 }

        let availableWidth = max(280, width)
        let contentWidth = availableWidth - horizontalContentInset * 2
        let itemHeights = (0..<itemCount).map { index -> CGFloat in
            let billName = (usesSnapshots ? snapshotItems[index].title : items[index].name) as NSString
            let textWidth = contentWidth - 56
            let textHeight = billName.boundingRect(
                with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: [.font: UIFont.boldSystemFont(ofSize: 16)],
                context: nil
            ).height
            return max(112, ceil(textHeight) + 74)
        }

        let spacing = CGFloat(max(0, itemCount - 1)) * 16
        return itemHeights.reduce(0, +) + spacing + 32
    }
    
    private func updateEmptyState() {
        emptyLabel.text = emptyMessage
        let isEmpty = usesSnapshots ? snapshotItems.isEmpty : items.isEmpty
        emptyLabel.isHidden = emptyMessage == nil || !isEmpty
    }
}

extension ListViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout, ListViewCellDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return usesSnapshots ? snapshotItems.count : items.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: String(describing: ListViewCell.self),
            for: indexPath
        ) as? ListViewCell else {
            return UICollectionViewCell()
        }

        if usesSnapshots {
            let snapshot = snapshotItems[indexPath.row]
            let isFavorited = favoriteItems.contains(snapshot.billID) || snapshot.isFavorite
            cell.configure(
                with: snapshot,
                isFavorited: isFavorited,
                showsProposedDate: showsSnapshotProposedDate
            )
        } else {
            let item = items[indexPath.row]
            let isFavorited = favoriteItems.contains(item.ID)
            cell.configure(with: item, isFavorited: isFavorited)
        }
        cell.delegate = self
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedBill = usesSnapshots ? snapshotItems[indexPath.row].toStarredBill() : items[indexPath.row]
        let detailVC = DetailViewController(billID: selectedBill.ID, age: selectedBill.age)
        navigationController?.pushViewController(detailVC, animated: true)
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        didDisplayItem(at: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.bounds.width - horizontalContentInset * 2
        let billName = (usesSnapshots ? snapshotItems[indexPath.row].title : items[indexPath.row].name) as NSString
        let textWidth = width - 56
        let textHeight = billName.boundingRect(
            with: CGSize(width: textWidth, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: UIFont.boldSystemFont(ofSize: 16)],
            context: nil
        ).height
        return CGSize(width: width, height: max(112, ceil(textHeight) + 74))
    }
}
