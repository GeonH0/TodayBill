//
//  MainTabBarViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import UIKit

/// Owns tab selection and child navigation; layout lives in the container view.
final class MainTabBarViewController: UIViewController {
    private let containerView = MainTabBarContainerView()
    private(set) var viewControllers: [UIViewController] = []
    private(set) var selectedIndex = 0
    private(set) var selectedViewController: UIViewController?

    override func loadView() {
        view = containerView
        containerView.tabBar.delegate = self
    }

    func setViewControllers(_ controllers: [UIViewController], symbolNames: [String], titles: [String]) {
        viewControllers = controllers
        controllers.compactMap { $0 as? UINavigationController }.forEach { $0.delegate = self }
        containerView.tabBar.configure(symbolNames: symbolNames, titles: titles)
        selectTab(at: 0)
    }

    /// Shared by touch input, widget links, and stage-change notifications.
    func selectTab(at index: Int) {
        guard viewControllers.indices.contains(index) else { return }
        loadViewIfNeeded()
        containerView.tabBar.select(at: index)
        let next = viewControllers[index]
        selectedIndex = index
        guard selectedViewController !== next else { return }

        let previous = selectedViewController
        addChild(next)
        next.view.translatesAutoresizingMaskIntoConstraints = false
        containerView.contentView.addSubview(next.view)
        NSLayoutConstraint.activate([
            next.view.topAnchor.constraint(equalTo: containerView.contentView.topAnchor),
            next.view.leadingAnchor.constraint(equalTo: containerView.contentView.leadingAnchor),
            next.view.trailingAnchor.constraint(equalTo: containerView.contentView.trailingAnchor),
            next.view.bottomAnchor.constraint(equalTo: containerView.contentView.bottomAnchor)
        ])
        next.didMove(toParent: self)
        previous?.willMove(toParent: nil)
        previous?.view.removeFromSuperview()
        previous?.removeFromParent()
        selectedViewController = next
        updateTabBarVisibility(for: next, animated: false)
    }

    private func updateTabBarVisibility(for controller: UIViewController, animated: Bool) {
        let navigation = controller as? UINavigationController
        let top = navigation?.topViewController ?? controller
        let isRoot = navigation?.viewControllers.first === top
        containerView.setTabBarHidden(top.hidesBottomBarWhenPushed && !isRoot, animated: animated)
    }
}

extension MainTabBarViewController: MainTabBarViewDelegate {
    func tabBarView(_ tabBarView: MainTabBarView, didSelectTabAt index: Int) {
        selectTab(at: index)
    }
}

extension MainTabBarViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        guard navigationController === selectedViewController else { return }
        updateTabBarVisibility(for: navigationController, animated: animated)
    }
}
