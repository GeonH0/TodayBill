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

class BillModalViewController: UIViewController, UISearchBarDelegate, UICollectionViewDataSource,UICollectionViewDelegate,UICollectionViewDelegateFlowLayout {
    
    weak var delegate: BillModalViewControllerDelegate?
    
    private var date: Date
    var dataRows = [Row]()
    var filteredDataRows = [Row]()
    var favoriteData = [Row]()

    var searchBar = UISearchBar()
    var collectionView: UICollectionView!
    var noDataLabel: UILabel!
    

    init(date: Date, dataRows: [Row], favoriteData : [Row]) {
        self.date = date
        self.dataRows = dataRows
        self.favoriteData = favoriteData
        self.filteredDataRows = dataRows  // 초기에는 전체 데이터를 보여줄 것이므로 초기화
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        
        super.viewDidLoad()
        setupSearchBar()
        setupCollectionView()
        setupNoDataLabel()
        // date를 한국 표준시(KST) 형식으로 포맷팅하여 표시
        let formattedDate = dateFormattedString(from: date)
        
    }
    
    func setupNoDataLabel() {
        noDataLabel = UILabel()
        noDataLabel.text = "정보가 없습니다"
        noDataLabel.textColor = .white
        noDataLabel.textAlignment = .center
        noDataLabel.isHidden = true  // 초기에는 숨김 상태로 설정
        noDataLabel.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(noDataLabel)

        NSLayoutConstraint.activate([
            noDataLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            noDataLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

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
        
        
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "cell")
        collectionView.backgroundColor = .white
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        
        
        view.addSubview(collectionView)

        NSLayoutConstraint.activate([
            collectionView.topAnchor.constraint(equalTo: searchBar.bottomAnchor),  // 간격을 추가
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        collectionView.addGestureRecognizer(longPressGesture)
    }
    
    // 나머지 함수 및 dateFormattedString 등은 동일하게 유지

    func dateFormattedString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        return dateFormatter.string(from: date)
    }
    


    
    

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let count = filteredDataRows.count
                noDataLabel.isHidden = count != 0  // 데이터가 있을 경우 라벨 숨김
                return count
    }
    

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "cell", for: indexPath)

        // 기존의 셀 하위 뷰들을 제거합니다.
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        
        let label = UILabel()
        label.text = filteredDataRows[indexPath.item].BILL_NAME  // 필터링된 데이터 배열에서 가져옴
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
           cell.layer.borderWidth = 1  // 테두리의 두께
           cell.layer.borderColor = UIColor.gray.cgColor  // 테두리의 색상
           cell.layer.cornerRadius = 10  // 셀의 모서리를 둥글게 설정
           cell.clipsToBounds = true  // 셀의 내용이 모서리를 넘어가지 않도록 설정
        
        return cell
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: collectionView)
            if let indexPath = collectionView.indexPathForItem(at: point) {
                toggleFavoriteStatus(at: indexPath)
            }
        }
    }
    
    
    // MARK: - UICollectionViewDelegateFlowLayout

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Set the size of each cell
        let padding: CGFloat = 10  // sectionInset에서 설정한 왼쪽, 오른쪽 여백
        let cellWidth = collectionView.bounds.width - padding * 2  // padding을 뺀 너비
        return CGSize(width: cellWidth, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedRow = filteredDataRows[indexPath.item]  // 필터링된 데이터 배열에서 가져옴
        let detailVC = DetailView(row: selectedRow)  // DetailViewController를 초기화할 때 init(row:) 사용
        detailVC.modalPresentationStyle = .fullScreen
        self.present(detailVC, animated: true, completion: nil)
    }


    // MARK: - UISearchBarDelegate

    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        // 검색어에 따라 데이터를 필터링
        filteredDataRows = searchText.isEmpty ? dataRows : dataRows.filter { $0.BILL_NAME.localizedCaseInsensitiveContains(searchText) }
        collectionView.reloadData()
    }
    
    func saveFavoriteData() {
        do {
            let encodedData = try JSONEncoder().encode(favoriteData)
            UserDefaults.standard.set(encodedData, forKey: "favoriteData")
        } catch {
            print("Error encoding favoriteData: \(error)")
        }
    }

    



    
    
    func toggleFavoriteStatus(at indexPath: IndexPath) {
        let selectedRow = filteredDataRows[indexPath.item]

        // 이미 favoriteData에 있는 데이터인지 확인
        if favoriteData.contains(where: { $0.BILL_ID == selectedRow.BILL_ID }) {
            // 이미 존재하면 제거
            if let index = favoriteData.firstIndex(where: { $0.BILL_ID == selectedRow.BILL_ID }) {
                favoriteData.remove(at: index)
            }
        } else {
            // 존재하지 않으면 추가
            favoriteData.append(selectedRow)
        }

        // 나머지 코드는 그대로 유지

        // 필터링된 데이터의 즐겨찾기 상태 업데이트
        filteredDataRows[indexPath.item].favoriteInfo.isFavorite.toggle()
        
        
        saveFavoriteData()
        delegate?.favoriteDataUpdated(favoriteData)

        collectionView.reloadItems(at: [indexPath])
    }




           
}



