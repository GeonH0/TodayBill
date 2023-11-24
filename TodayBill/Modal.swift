//
//  Modal.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//

import UIKit

class BillModalViewController: UIViewController,UISearchBarDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout  {
    
    
    var date: Date
    var dataRows = [Row]()

    
    var searchBar = UISearchBar()
    var tableView = UITableView()
    var collectionView: UICollectionView!

    
    
    init(date: Date,dataRows : [Row]) {
        self.date = date
        self.dataRows = dataRows
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupSearchBar()
        setupCollectionView()
        
        
        
        
        searchBar.delegate = self
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        
        searchBar.layer.cornerRadius = 10
        searchBar.clipsToBounds = true
        
        view.addSubview(searchBar)
        
        NSLayoutConstraint.activate([
            searchBar.topAnchor.constraint(equalTo: view.topAnchor),
            searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        
        
        
        // date를 한국 표준시(KST) 형식으로 포맷팅하여 표시
        let formattedDate = dateFormattedString(from: date)
        
        
        
        view.backgroundColor = .white
        
        
        func setupSearchBar() {
                searchBar.delegate = self
                searchBar.translatesAutoresizingMaskIntoConstraints = false
                searchBar.layer.cornerRadius = 10
                searchBar.clipsToBounds = true
                view.addSubview(searchBar)
                
                NSLayoutConstraint.activate([
                    searchBar.topAnchor.constraint(equalTo: view.topAnchor),
                    searchBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                    searchBar.trailingAnchor.constraint(equalTo: view.trailingAnchor)
                ])
            }
        
        
        func setupCollectionView() {

            let layout = UICollectionViewFlowLayout()
            layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
            collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)

            collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
            collectionView.dataSource = self
            collectionView.delegate = self
            collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
            collectionView.backgroundColor = .white
            collectionView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(collectionView)
            
            NSLayoutConstraint.activate([
                collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),
                collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ])
        }
        
        
    }
    
    
    func dateFormattedString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        return dateFormatter.string(from: date)
    }
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataRows.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)
        
        // 기존의 셀 하위 뷰들을 제거합니다.
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        
        let label = UILabel()
        label.text = dataRows[indexPath.item].BILL_NAME // 원하는 텍스트 값을 설정합니다.
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        cell.contentView.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: cell.contentView.topAnchor),
            label.leadingAnchor.constraint(equalTo: cell.contentView.leadingAnchor),
            label.trailingAnchor.constraint(equalTo: cell.contentView.trailingAnchor),
            label.bottomAnchor.constraint(equalTo: cell.contentView.bottomAnchor)
        ])
        
        

        // 경계선 그리기
        cell.contentView.layer.borderWidth = 1 // 테두리의 두께
        cell.contentView.layer.borderColor = UIColor.gray.cgColor // 테두리의 색상
        

        cell.contentView.layer.cornerRadius = 10 // 셀의 모서리를 둥글게 설정합니다.
        cell.contentView.clipsToBounds = true // 셀의 내용이 모서리를 넘어가지 않도록 설정합니다.

        
        return cell
    }



    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Set the size of each cell
        let padding: CGFloat = 20 // sectionInset에서 설정한 왼쪽, 오른쪽 여백
        let cellWidth = collectionView.bounds.width - padding * 2 // padding을 뺀 너비
        return CGSize(width: cellWidth, height: 50)
    }

    
    

    
    
}

