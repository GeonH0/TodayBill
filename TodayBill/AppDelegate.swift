//
//  AppDelegate.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        
        if let savedFavoriteData = UserDefaults.standard.data(forKey: "favoriteData"),
                   let decodedFavoriteData = try? JSONDecoder().decode([Row].self, from: savedFavoriteData) {
                    // 불러온 데이터를 앱 전체에서 사용할 수 있도록 설정합니다.
                    if let viewController = window?.rootViewController as? ViewController {
                        viewController.favoriteData = decodedFavoriteData
                    }
                }
        
        return true
    }
    func applicationWillTerminate(_ application: UIApplication) {
        // 앱이 종료될 때 UserDefaults에 favoriteData를 저장합니다.
        if let viewController = window?.rootViewController as? ViewController {
            if let encodedData = try? JSONEncoder().encode(viewController.favoriteData) {
                UserDefaults.standard.set(encodedData, forKey: "favoriteData")
            }
        }
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }


}

