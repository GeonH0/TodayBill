import UIKit

class AppInitializer {
    /// 위젯 딥링크 라우팅용. 루트가 교체되면 함께 사라지도록 weak로 둔다.
    private static weak var tabBarViewController: MainTabBarViewController?
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
        self.favoritesNavigationController = starViewController

        // 네비게이션 컨트롤러 설정
        window?.rootViewController = tabBarViewController
        window?.makeKeyAndVisible()
    }

    /// 위젯 딥링크. 알 수 없는 URL은 무시한다.
    @discardableResult
    static func handle(url: URL) -> Bool {
        guard url.scheme == "todaybill", let tabBarViewController else { return false }

        switch url.host {
        case "home":
            tabBarViewController.selectTab(at: 0)
            return true

        case "favorites":
            tabBarViewController.selectTab(at: 2)
            return true

        case "bill":
            let billID = url.lastPathComponent
            let age = URLComponents(url: url, resolvingAgainstBaseURL: false)?
                .queryItems?
                .first { $0.name == "age" }?
                .value
                .flatMap(Int.init)
            guard !billID.isEmpty, billID != "/", let age,
                  let navigationController = favoritesNavigationController else { return false }

            tabBarViewController.selectTab(at: 2)
            // 위젯을 연달아 탭하면 상세가 쌓인다.
            navigationController.popToRootViewController(animated: false)
            navigationController.pushViewController(
                DetailViewController(billID: billID, age: age), animated: true
            )
            return true

        default:
            return false
        }
    }
}
