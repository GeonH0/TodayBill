//
//  Modal.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//

import UIKit

class BillModalViewController: UIViewController,UISearchBarDelegate  {
    
    
    var date: Date
    var dataRows = [Row]()
    var filteredData: [Bills] = []
    
    var searchBar = UISearchBar()
    var tableView = UITableView()

    
    
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
        
        let label = UILabel()
        label.text = "선택한 날짜: \(formattedDate)"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        


        
        





        
    }
    
    func dateFormattedString(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.locale = Locale(identifier: "ko_KR")
        dateFormatter.timeZone = TimeZone(identifier: "Asia/Seoul")
        
        return dateFormatter.string(from: date)
    }
    

    
    
}

