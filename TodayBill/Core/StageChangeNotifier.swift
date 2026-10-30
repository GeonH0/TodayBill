//
//  StageChangeNotifier.swift
//  TodayBill
//

import Foundation
import UserNotifications

/// Cancellation can originate on the background-task expiration queue.
final class StageCheckCancellation {
    private let lock = NSLock()
    private var cancelled = false
    private var finished = false
    private var handlers: [() -> Void] = []

    var isCancelled: Bool {
        lock.lock()
        defer { lock.unlock() }
        return cancelled
    }

    func onCancel(_ handler: @escaping () -> Void) {
        lock.lock()
        if cancelled { lock.unlock(); handler(); return }
        if finished { lock.unlock(); return }
        handlers.append(handler)
        lock.unlock()
    }

    func cancel() {
        lock.lock()
        guard !finished, !cancelled else { lock.unlock(); return }
        cancelled = true
        let callbacks = handlers
        handlers.removeAll()
        lock.unlock()
        callbacks.forEach { $0() }
    }

    func finish() {
        lock.lock()
        finished = true
        handlers.removeAll()
        lock.unlock()
    }
}

protocol FavoriteRefreshing {
    func favoriteSnapshots() -> [BillSnapshot]
    func refreshFavoriteSnapshots(
        cancellation: StageCheckCancellation,
        completion: @escaping (Result<[BillSnapshot], Error>) -> Void
    )
}

/// A refresh failure can still carry changes fetched successfully for other bills.
struct FavoriteRefreshFailure: Error {
    let refreshedSnapshots: [BillSnapshot]
    let failedBillIDs: [String]
    let underlyingError: Error
}

protocol StageNotificationSending {
    func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void)
    func add(_ request: UNNotificationRequest, completion: @escaping (Error?) -> Void)
    func removePendingDigest()
}

struct SystemStageNotificationCenter: StageNotificationSending {
    let center: UNUserNotificationCenter

    init(center: UNUserNotificationCenter = .current()) { self.center = center }

    func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        center.getNotificationSettings { completion($0.authorizationStatus) }
    }

    func add(_ request: UNNotificationRequest, completion: @escaping (Error?) -> Void) {
        center.add(request, withCompletionHandler: completion)
    }

    func removePendingDigest() {
        center.removePendingNotificationRequests(withIdentifiers: [StageChangeNotifier.notificationRequestIdentifier])
    }
}

final class StageChangeNotifier {
    static let shared = StageChangeNotifier()
    static let notifiedStageKeysDefaultsKey = "StageChangeNotifier.notifiedStageKeys"
    static let notificationRequestIdentifier = "stageChangeDigest"
    static let lastSuccessfulRefreshKey = "StageChangeNotifier.lastSuccessfulRefresh"
    static let lastRefreshAttemptKey = "StageChangeNotifier.lastRefreshAttempt"
    static let lastErrorKey = "StageChangeNotifier.lastError"
    static let favoritesDidChange = Notification.Name("StageChangeNotifier.favoritesDidChange")
    static let refreshInterval: TimeInterval = 6 * 60 * 60
    static let retryInterval: TimeInterval = 15 * 60

    private let repository: FavoriteRefreshing
    private let defaults: UserDefaults
    private let center: StageNotificationSending
    private let now: () -> Date
    private var activeRun: Run?

    private final class Run {
        let cancellation = StageCheckCancellation()
        var completions: [(Result<Void, Error>) -> Void] = []
        var addStarted = false
    }

    init(
        repository: FavoriteRefreshing = BillRepository.shared,
        defaults: UserDefaults = .standard,
        center: StageNotificationSending = SystemStageNotificationCenter(),
        now: @escaping () -> Date = Date.init
    ) {
        self.repository = repository
        self.defaults = defaults
        self.center = center
        self.now = now
    }

    static func billsToNotify(from snapshots: [BillSnapshot], notifiedStageKeys: [String: String]) -> [BillSnapshot] {
        snapshots.filter { $0.hasUnseenStageChange && notifiedStageKeys[$0.billID] != $0.stageKey }
    }

    /// Main-queue ownership serializes concurrent foreground/background callers and history writes.
    @discardableResult
    func run(refresh: Bool = true, completion: @escaping (Result<Void, Error>) -> Void = { _ in }) -> StageCheckCancellation {
        dispatchPrecondition(condition: .onQueue(.main))
        if let activeRun {
            activeRun.completions.append(completion)
            return activeRun.cancellation
        }

        let run = Run()
        run.completions.append(completion)
        activeRun = run
        run.cancellation.onCancel { [weak self, weak run] in
            DispatchQueue.main.async {
                guard let self, let run, self.activeRun === run else { return }
                if run.addStarted { self.center.removePendingDigest() }
                self.finish(run, result: .failure(URLError(.cancelled)))
            }
        }

        if refresh {
            defaults.set(now(), forKey: Self.lastRefreshAttemptKey)
            repository.refreshFavoriteSnapshots(cancellation: run.cancellation) { [weak self] result in
                DispatchQueue.main.async {
                    guard let self, self.isActive(run) else { return }
                    switch result {
                    case .success(let snapshots):
                        self.defaults.set(self.now(), forKey: Self.lastSuccessfulRefreshKey)
                        self.deliver(snapshots, refreshError: nil, run: run)
                    case .failure(let error):
                        if let partial = error as? FavoriteRefreshFailure {
                            self.deliver(partial.refreshedSnapshots, refreshError: error, run: run)
                        } else {
                            self.finish(run, result: .failure(error))
                        }
                    }
                }
            }
        } else {
            deliver(repository.favoriteSnapshots(), refreshError: nil, run: run)
        }
        return run.cancellation
    }

