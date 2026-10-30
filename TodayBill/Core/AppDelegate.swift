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
    private lazy var stageScheduler = StageCheckScheduler()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        CoreDataManager.shared.migrateUserDefaultsFavorites(StarBillManager.shared.loadStarredBills())
        BGTaskScheduler.shared.register(forTaskWithIdentifier: Self.stageCheckTaskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            self.handleStageCheck(task: refreshTask)
        }
        UNUserNotificationCenter.current().delegate = self

        // Scene-based apps never receive `applicationDidEnterBackground(_:)`, but UIKit
        // still posts `didEnterBackgroundNotification`, so schedule from there instead.
        NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.scheduleStageCheckIfNeeded()
        }

        NotificationCenter.default.addObserver(
            forName: StageChangeNotifier.favoritesDidChange, object: nil, queue: .main
        ) { [weak self] _ in
            self?.scheduleStageCheckIfNeeded()
        }
        scheduleStageCheckIfNeeded()
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
        stageScheduler.scheduleIfNeeded()
    }

    func sceneBecameActive() {
        scheduleStageCheckIfNeeded()
        guard !CoreDataManager.shared.fetchFavoriteSnapshots().isEmpty else { return }
        requestNotificationPermissionIfNeeded()
        StageChangeNotifier.shared.runIfNeeded()
    }

    private func requestNotificationPermissionIfNeeded() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else { return }
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in
                DispatchQueue.main.async {
                    guard UIApplication.shared.applicationState == .active else { return }
                    StageChangeNotifier.shared.runIfNeeded()
                }
            }
        }
    }

    private func handleStageCheck(task: BGAppRefreshTask) {
        let lifetime = StageCheckCancellation()
        let lock = NSLock()
        var finished = false
        func finish(success: Bool) {
            lock.lock()
            guard !finished else { lock.unlock(); return }
            finished = true
            lock.unlock()
            lifetime.finish()
            task.expirationHandler = nil
            task.setTaskCompleted(success: success)
        }
        task.expirationHandler = {
            lifetime.cancel()
            finish(success: false)
        }
        DispatchQueue.main.async {
            guard !lifetime.isCancelled else {
                self.stageScheduler.scheduleIfNeeded(delay: StageChangeNotifier.retryInterval)
                return
            }
            // Secure the successor while the task is alive, including if the refresh later expires.
            self.stageScheduler.scheduleIfNeeded()
            let work = StageChangeNotifier.shared.run { result in
                let success: Bool
                switch result {
                case .success: success = true
                case .failure: success = false
                }
                self.stageScheduler.scheduleIfNeeded(delay: success
                    ? StageChangeNotifier.refreshInterval : StageChangeNotifier.retryInterval) {
                    finish(success: success)
                }
            }
            lifetime.onCancel { work.cancel() }
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

protocol StageCheckScheduling {
    func pendingRequests(completion: @escaping ([BGTaskRequest]) -> Void)
    func submit(_ request: BGTaskRequest) throws
    func cancel(identifier: String)
}

struct SystemStageCheckScheduler: StageCheckScheduling {
    func pendingRequests(completion: @escaping ([BGTaskRequest]) -> Void) {
        BGTaskScheduler.shared.getPendingTaskRequests(completionHandler: completion)
    }
    func submit(_ request: BGTaskRequest) throws { try BGTaskScheduler.shared.submit(request) }
    func cancel(identifier: String) { BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: identifier) }
}

/// Serializes the asynchronous pending-request check and never postpones an existing request.
final class StageCheckScheduler {
    static let lastErrorKey = "StageCheckScheduler.lastError"
    private let scheduler: StageCheckScheduling
    private let hasFavorites: () -> Bool
    private let defaults: UserDefaults
    private let now: () -> Date
    private var checking = false
    private var requestedDelay = StageChangeNotifier.refreshInterval
    private var completions: [() -> Void] = []

    init(
        scheduler: StageCheckScheduling = SystemStageCheckScheduler(),
        hasFavorites: @escaping () -> Bool = { !CoreDataManager.shared.fetchFavoriteSnapshots().isEmpty },
        defaults: UserDefaults = .standard,
        now: @escaping () -> Date = Date.init
    ) {
        self.scheduler = scheduler
        self.hasFavorites = hasFavorites
        self.defaults = defaults
        self.now = now
    }

    func scheduleIfNeeded(delay: TimeInterval = StageChangeNotifier.refreshInterval, completion: @escaping () -> Void = {}) {
        dispatchPrecondition(condition: .onQueue(.main))
        completions.append(completion)
        if checking {
            requestedDelay = min(requestedDelay, delay)
            return
        }
        checking = true
        requestedDelay = delay
        guard hasFavorites() else {
            scheduler.cancel(identifier: AppDelegate.stageCheckTaskIdentifier)
            finishCheck()
            return
        }
        scheduler.pendingRequests { [weak self] requests in
            DispatchQueue.main.async {
                guard let self else { return }
                defer { self.finishCheck() }
                guard self.hasFavorites() else {
                    self.scheduler.cancel(identifier: AppDelegate.stageCheckTaskIdentifier)
                    return
                }
                let earliestDate = self.now().addingTimeInterval(self.requestedDelay)
                if let existing = requests.first(where: { $0.identifier == AppDelegate.stageCheckTaskIdentifier }),
                   existing.earliestBeginDate.map({ $0 <= earliestDate }) ?? true {
                    return
                }
                let request = BGAppRefreshTaskRequest(identifier: AppDelegate.stageCheckTaskIdentifier)
                request.earliestBeginDate = earliestDate
                do {
                    try self.scheduler.submit(request)
                    self.defaults.removeObject(forKey: Self.lastErrorKey)
                } catch {
                    let nsError = error as NSError
                    self.defaults.set("\(nsError.domain):\(nsError.code)", forKey: Self.lastErrorKey)
                    NSLog("Stage check scheduling failed (%@:%ld)", nsError.domain, nsError.code)
                }
            }
        }
    }

    private func finishCheck() {
        checking = false
        let callbacks = completions
        completions.removeAll()
        callbacks.forEach { $0() }
    }
}
