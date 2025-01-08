//
//  Modal.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//
import UIKit

protocol BillModalViewControllerDelegate: AnyObject {
    func favoriteDataUpdated(_ favoriteData: [Row])
}

import UIKit

class BillModalViewController: UIViewController, UISearchBarDelegate, BillModalViewControllerDelegate {
    private var date: Date
    var dataRows = [Row]()
    var favoriteData = [Row]()

    private lazy var searchBar: UISearchBar = {
        let searchBar = UISearchBar()
        searchBar.delegate = self
        searchBar.layer.cornerRadius = 10
        searchBar.clipsToBounds = true
        return searchBar
    }()

    private lazy var collectionViewController: BillModalCollectionViewController = {
        let controller = BillModalCollectionViewController()
        controller.delegate = self
        return controller
    }()

    init(date: Date, dataRows: [Row], favoriteData: [Row]) {
        self.date = date
        self.dataRows = dataRows
        self.favoriteData = favoriteData
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        setupSubviews()
        setupConstraints()
        initializeData()
    }

    private func setupSubviews() {
        view.addSubview(searchBar)
        addChild(collectionViewController)
        view.addSubview(collectionViewController.view)
        collectionViewController.didMove(toParent: self)
    }

    private func setupConstraints() {
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        collectionViewController.view.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 10),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
            collectionViewController.view.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 10),
            collectionViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func initializeData() {
        collectionViewController.dataRows = dataRows
        collectionViewController.filteredDataRows = dataRows
        collectionViewController.favoriteData = favoriteData
        collectionViewController.reloadData()
    }

    func favoriteDataUpdated(_ favoriteData: [Row]) {
        self.favoriteData = favoriteData
        print("Favorite Data Updated")
    }

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        let filteredData = searchText.isEmpty ? dataRows : dataRows.filter { $0.BILL_NAME.localizedCaseInsensitiveContains(searchText) }
        collectionViewController.filteredDataRows = filteredData
        collectionViewController.reloadData()
    }
}
