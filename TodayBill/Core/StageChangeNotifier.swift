//
//  StageChangeNotifier.swift
//  TodayBill
//

import Foundation
import UserNotifications

enum StageChangeNotifier {
    static let notifiedStageKeysDefaultsKey = "StageChangeNotifier.notifiedStageKeys"
    static let notificationRequestIdentifier = "stageChangeDigest"

    /// Favorited bills whose stage changed since the last time this exact
    /// change was announced. Pure function — no CoreData/UserDefaults/UNUserNotificationCenter access.
    static func billsToNotify(from snapshots: [BillSnapshot], notifiedStageKeys: [String: String]) -> [BillSnapshot] {
        snapshots.filter { $0.hasUnseenStageChange && notifiedStageKeys[$0.billID] != $0.stageKey }
    }

    /// Refreshes favorited bills, posts a digest notification if anything changed, and
    /// records what was announced so the same change isn't re-sent next time.
    static func run(
        repository: BillRepositoryProtocol = BillRepository.shared,
        defaults: UserDefaults = .standard,
        center: UNUserNotificationCenter = .current(),
        completion: @escaping () -> Void = {}
    ) {
        repository.refreshFavoriteSnapshots { result in
            guard case .success(let snapshots) = result, !snapshots.isEmpty else {
                completion()
                return
            }

            let notifiedKeys = defaults.dictionary(forKey: notifiedStageKeysDefaultsKey) as? [String: String] ?? [:]
            let toNotify = billsToNotify(from: snapshots, notifiedStageKeys: notifiedKeys)
            guard !toNotify.isEmpty else {
                completion()
                return
            }

            // Only mark a change as announced if it can actually be delivered — otherwise an
            // unauthorized user would silently lose the change even after enabling notifications.
            center.getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized else {
                    completion()
                    return
                }

                center.add(UNNotificationRequest(
                    identifier: notificationRequestIdentifier,
                    content: makeContent(for: toNotify),
                    trigger: nil
                ))

                var updatedKeys = notifiedKeys
                toNotify.forEach { updatedKeys[$0.billID] = $0.stageKey }
                defaults.set(updatedKeys, forKey: notifiedStageKeysDefaultsKey)

                completion()
            }
        }
    }

    /// Call when a bill is un-favorited so a stale "already notified" entry
    /// doesn't linger if the same bill is favorited again later.
    static func clearNotified(billID: String, defaults: UserDefaults = .standard) {
        var stored = defaults.dictionary(forKey: notifiedStageKeysDefaultsKey) as? [String: String] ?? [:]
        stored.removeValue(forKey: billID)
        defaults.set(stored, forKey: notifiedStageKeysDefaultsKey)
    }

    private static func makeContent(for bills: [BillSnapshot]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "관심 법안 업데이트"
        content.sound = .default
        if bills.count == 1 {
            content.body = "\(bills[0].title)의 진행 상태가 바뀌었어요"
        } else {
            content.body = "\(bills[0].title) 등 \(bills.count)개 법안의 진행 상태가 바뀌었어요"
        }
        return content
    }
}
