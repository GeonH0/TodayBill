//
//  AppInitializer.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import UIKit

class AppInitializer {
    static func setupRootViewController(for window: UIWindow?) {
        CoreDataManager.shared.migrateUserDefaultsFavorites(StarBillManager.shared.loadStarredBills())

        let tabBarViewController = MainTabBarViewController()
        
        let calendarViewController = UINavigationController(rootViewController: CalenderViewController())
        let searchViewController = UINavigationController(rootViewController:SearchViewController())
        let starViewController = UINavigationController(rootViewController:StarBillViewController())
        
        
        let homeImage = UIImage(systemName: "house")!
        let searchImage = UIImage(systemName: "magnifyingglass")!
        let starImage = UIImage(systemName: "star")!
        
        // MainTabBarViewController 구성
        tabBarViewController.setViewControllers(
            [calendarViewController, searchViewController, starViewController],
            images: [homeImage, searchImage, starImage],
            titles: ["홈", "검색", "추적"]
        )
        
        // 네비게이션 컨트롤러 설정
        window?.rootViewController = tabBarViewController
        window?.makeKeyAndVisible()
    }
}
