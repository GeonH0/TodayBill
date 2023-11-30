//
//  ViewControllerCollectionViewDataSource.swift
//  TodayBill
//
//  Created by 김건호 on 11/27/23.
//

import Foundation
import UIKit
extension ViewController: UICollectionViewDataSource {

func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return favoriteData.count
}
    
    

func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FavoriteCell", for: indexPath)
    
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
    
    cell.backgroundColor = .brown
    
    // 경계선 그리기
    cell.layer.borderWidth = 1  // 테두리의 두께
    cell.layer.borderColor = UIColor.gray.cgColor  // 테두리의 색상
    cell.layer.cornerRadius = 10  // 셀의 모서리를 둥글게 설정
    cell.clipsToBounds = true  // 셀의 내용이 모서리를 넘어가지 않도록 설정

    return cell
}
}

