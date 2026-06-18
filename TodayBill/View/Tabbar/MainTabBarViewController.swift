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
    private var viewControllers: [UIViewController] = []
    private var currentViewController: UIViewController?
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
        customTabBar.backgroundColor = .white
        tabBarHeightConstraint = customTabBar.heightAnchor.constraint(equalToConstant: tabBarContentHeight)
        NSLayoutConstraint.activate([
            contentContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            contentContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            contentContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            contentContainerView.bottomAnchor.constraint(equalTo: customTabBar.topAnchor),
            
            customTabBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            customTabBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            customTabBar.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            tabBarHeightConstraint!
        ])
    }
    
    private func updateTabBarHeight() {
        tabBarHeightConstraint?.constant = tabBarContentHeight + view.safeAreaInsets.bottom
    }
    
    private func selectTab(at index: Int) {
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
    }
}

extension MainTabBarViewController: MainTabBarViewDelegate {
    func tabBarView(_ tabBarView: MainTabBarView, didSelectTabAt index: Int) {
        selectTab(at: index)
    }
}
