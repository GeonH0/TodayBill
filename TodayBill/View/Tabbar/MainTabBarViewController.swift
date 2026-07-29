//
//  MainTabBarViewController.swift
//  TodayBill
//
//  Created by 김건호 on 1/23/25.
//

import UIKit

final class MainTabBarViewController: UIViewController {
    private let contentContainerView = UIView()
    private let customTabBar = MainTabBarView()
    private var tabBarHeightConstraint: NSLayoutConstraint?
    private var contentBottomToTabBarConstraint: NSLayoutConstraint?
    private var contentBottomToViewConstraint: NSLayoutConstraint?
    private var viewControllers: [UIViewController] = []
    private var currentViewController: UIViewController?
    private var isCustomTabBarHidden = false
    private let tabBarContentHeight: CGFloat = 50
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupContentContainerView()
        setupTabBar()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateTabBarHeight()
    }
    
    func setViewControllers(_ controllers: [UIViewController], images: [UIImage], titles: [String]) {
        viewControllers = controllers
        controllers.compactMap { $0 as? UINavigationController }.forEach { $0.delegate = self }
        customTabBar.configure(with: images, titles: titles)
        selectTab(at: 0)
    }
    
    private func setupContentContainerView() {
        view.backgroundColor = Theme.backgroundColor
        contentContainerView.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.backgroundColor = Theme.backgroundColor
        contentContainerView.clipsToBounds = true
        view.addSubview(contentContainerView)
    }
    
    private func setupTabBar() {
        customTabBar.translatesAutoresizingMaskIntoConstraints = false
        customTabBar.delegate = self
        view.addSubview(customTabBar)
        customTabBar.backgroundColor = Theme.cellBackgroundColor
        tabBarHeightConstraint = customTabBar.heightAnchor.constraint(equalToConstant: tabBarContentHeight)
        contentBottomToTabBarConstraint = contentContainerView.bottomAnchor.constraint(equalTo: customTabBar.topAnchor)
        contentBottomToViewConstraint = contentContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentBottomToTabBarConstraint!,
            
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBarHeightConstraint!
        ])
        contentBottomToViewConstraint?.isActive = false
    }
    
    private func updateTabBarHeight() {
        tabBarHeightConstraint?.constant = tabBarContentHeight + view.safeAreaInsets.bottom
    }
    
    func selectTab(at index: Int) {
        guard index >= 0 && index < viewControllers.count else { return }
        
        let selectedViewController = viewControllers[index]
        
        if currentViewController == selectedViewController {
            return
        }
        
        let oldViewController = currentViewController
        addChild(selectedViewController)
        selectedViewController.view.translatesAutoresizingMaskIntoConstraints = false
        contentContainerView.addSubview(selectedViewController.view)
        NSLayoutConstraint.activate([
            selectedViewController.view.topAnchor.constraint(equalTo: contentContainerView.topAnchor),
            selectedViewController.view.leadingAnchor.constraint(equalTo: contentContainerView.leadingAnchor),
            selectedViewController.view.trailingAnchor.constraint(equalTo: contentContainerView.trailingAnchor),
            selectedViewController.view.bottomAnchor.constraint(equalTo: contentContainerView.bottomAnchor)
        ])
        selectedViewController.didMove(toParent: self)
        
        oldViewController?.willMove(toParent: nil)
        oldViewController?.view.removeFromSuperview()
        oldViewController?.removeFromParent()
        
        currentViewController = selectedViewController
        updateCustomTabBarVisibility(for: selectedViewController, animated: false)
    }

    private func updateCustomTabBarVisibility(for viewController: UIViewController, animated: Bool) {
        let navigationController = viewController as? UINavigationController
        let topViewController = navigationController?.topViewController ?? viewController
        let isRoot = navigationController?.viewControllers.first === topViewController
        let shouldHide = topViewController.hidesBottomBarWhenPushed && !isRoot
        setCustomTabBarHidden(shouldHide, animated: animated)
    }

    private func setCustomTabBarHidden(_ hidden: Bool, animated: Bool) {
        guard hidden != isCustomTabBarHidden else { return }
        isCustomTabBarHidden = hidden

        contentBottomToTabBarConstraint?.isActive = !hidden
        contentBottomToViewConstraint?.isActive = hidden

        if !hidden {
            customTabBar.isHidden = false
        }

        let changes = {
            self.customTabBar.alpha = hidden ? 0 : 1
            self.view.layoutIfNeeded()
        }

        let completion: (Bool) -> Void = { _ in
            self.customTabBar.isHidden = hidden
        }

        if animated {
            UIView.animate(withDuration: 0.22, delay: 0, options: [.curveEaseInOut], animations: changes, completion: completion)
        } else {
            changes()
            completion(true)
        }
    }
}

extension MainTabBarViewController: MainTabBarViewDelegate {
    func tabBarView(_ tabBarView: MainTabBarView, didSelectTabAt index: Int) {
        selectTab(at: index)
    }
}

extension MainTabBarViewController: UINavigationControllerDelegate {
    func navigationController(
        _ navigationController: UINavigationController,
        willShow viewController: UIViewController,
        animated: Bool
    ) {
        updateCustomTabBarVisibility(for: navigationController, animated: animated)
    }
}
