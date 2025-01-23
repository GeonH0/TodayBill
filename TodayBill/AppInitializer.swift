//
//  AppInitializer.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import UIKit

class AppInitializer {
    static func setupRootViewController(for window: UIWindow?) {
        let tabBarViewController = MainTabBarViewController()
        
        // 각 뷰 컨트롤러 생성 및 이미지 설정
        let calendarViewController = CalenderViewController()
        let searchViewController = SearchViewController()
        let starViewController = StarViewController()
        
        let homeImage = UIImage(systemName: "house")!
        let searchImage = UIImage(systemName: "magnifyingglass")!
        let starImage = UIImage(systemName: "star")!
        
        // MainTabBarViewController 구성
        tabBarViewController.setViewControllers(
            [calendarViewController, searchViewController, starViewController],
            images: [homeImage, searchImage, starImage]
        )
        
        // 네비게이션 컨트롤러 설정
        let navigationController = UINavigationController(rootViewController: tabBarViewController)
        window?.rootViewController = navigationController
        window?.makeKeyAndVisible()
    }
}
