//
//  ListView.swift
//  TodayBill
//
//  Created by 김건호 on 1/25/25.
//

import Foundation

import UIKit

final class ListView: UICollectionView {
    
    init(cellType: UICollectionViewCell.Type, layout: UICollectionViewFlowLayout) {
        super.init(frame: .zero, collectionViewLayout: layout)                
        self.register(cellType, forCellWithReuseIdentifier: String(describing: cellType))
        self.translatesAutoresizingMaskIntoConstraints = false
        self.backgroundColor = Theme.backgroundColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
