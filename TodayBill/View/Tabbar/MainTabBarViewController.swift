//
//  MainTabBarViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import UIKit

final class MainTabBarViewController: UIViewController {
    private let customTabBar = MainTabBarView()
    private var viewControllers: [UIViewController] = []
    private var currentViewController: UIViewController?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabBar()
    }
    
    func setViewControllers(_ controllers: [UIViewController], images: [UIImage]) {
        viewControllers = controllers
        customTabBar.configure(with: images)
        selectTab(at: 0)
    }
    
    private func setupTabBar() {
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        customTabBar.delegate = self
        view.addSubview(customTabBar)
        
        NSLayoutConstraint.activate([
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            customTabBar.heightAnchor.constraint(equalToConstant: 50)
        ])
    }
    
    private func selectTab(at index: Int) {
        guard index >= 0 && index < viewControllers.count else { return }
        
        let selectedViewController = viewControllers[index]
        
        if currentViewController == selectedViewController {
            return
        }
        
        let oldViewController = currentViewController
        currentViewController?.willMove(toParent: nil)
        
        addChild(selectedViewController)
        selectedViewController.view.frame = view.bounds.offsetBy(
            dx: index > (oldViewController.flatMap { viewControllers.firstIndex(of: $0) } ?? 0)
                ? view.bounds.width
                : -view.bounds.width,
            dy: 0
        )
        selectedViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(selectedViewController.view, belowSubview: customTabBar)

        UIView.animate(withDuration: 0.3, animations: {
            selectedViewController.view.frame = self.view.bounds
            oldViewController?.view.frame = oldViewController?.view.frame.offsetBy(
                dx: index > (oldViewController.flatMap { self.viewControllers.firstIndex(of: $0) } ?? 0)
                    ? -self.view.bounds.width
                    : self.view.bounds.width,
                dy: 0
            ) ?? CGRect.zero
        }) { _ in
            oldViewController?.view.removeFromSuperview()
            oldViewController?.removeFromParent()
            selectedViewController.didMove(toParent: self)
            self.currentViewController = selectedViewController
        }
    }
}

extension MainTabBarViewController: MainTabBarViewDelegate {
    func tabBarView(_ tabBarView: MainTabBarView, didSelectTabAt index: Int) {
        selectTab(at: index)
    }
}
