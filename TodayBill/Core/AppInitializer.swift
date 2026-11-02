//
//  AppInitializer.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import UIKit

/// Pure URL parsing is shared by warm and cold scene routing.
enum AppDeepLink: Equatable {
    case home
    case favorites
    case bill(id: String, age: Int)

    init?(url: URL) {
        guard url.scheme?.lowercased() == "todaybill", url.user == nil,
              url.password == nil, url.port == nil else { return nil }
        let segments = url.pathComponents.filter { $0 != "/" }
        switch url.host?.lowercased() {
        case "home" where segments.isEmpty: self = .home
        case "favorites" where segments.isEmpty: self = .favorites
        case "bill":
            let ages = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?.filter { $0.name == "age" } ?? []
            guard segments.count == 1, let id = segments.first, !id.isEmpty, !id.contains("/"),
                  ages.count == 1, let value = ages.first?.value, let age = Int(value), age > 0 else { return nil }
            self = .bill(id: id, age: age)
        default: return nil
        }
    }
}

class AppInitializer {
    /// 위젯 딥링크 라우팅용. 루트가 교체되면 함께 사라지도록 weak로 둔다.
    private static weak var tabBarViewController: MainTabBarViewController?
    private static weak var homeNavigationController: UINavigationController?
    private static weak var favoritesNavigationController: UINavigationController?

    static func setupRootViewController(for window: UIWindow?) {
        let tabBarViewController = MainTabBarViewController()

        let calendarViewController = UINavigationController(rootViewController: CalenderViewController())
        let searchViewController = UINavigationController(rootViewController: SearchViewController())
        let starViewController = UINavigationController(rootViewController: StarBillViewController())

        // MainTabBarViewController 구성
        tabBarViewController.setViewControllers(
            [calendarViewController, searchViewController, starViewController],
            symbolNames: ["house", "magnifyingglass", "star"],
            titles: ["홈", "검색", "관심"]
        )

        self.tabBarViewController = tabBarViewController
        self.homeNavigationController = calendarViewController
        self.favoritesNavigationController = starViewController

        // 네비게이션 컨트롤러 설정
        window?.tintColor = Theme.accent
        window?.rootViewController = tabBarViewController
        window?.makeKeyAndVisible()
    }

    /// 위젯 딥링크. 알 수 없는 URL은 무시한다.
    @discardableResult
    static func handle(url: URL) -> Bool {
        guard let route = AppDeepLink(url: url), let tabBarViewController else { return false }
        switch route {
        case .home:
            tabBarViewController.selectTab(at: 0)
            homeNavigationController?.popToRootViewController(animated: false)
        case .favorites:
            tabBarViewController.selectTab(at: 2)
            favoritesNavigationController?.popToRootViewController(animated: false)
        case .bill(let id, let age):
            guard let navigation = favoritesNavigationController, let root = navigation.viewControllers.first else { return false }
            tabBarViewController.selectTab(at: 2)
            // Atomic replacement also handles rapid consecutive widget taps.
            navigation.setViewControllers([root, DetailViewController(billID: id, age: age)], animated: false)
        }
        return true
    }
}
