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
        
        let calendarViewController = UINavigationController(rootViewController: CalenderViewController())
        let searchViewController = UINavigationController(rootViewController:SearchViewController())
        let starViewController = UINavigationController(rootViewController:StarBillViewController())
        
        
        // MainTabBarViewController 구성
        tabBarViewController.setViewControllers(
            [calendarViewController, searchViewController, starViewController],
            symbolNames: ["house", "magnifyingglass", "star"],
            titles: ["홈", "검색", "관심"]
        )
        
        // 네비게이션 컨트롤러 설정
        window?.rootViewController = tabBarViewController
        window?.makeKeyAndVisible()
    }
}
