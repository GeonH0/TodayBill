//
//  AppDelegate.swift
//  TodayBill
//
//  Created by 김건호 on 11/21/23.
//

import UIKit
import BackgroundTasks
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    static let stageCheckTaskIdentifier = "Test.TodayBill.stagecheck"

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.stageCheckTaskIdentifier, using: nil) { task in
            self.handleStageCheck(task: task as! BGAppRefreshTask)
        }
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        saveFavoriteData()
        scheduleStageCheckIfNeeded()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        saveFavoriteData()
    }

    private func saveFavoriteData() {
        let starredBills = StarBillManager.shared.loadStarredBills()
        StarBillManager.shared.saveStarredBills(starredBills)
    }

    private func scheduleStageCheckIfNeeded() {
        guard !CoreDataManager.shared.fetchFavoriteSnapshots().isEmpty else { return }

        let request = BGAppRefreshTaskRequest(identifier: Self.stageCheckTaskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 6 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }

    private func handleStageCheck(task: BGAppRefreshTask) {
        scheduleStageCheckIfNeeded()

        let lock = NSLock()
        var isFinished = false
        func finish(success: Bool) {
            lock.lock()
            defer { lock.unlock() }
            guard !isFinished else { return }
            isFinished = true
            task.setTaskCompleted(success: success)
        }

        task.expirationHandler = {
            finish(success: false)
        }

        StageChangeNotifier.run {
            finish(success: true)
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

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
