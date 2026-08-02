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

        // Scene-based apps never receive `applicationDidEnterBackground(_:)`, but UIKit
        // still posts `didEnterBackgroundNotification`, so schedule from there instead.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: nil
        ) { [weak self] _ in
            self?.scheduleStageCheckIfNeeded()
        }

        scheduleStageCheckIfNeeded()
        requestNotificationPermissionIfNeeded()
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

    /// Covers users who already had favorites before this feature shipped — the
    /// first-favorite prompt in `BillsRepository.toggleFavorite` only fires on a 0→1 transition.
    private func requestNotificationPermissionIfNeeded() {
        guard !CoreDataManager.shared.fetchFavoriteSnapshots().isEmpty else { return }

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        }
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

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        if response.notification.request.identifier == StageChangeNotifier.notificationRequestIdentifier {
            selectStarTab()
        }
        completionHandler()
    }

    private func selectStarTab() {
        // Tapping a digest is a cold-launch/resume path, so the scene may still be
        // `.foregroundInactive` here — look the tab bar up without depending on activation state.
        let tabBarController = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .compactMap { $0.rootViewController as? MainTabBarViewController }
            .first
        tabBarController?.selectTab(at: 2) // 추적 tab — see AppInitializer.swift:26-30
    }
}
