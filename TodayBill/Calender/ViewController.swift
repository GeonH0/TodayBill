//
//  ViewController.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//
import UIKit

class ViewController: UIViewController, BillModalViewControllerDelegate, UICollectionViewDelegateFlowLayout {
    
    var dataRows = [Row]()
    var favoriteData = [Row]()
    var favoriteCollectionView: UICollectionView!
    var currentPIndex: Int = 1
    
    lazy var dateView: UICalendarView = {
        var view = UICalendarView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.wantsDateDecorations = true
        return view
    }()
    
    var selectedDate: DateComponents? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        fetchBill(pIndex: currentPIndex)
        applyConstraints()
        setCalendar()
        reloadDateView(date: Date())
        loadFavoriteData()
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        favoriteCollectionView.addGestureRecognizer(longPressGesture)
        
    }
    
    fileprivate func setCalendar() {
        dateView.delegate = self
        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        dateView.selectionBehavior = dateSelection
        
        
        
    }
    private func loadFavoriteData() {
        if let savedData = UserDefaults.standard.data(forKey: "favoriteData") {
            print("Saved Data:", savedData)
            do {
                favoriteData = try JSONDecoder().decode([Row].self, from: savedData)
                print("LOAD")
            } catch {
                print("Failed to decode favoriteData from UserDefaults: \(error)")
            }
        }
    }
    
    private func applyConstraints() {
        view.addSubview(dateView)
        
        // 새로운 라벨 생성
        let label = UILabel()
        label.text = "꾹 누르면 즐겨찾기가 됩니다!" // 라벨 텍스트 설정
        label.translatesAutoresizingMaskIntoConstraints = false // Auto Layout 사용 설정
        view.addSubview(label) // 라벨을 화면에 추가
        
        // favoriteCollectionView도 화면에 추가
        view.addSubview(favoriteCollectionView)
        
        let gap: CGFloat = 20 // 원하는 간격 값
        let leadingSpace: CGFloat = 10 // 왼쪽 여백 값
        
        let constraints = [
            
            dateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            dateView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            dateView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            
            label.topAnchor.constraint(equalTo: dateView.bottomAnchor),
            label.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: leadingSpace), // 왼쪽 여백 추가
            label.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            
            
            favoriteCollectionView.topAnchor.constraint(equalTo: label.bottomAnchor, constant: gap), // 간격 추가
            favoriteCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            favoriteCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            favoriteCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ]
        NSLayoutConstraint.activate(constraints)
    }
    
    func reloadDateView(date: Date?) {
        if let date = date {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
            selectedDate = dateComponents
            dateView.reloadDecorations(forDateComponents: [dateComponents], animated: true)
        }
    }
    
    private func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical  // 스크롤 방향을 수직으로 설정
        layout.sectionInset = UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        favoriteCollectionView = UICollectionView(frame: view.bounds, collectionViewLayout: layout)
        favoriteCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "FavoriteCell")
        favoriteCollectionView.backgroundColor = .white
        favoriteCollectionView.delegate = self
        favoriteCollectionView.dataSource = self
        favoriteCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(favoriteCollectionView)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 10  // sectionInset에서 설정한 왼쪽, 오른쪽 여백
        let cellWidth = collectionView.bounds.width - padding * 2 - collectionView.contentInset.left - collectionView.contentInset.right
        return CGSize(width: cellWidth, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let selectedRow = favoriteData[indexPath.item]  // 필터링된 데이터 배열에서 가져옴
        let detailVC = DetailView(row: selectedRow)
        detailVC.modalPresentationStyle = .fullScreen
        self.present(detailVC, animated: true, completion: nil)
    }
    
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        if gesture.state == .began {
            let point = gesture.location(in: favoriteCollectionView)
            if let indexPath = favoriteCollectionView.indexPathForItem(at: point) {
                removeCell(at: indexPath)
            }
        }
    }
    private func saveFavoriteData() {
        do {
            let encodedData = try JSONEncoder().encode(favoriteData)
            UserDefaults.standard.set(encodedData, forKey: "favoriteData")
        } catch {
            print("Error encoding favoriteData: \(error)")
        }
    }
    
    // 셀 제거 로직
    private func removeCell(at indexPath: IndexPath) {
        // 선택된 인덱스에 해당하는 데이터 및 셀을 삭제
        favoriteData.remove(at: indexPath.item)
        favoriteCollectionView.deleteItems(at: [indexPath])
        
        // 저장된 데이터 업데이트
        saveFavoriteData()
    }
}
