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
        
        let calendarViewController = CalenderViewController()
        let searchViewController = SearchViewController()
        let savedStarBills = StarBillManager.shared.loadStarredBills()
        let starViewController = StarBillViewController(starBills: savedStarBills)
        
        
        let homeImage = UIImage(systemName: "house")!
        let searchImage = UIImage(systemName: "magnifyingglass")!
        let starImage = UIImage(systemName: "star")!
        
        // MainTabBarViewController 구성
        tabBarViewController.setViewControllers(
            [calendarViewController, searchViewController, starViewController],
            images: [homeImage, searchImage, starImage]
        )
        
        // 네비게이션 컨트롤러 설정
        window?.rootViewController = tabBarViewController
        window?.makeKeyAndVisible()
    }
}
