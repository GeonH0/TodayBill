//
//  MainTabBarView.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import Foundation

import UIKit

protocol MainTabBarViewDelegate: AnyObject {
    func tabBarView(_ tabBarView: MainTabBarView, didSelectTabAt index: Int)
}

final class MainTabBarView: UIView {
    
    weak var delegate: MainTabBarViewDelegate?
    
    private var buttons: [UIButton] = []
    private let indicatorView: UIView = {
        let indicatorView = UIView()
        indicatorView.backgroundColor = .systemBlue
        return indicatorView
    }()
    
    private let separatorView: UIView = {
        let separatorView = UIView()
        separatorView.backgroundColor = .lightGray
        return separatorView
    }()
    
    private var currentSelectedIndex: Int = 0
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addsubviews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func addsubviews(){
        addSubview(indicatorView)
        addSubview(separatorView)
    }
    
    func configure(with images: [UIImage]) {
        buttons.forEach { $0.removeFromSuperview() }
        buttons = []
        
        for (index, image) in images.enumerated() {
            let button = UIButton(type: .system)
            var config = UIButton.Configuration.plain()
            config.image = image.withRenderingMode(.alwaysTemplate)
            config.imagePadding = 0
            config.baseForegroundColor = .gray
            config.contentInsets = NSDirectionalEdgeInsets(top: -10, leading: 0, bottom: 0, trailing: 0)
            
            button.configuration = config
            button.tintColor = .gray
            button.tag = index
            button.addAction(
                UIAction { [weak self] _ in
                    guard let self = self else { return }
                    self.currentSelectedIndex = index
                    self.updateIndicatorPosition(animated: true)
                    self.delegate?.tabBarView(self, didSelectTabAt: index)
                },
                for: .touchUpInside
            )
            
            buttons.append(button)
            addSubview(button)
        }
        
        setNeedsLayout()
        layoutIfNeeded()
        updateIndicatorPosition(animated: false)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()

        // 구분선 위치 설정
        separatorView.frame = CGRect(x: 0, y: -5, width: bounds.width, height: 1)

        // 버튼 레이아웃 설정
        let buttonWidth = bounds.width / CGFloat(buttons.count)
        let buttonHeight = bounds.height
        for (index, button) in buttons.enumerated() {
            button.frame = CGRect(
                x: CGFloat(index) * buttonWidth,
                y: 0,
                width: buttonWidth,
                height: buttonHeight
            )
            button.imageView?.contentMode = .scaleAspectFit
        }

        // 슬라이딩 인디케이터 초기화
        updateIndicatorPosition(animated: false)
    }
    
    private func updateIndicatorPosition(animated: Bool) {
        guard !buttons.isEmpty else { return }
        
        let buttonWidth = bounds.width / CGFloat(buttons.count)
        let targetX = CGFloat(currentSelectedIndex) * buttonWidth
        let indicatorFrame = CGRect(
            x: targetX,
            y: -5,
            width: buttonWidth,
            height: 3
        )
        
        if animated {
            UIView.animate(withDuration: 0.3) {
                self.indicatorView.frame = indicatorFrame
            }
        } else {
            indicatorView.frame = indicatorFrame
        }
    }
}