    /// Always rechecks cached, unannounced changes, including after enabling permission in Settings.
    @discardableResult
    func runIfNeeded(completion: @escaping (Result<Void, Error>) -> Void = { _ in }) -> StageCheckCancellation {
        let date = now()
        let lastSuccess = defaults.object(forKey: Self.lastSuccessfulRefreshKey) as? Date
        let lastAttempt = defaults.object(forKey: Self.lastRefreshAttemptKey) as? Date
        let stale = lastSuccess.map { date.timeIntervalSince($0) >= Self.refreshInterval || $0 > date } ?? true
        let canRetry = lastAttempt.map { date.timeIntervalSince($0) >= Self.retryInterval || $0 > date } ?? true
        return run(refresh: stale && canRetry, completion: completion)
    }

    private func isActive(_ run: Run) -> Bool {
        activeRun === run && !run.cancellation.isCancelled
    }

    private func deliver(_ snapshots: [BillSnapshot], refreshError: Error?, run: Run) {
        guard isActive(run) else { return }
        let finalResult: Result<Void, Error> = refreshError.map { .failure($0) } ?? .success(())
        let keys = defaults.dictionary(forKey: Self.notifiedStageKeysDefaultsKey) as? [String: String] ?? [:]
        let candidates = Self.billsToNotify(from: snapshots, notifiedStageKeys: keys)
        guard !candidates.isEmpty else { finish(run, result: finalResult); return }

        center.authorizationStatus { [weak self] status in
            DispatchQueue.main.async {
                guard let self, self.isActive(run) else { return }
                guard status == .authorized || status == .provisional || status == .ephemeral else {
                    self.finish(run, result: finalResult)
                    return
                }
                // The user may have read/unfavorited a bill while the settings request was in flight.
                let current = self.repository.favoriteSnapshots()
                let toNotify = candidates.filter { candidate in
                    current.contains { $0.billID == candidate.billID && $0.stageKey == candidate.stageKey && $0.hasUnseenStageChange }
                }
                guard !toNotify.isEmpty else { self.finish(run, result: finalResult); return }
                run.addStarted = true
                self.center.add(UNNotificationRequest(
                    identifier: Self.notificationRequestIdentifier,
                    content: Self.makeContent(for: toNotify),
                    trigger: nil
                )) { [weak self] error in
                    DispatchQueue.main.async {
                        guard let self, self.isActive(run) else { return }
                        if let error {
                            self.finish(run, result: .failure(error))
                            return
                        }
                        // Scheduling has succeeded. Merge with current history, not the earlier copy.
                        var updatedKeys = self.defaults.dictionary(forKey: Self.notifiedStageKeysDefaultsKey) as? [String: String] ?? [:]
                        let current = self.repository.favoriteSnapshots()
                        for bill in toNotify where current.contains(where: {
                            $0.billID == bill.billID && $0.stageKey == bill.stageKey && $0.hasUnseenStageChange
                        }) {
                            updatedKeys[bill.billID] = bill.stageKey
                        }
                        self.defaults.set(updatedKeys, forKey: Self.notifiedStageKeysDefaultsKey)
                        self.finish(run, result: finalResult)
                    }
                }
            }
        }
    }

    private func finish(_ run: Run, result: Result<Void, Error>) {
        guard activeRun === run else { return }
        activeRun = nil
        run.cancellation.finish()
        if case .failure(let error) = result {
            let underlying = (error as? FavoriteRefreshFailure)?.underlyingError ?? error
            let nsError = underlying as NSError
            defaults.set("\(nsError.domain):\(nsError.code)", forKey: Self.lastErrorKey)
        } else {
            defaults.removeObject(forKey: Self.lastErrorKey)
        }
        run.completions.forEach { $0(result) }
    }

    static func clearNotified(billID: String, defaults: UserDefaults = .standard) {
        var stored = defaults.dictionary(forKey: notifiedStageKeysDefaultsKey) as? [String: String] ?? [:]
        stored.removeValue(forKey: billID)
        defaults.set(stored, forKey: notifiedStageKeysDefaultsKey)
    }

    private static func makeContent(for bills: [BillSnapshot]) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = "관심 법안 업데이트"
        content.sound = .default
        content.body = bills.count == 1
            ? "\(bills[0].title)의 진행 상태가 바뀌었어요"
            : "\(bills[0].title) 등 \(bills.count)개 법안의 진행 상태가 바뀌었어요"
        return content
    }
}
