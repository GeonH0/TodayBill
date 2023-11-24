//
//  DetailView.swift
//  TodayBill
//
//  Created by 김건호 on 11/24/23.
//

import Foundation
import UIKit

class DetailView : UIViewController {
    
    var row: Row // 사용자가 선택한 셀의 정보
    
    init(row: Row) {
        self.row = row
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        let navBar = UINavigationBar(frame: CGRect(x: 0, y: UIApplication.shared.statusBarFrame.height , width: view.frame.size.width, height: 44))
        navBar.barTintColor = .white
        navBar.shadowImage = UIImage()  // 네비게이션 바의 그림자 제거


        
        view.addSubview(navBar)
        
        
        let backButton = UIBarButtonItem(title: "Back", style: .plain, target: self, action: #selector(backButtonTapped))
        let navItem = UINavigationItem()
        navItem.leftBarButtonItem = backButton
        navBar.setItems([navItem], animated: false)
        
        
        let label = UILabel()
        label.text = row.BILL_NAME // 셀의 정보를 표시합니다.
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(label)
        
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
        ])
    }
    
    
    @objc func backButtonTapped() {
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
    
    
}
