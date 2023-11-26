//
//  ViewController.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//
import UIKit


class ViewController: UIViewController,BillModalViewControllerDelegate {
    
    var dataRows = [Row]()
    var favoriteData: [Row] = []  // 즐겨찾기된 데이터를 저장할 배열 추가
    var favoriteCollectionView: UICollectionView!
    
    
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
        fetchBill()
        applyConstraints()
        setCalendar()
        reloadDateView(date: Date())
        favoriteCollectionView.backgroundColor = .red
    }

    fileprivate func setCalendar() {
        dateView.delegate = self

        let dateSelection = UICalendarSelectionSingleDate(delegate: self)
        dateView.selectionBehavior = dateSelection
    }
    
    func applyConstraints() {
        view.addSubview(dateView)
        
        let dateViewConstraints = [
            dateView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            dateView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            dateView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            favoriteCollectionView.topAnchor.constraint(equalTo: dateView.bottomAnchor),
            favoriteCollectionView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor),
            favoriteCollectionView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor),
            favoriteCollectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
            
            
        ]
        NSLayoutConstraint.activate(dateViewConstraints)
    }
    
    func reloadDateView(date: Date?) {
        if let date = date {
            let calendar = Calendar.current
            let dateComponents = calendar.dateComponents([.day, .month, .year], from: date)
            selectedDate = dateComponents
            dateView.reloadDecorations(forDateComponents: [dateComponents], animated: true)
        }
    }
    
    func setupCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal  // 스크롤 방향을 수평으로 설정
        favoriteCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        favoriteCollectionView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "FavoriteCell")
        favoriteCollectionView.backgroundColor = .white
        favoriteCollectionView.delegate = self
        favoriteCollectionView.dataSource = self
        favoriteCollectionView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(favoriteCollectionView)
    }

}

extension ViewController: UICalendarViewDelegate, UICalendarSelectionSingleDateDelegate {
    
    func calendarView(_ calendarView: UICalendarView, decorationFor dateComponents: DateComponents) -> UICalendarView.Decoration? {
            guard let selectedDate = Calendar.current.date(from: dateComponents) else {
                return nil
            }

            let count = countOfBillsForSelectedDate(selectedDate: selectedDate)

            return nil
        }

    // 달력에서 날짜 선택했을 경우
    func dateSelection(_ selection: UICalendarSelectionSingleDate, didSelectDate dateComponents: DateComponents?) {
        selection.setSelected(dateComponents, animated: true)
        
        selectedDate = dateComponents
        reloadDateView(date: Calendar.current.date(from: dateComponents!))
        
        if let date = Calendar.current.date(from: dateComponents!) {
            let filteredData = filterDataForSelectedDate(selectedDate: date)
            let modalViewController = BillModalViewController(date: date, dataRows: filteredData, favoriteData: favoriteData)
            modalViewController.delegate = self  // delegate 설정
            if let sheet = modalViewController.sheetPresentationController {
                sheet.detents = [.medium(), .large()]
                sheet.prefersGrabberVisible = true
                sheet.preferredCornerRadius = 20
                sheet.prefersScrollingExpandsWhenScrolledToEdge = false
            }
            present(modalViewController, animated: true)
        }
    }

    
    func filterDataForSelectedDate(selectedDate: Date) -> [Row] {
        let formattedDate = dateFormattedString(from: selectedDate)

        let filteredData = dataRows.filter {
            return $0.PROPOSE_DT == formattedDate
        }

        return filteredData
    }
    
    func favoriteDataUpdated(_ favoriteData: [Row]) {
         // 즐겨찾기 데이터가 업데이트될 때마다 캘린더 아래의 컬렉션 뷰를 업데이트
        print("SUC")
         updateFavoriteCollectionView(favoriteData)
     }
    func updateFavoriteCollectionView(_ favoriteData: [Row]) {
        print("SUC!!!!")
        self.favoriteData = favoriteData  // 즐겨찾기 데이터를 업데이트
        favoriteCollectionView.reloadData()  // 컬렉션 뷰를 업데이트
    }
    
    


    
    func countOfBillsForSelectedDate(selectedDate: Date) -> Int {
        let formattedDate = dateFormattedString(from: selectedDate)

        let billsForSelectedDate = dataRows.filter {
            return $0.PROPOSE_DT == formattedDate
        }

        return billsForSelectedDate.count
    }


    
    func dateFormattedString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")

        return dateFormatter.string(from: date)
    }
}

extension ViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("Number of items: \(favoriteData.count)")
        return favoriteData.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCell", for: indexPath)
        print("Creating cell for item at \(indexPath)")
        
        // 기존의 셀 하위 뷰들을 제거합니다.
        for subview in cell.contentView.subviews {
            subview.removeFromSuperview()
        }
        
        let label = UILabel()
        label.text = favoriteData[indexPath.item].BILL_NAME  // 즐겨찾기된 데이터 배열에서 가져옴
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
        cell.contentView.layer.borderWidth = 1  // 테두리의 두께
        cell.contentView.layer.borderColor = UIColor.gray.cgColor  // 테두리의 색상
        cell.contentView.layer.cornerRadius = 10  // 셀의 모서리를 둥글게 설정
        cell.contentView.clipsToBounds = true  // 셀의 내용이 모서리를 넘어가지 않도록 설정

        return cell
    }

}

