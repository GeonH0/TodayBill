import XCTest
import UserNotifications
import BackgroundTasks
@testable import TodayBill

final class StageChangeNotifierTests: XCTestCase {
    func testBillsToNotifyIncludesOnlyUnnotifiedUnseenChanges() {
        let changed = makeSnapshot(id: "A1", committeeDate: "2025-02-01", lastSeenStageKey: "committee|2025-01-01")
        let unchanged = makeSnapshot(id: "A2", committeeDate: "2025-01-01", lastSeenStageKey: "committee|2025-01-01")
        let alreadyNotified = makeSnapshot(id: "A3", committeeDate: "2025-03-01", lastSeenStageKey: "committee|2025-01-01")

        let result = StageChangeNotifier.billsToNotify(
            from: [changed, unchanged, alreadyNotified],
            notifiedStageKeys: ["A3": alreadyNotified.stageKey]
        )

        XCTAssertEqual(result.map(\.billID), ["A1"])
    }

    func testBillsToNotifyIgnoresNonFavorites() {
        let nonFavorite = makeSnapshot(id: "B1", committeeDate: "2025-02-01", lastSeenStageKey: "committee|2025-01-01", isFavorite: false)

        let result = StageChangeNotifier.billsToNotify(from: [nonFavorite], notifiedStageKeys: [:])

        XCTAssertTrue(result.isEmpty)
    }

    func testBillsToNotifyExcludesNeverSeenBills() {
        let neverSeen = makeSnapshot(id: "C1", committeeDate: "2025-02-01", lastSeenStageKey: nil)

        let result = StageChangeNotifier.billsToNotify(from: [neverSeen], notifiedStageKeys: [:])

        XCTAssertTrue(result.isEmpty)
    }

    private func makeSnapshot(
        id: String,
        committeeDate: String,
        lastSeenStageKey: String?,
        isFavorite: Bool = true
    ) -> BillSnapshot {
        BillSnapshot(
            billID: id,
            age: 22,
            title: "테스트 법안 \(id)",
            committeeDate: committeeDate,
            isFavorite: isFavorite,
            lastSeenStageKey: lastSeenStageKey
        )
    }
}

/// Regression coverage for the release QA defects.
final class StageChangeReleaseQATests: XCTestCase {
    func testRefreshPreservesUnseenChangeUntilDetailIsRead() throws {
        let manager = CoreDataManager.makeInMemory()
        let initial = BillSnapshot(billID: "QA-READ", age: 22, title: "QA", proposedDate: "2026-01-01")
        manager.saveSnapshots([initial])
        _ = manager.toggleFavorite(id: initial.billID)
        var changed = initial
        changed.committeeDate = "2026-02-01"
        manager.saveSnapshots([changed])
        let unread = try XCTUnwrap(manager.fetchSnapshot(id: initial.billID))
        XCTAssertEqual(StageChangeNotifier.billsToNotify(from: [unread], notifiedStageKeys: [:]).count, 1)
        manager.markStageSeen(id: initial.billID)
        let read = try XCTUnwrap(manager.fetchSnapshot(id: initial.billID))
        XCTAssertTrue(StageChangeNotifier.billsToNotify(from: [read], notifiedStageKeys: [:]).isEmpty)
    }

    func testRelaunchMigrationMustPreserveUnreadStageChange() throws {
        let manager = CoreDataManager.makeInMemory()
        let initial = BillSnapshot(billID: "QA-RELAUNCH", age: 22, title: "QA", proposedDate: "2026-01-01")
        manager.saveSnapshots([initial])
        _ = manager.toggleFavorite(id: initial.billID)
        var changed = initial
        changed.committeeDate = "2026-02-01"
        manager.saveSnapshots([changed])
        XCTAssertTrue(try XCTUnwrap(manager.fetchSnapshot(id: initial.billID)).hasUnseenStageChange)

        // A repeated migration must be harmless.
        manager.migrateUserDefaultsFavorites([initial.toStarredBill()])
        let relaunched = try XCTUnwrap(manager.fetchSnapshot(id: initial.billID))
        XCTAssertTrue(relaunched.hasUnseenStageChange)
    }

    func testLegacyFavoriteFirstFetchMustEstablishBaselineWithoutFalseAlert() throws {
        let manager = CoreDataManager.makeInMemory()
        manager.migrateUserDefaultsFavorites([StarredBill(ID: "QA-LEGACY", age: 22, name: "QA")])
        manager.saveSnapshots([BillSnapshot(billID: "QA-LEGACY", age: 22, title: "QA", proposedDate: "2026-01-01", committeeDate: "2026-02-01")])
        let firstFetch = try XCTUnwrap(manager.fetchSnapshot(id: "QA-LEGACY"))
        XCTAssertTrue(StageChangeNotifier.billsToNotify(from: [firstFetch], notifiedStageKeys: [:]).isEmpty)
        var next = firstFetch
        next.lawSubmitDate = "2026-03-01"
        manager.saveSnapshots([next])
        XCTAssertTrue(try XCTUnwrap(manager.fetchSnapshot(id: "QA-LEGACY")).hasUnseenStageChange)
    }

    func testClearNotifiedRemovesOnlyRequestedBillAndAllowsNewChange() throws {
        let suite = "TodayBill.ReleaseQA.\(UUID().uuidString)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let changed = BillSnapshot(billID: "QA-A", age: 22, title: "QA", committeeDate: "2026-02-01", isFavorite: true, lastSeenStageKey: "proposed")
        defaults.set(["QA-A": changed.stageKey, "QA-B": "completed"], forKey: StageChangeNotifier.notifiedStageKeysDefaultsKey)
        StageChangeNotifier.clearNotified(billID: "QA-A", defaults: defaults)
        let stored = try XCTUnwrap(defaults.dictionary(forKey: StageChangeNotifier.notifiedStageKeysDefaultsKey) as? [String: String])
        XCTAssertEqual(stored, ["QA-B": "completed"])
        XCTAssertEqual(StageChangeNotifier.billsToNotify(from: [changed], notifiedStageKeys: stored).count, 1)
    }

    func testLaterStageChangeCanNotifyAfterPreviousNotification() {
        let first = BillSnapshot(billID: "QA-NEXT", age: 22, title: "QA", committeeDate: "2026-02-01", isFavorite: true, lastSeenStageKey: "proposed")
        var next = first
        next.lawSubmitDate = "2026-03-01"
        XCTAssertTrue(StageChangeNotifier.billsToNotify(from: [first], notifiedStageKeys: [first.billID: first.stageKey]).isEmpty)
        XCTAssertEqual(StageChangeNotifier.billsToNotify(from: [next], notifiedStageKeys: [first.billID: first.stageKey]).count, 1)
    }

    func testUnfavoriteAndRefavoriteEstablishesFreshBaseline() throws {
        let manager = CoreDataManager.makeInMemory()
        let initial = BillSnapshot(billID: "QA-TOGGLE", age: 22, title: "QA", proposedDate: "2026-01-01")
        manager.saveSnapshots([initial])
        _ = manager.toggleFavorite(id: initial.billID)
        var changed = initial
        changed.committeeDate = "2026-02-01"
        manager.saveSnapshots([changed])
        _ = manager.toggleFavorite(id: initial.billID)
        let refavorited = try XCTUnwrap(manager.toggleFavorite(id: initial.billID))
        XCTAssertFalse(refavorited.hasUnseenStageChange)
        XCTAssertEqual(refavorited.lastSeenStageKey, refavorited.stageKey)
    }

    func testAllRefreshRequestsFailMustReportFailure() {
        let manager = CoreDataManager.makeInMemory()
        _ = manager.setFavorite(snapshot: BillSnapshot(billID: "QA-OFFLINE", age: 22, title: "QA"), isFavorite: true)
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ReleaseQAOfflineURLProtocol.self]
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        let repository = BillRepository(apiClient: OpenAssemblyAPIClient(session: session), coreDataManager: manager)
        let completed = expectation(description: "refresh returns")
        repository.refreshFavoriteSnapshots { result in
            if case .success = result { XCTFail("Expected failure, received cached favorites as success") }
            completed.fulfill()
        }
        wait(for: [completed], timeout: 5)
    }
}

private final class ReleaseQAOfflineURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() { client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet)) }
    override func stopLoading() {}
}

final class StageNotificationDeliveryTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    private let date = Date(timeIntervalSince1970: 1_800_000_000)

    override func setUp() {
        super.setUp()
        suite = "TodayBill.NotificationTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }

    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        defaults = nil
        super.tearDown()
    }

    private func changed(_ id: String = "A") -> BillSnapshot {
        BillSnapshot(billID: id, age: 22, title: "법안 \(id)", committeeDate: "2026-01-02", isFavorite: true, lastSeenStageKey: "proposed")
    }

    private func makeNotifier(_ repository: StubFavoriteRefresher, _ center: StubStageNotificationCenter) -> StageChangeNotifier {
        let now = date
        return StageChangeNotifier(repository: repository, defaults: defaults, center: center, now: { now })
    }

    private var history: [String: String] {
        defaults.dictionary(forKey: StageChangeNotifier.notifiedStageKeysDefaultsKey) as? [String: String] ?? [:]
    }

    func testRegistrationFailureRemainsRetryableAndSuccessfulRetryRecordsHistory() {
        let repository = StubFavoriteRefresher([changed()])
        let center = StubStageNotificationCenter()
        center.addError = URLError(.cannotCreateFile)
        let notifier = makeNotifier(repository, center)
        let failed = expectation(description: "failure reported")
        notifier.run { result in
            if case .success = result { XCTFail("Registration failure was hidden") }
            failed.fulfill()
        }
        wait(for: [failed], timeout: 2)
        XCTAssertTrue(history.isEmpty)
        XCTAssertNotNil(defaults.string(forKey: StageChangeNotifier.lastErrorKey))

        center.addError = nil
        let succeeded = expectation(description: "retry")
        notifier.runIfNeeded { result in
            if case .failure(let error) = result { XCTFail("\(error)") }
            succeeded.fulfill()
        }
        wait(for: [succeeded], timeout: 2)
        XCTAssertEqual(history["A"], changed().stageKey)
        XCTAssertEqual(repository.refreshCount, 1, "Retry delivery from fresh cache")
        XCTAssertEqual(center.requests.count, 2)
    }

    func testHistoryAndCompletionWaitForSuccessfulRegistration() {
        let repository = StubFavoriteRefresher([changed()])
        let center = StubStageNotificationCenter()
        center.holdAdd = true
        let notifier = makeNotifier(repository, center)
        let attempted = expectation(description: "add attempted")
        center.onAdd = { attempted.fulfill() }
        var completed = false
        let done = expectation(description: "finished")
        notifier.run { _ in completed = true; done.fulfill() }
        wait(for: [attempted], timeout: 2)
        XCTAssertFalse(completed)
        XCTAssertTrue(history.isEmpty)
        center.addCompletion?(nil)
        wait(for: [done], timeout: 2)
        XCTAssertEqual(history["A"], changed().stageKey)
    }

    func testPermissionRecoveryDeliversCachedChangeWithoutWaitingSixHours() {
        let repository = StubFavoriteRefresher([changed()])
        let center = StubStageNotificationCenter()
        center.status = .denied
        let notifier = makeNotifier(repository, center)
        let denied = expectation(description: "denied")
        notifier.run { _ in denied.fulfill() }
        wait(for: [denied], timeout: 2)
        XCTAssertTrue(history.isEmpty)
        XCTAssertTrue(center.requests.isEmpty)
        center.status = .authorized
        let allowed = expectation(description: "allowed")
        notifier.runIfNeeded { _ in allowed.fulfill() }
        wait(for: [allowed], timeout: 2)
        XCTAssertEqual(repository.refreshCount, 1)
        XCTAssertEqual(center.requests.count, 1)
        XCTAssertEqual(history["A"], changed().stageKey)
    }

    func testProvisionalAuthorizationCanDeliverQuietNotification() {
        let repository = StubFavoriteRefresher([changed()])
        let center = StubStageNotificationCenter()
        center.status = .provisional
        let notifier = makeNotifier(repository, center)
        let done = expectation(description: "quiet notification")
        notifier.run { _ in done.fulfill() }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(center.requests.count, 1)
        XCTAssertEqual(history["A"], changed().stageKey)
    }

    func testConcurrentRunsShareOneRefreshAndOneNotification() {
        let repository = StubFavoriteRefresher([changed()])
        let center = StubStageNotificationCenter()
        let notifier = makeNotifier(repository, center)
        let done = expectation(description: "both callers")
        done.expectedFulfillmentCount = 2
        let first = notifier.run { _ in done.fulfill() }
        let second = notifier.run { _ in done.fulfill() }
        XCTAssertTrue(first === second)
        wait(for: [done], timeout: 2)
        XCTAssertEqual(repository.refreshCount, 1)
        XCTAssertEqual(center.requests.count, 1)
        let duplicate = expectation(description: "duplicate suppressed")
        notifier.run { _ in duplicate.fulfill() }
        wait(for: [duplicate], timeout: 2)
        XCTAssertEqual(center.requests.count, 1)
    }

    func testPartialFailureDeliversOnlySuccessfulBillsAndReportsFailure() {
        let repository = StubFavoriteRefresher([changed("A"), changed("B")])
        repository.result = .failure(FavoriteRefreshFailure(refreshedSnapshots: [changed("A")], failedBillIDs: ["B"], underlyingError: URLError(.timedOut)))
        let center = StubStageNotificationCenter()
        let notifier = makeNotifier(repository, center)
        let done = expectation(description: "partial refresh")
        notifier.run { result in
            if case .success = result { XCTFail("Partial failure reported as success") }
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
        XCTAssertEqual(center.requests.count, 1)
        XCTAssertEqual(history, ["A": changed().stageKey])
        XCTAssertNil(defaults.object(forKey: StageChangeNotifier.lastSuccessfulRefreshKey))
    }

    func testFailedRefreshPreservesHistoryAndDoesNotMarkSuccess() {
        let repository = StubFavoriteRefresher([changed()])
        repository.result = .failure(URLError(.notConnectedToInternet))
        let center = StubStageNotificationCenter()
        let notifier = makeNotifier(repository, center)
        let done = expectation(description: "failed refresh")
        notifier.run { result in
            if case .success = result { XCTFail("Expected error") }
            done.fulfill()
        }
        wait(for: [done], timeout: 2)
        XCTAssertTrue(center.requests.isEmpty)
        XCTAssertTrue(history.isEmpty)
        XCTAssertNil(defaults.object(forKey: StageChangeNotifier.lastSuccessfulRefreshKey))
    }

    func testCancellationStopsRefreshAndIgnoresLateCallback() {
        let repository = StubFavoriteRefresher([changed()])
        repository.holdRefresh = true
        let center = StubStageNotificationCenter()
        let notifier = makeNotifier(repository, center)
        let done = expectation(description: "cancelled")
        var completionCount = 0
        let token = notifier.run { result in
            completionCount += 1
            if case .success = result { XCTFail("Cancellation reported success") }
            done.fulfill()
        }
        token.cancel()
        wait(for: [done], timeout: 2)
        XCTAssertTrue(repository.wasCancelled)
        repository.refreshCompletion?(.success(repository.snapshots))
        let drained = expectation(description: "late callback drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 2)
        XCTAssertEqual(completionCount, 1)
        XCTAssertTrue(center.requests.isEmpty)
        XCTAssertTrue(history.isEmpty)
        XCTAssertNil(defaults.object(forKey: StageChangeNotifier.lastSuccessfulRefreshKey))
    }

    func testCancellationDuringAddDoesNotRecordLateSuccess() {
        let repository = StubFavoriteRefresher([changed()])
        let center = StubStageNotificationCenter()
        center.holdAdd = true
        let notifier = makeNotifier(repository, center)
        let attempted = expectation(description: "add attempted")
        center.onAdd = { attempted.fulfill() }
        let done = expectation(description: "cancelled")
        var completionCount = 0
        let token = notifier.run { result in
            completionCount += 1
            if case .success = result { XCTFail("Expected cancellation") }
            done.fulfill()
        }
        wait(for: [attempted], timeout: 2)
        token.cancel()
        wait(for: [done], timeout: 2)
        center.addCompletion?(nil)
        let drained = expectation(description: "late registration drained")
        DispatchQueue.main.async { drained.fulfill() }
        wait(for: [drained], timeout: 2)
        XCTAssertEqual(center.removals, 1)
        XCTAssertEqual(completionCount, 1)
        XCTAssertTrue(history.isEmpty)
    }

    func testUnfavoriteWhileReadingSettingsPreventsNotification() {
        let repository = StubFavoriteRefresher([changed()])
        let center = StubStageNotificationCenter()
        center.holdAuthorization = true
        let notifier = makeNotifier(repository, center)
        let queried = expectation(description: "settings queried")
        center.onAuthorization = { queried.fulfill() }
        let done = expectation(description: "finished")
        notifier.run { _ in done.fulfill() }
        wait(for: [queried], timeout: 2)
        repository.snapshots = []
        center.authorizationCompletion?(.authorized)
        wait(for: [done], timeout: 2)
        XCTAssertTrue(center.requests.isEmpty)
        XCTAssertTrue(history.isEmpty)
    }

    func testUnfavoriteDuringRegistrationDoesNotRestoreClearedHistory() {
        let repository = StubFavoriteRefresher([changed()])
        let center = StubStageNotificationCenter()
        center.holdAdd = true
        let notifier = makeNotifier(repository, center)
        let attempted = expectation(description: "add attempted")
        center.onAdd = { attempted.fulfill() }
        let done = expectation(description: "finished")
        notifier.run { _ in done.fulfill() }
        wait(for: [attempted], timeout: 2)
        repository.snapshots = []
        defaults.set(["B": "completed"], forKey: StageChangeNotifier.notifiedStageKeysDefaultsKey)
        StageChangeNotifier.clearNotified(billID: "A", defaults: defaults)
        center.addCompletion?(nil)
        wait(for: [done], timeout: 2)
        XCTAssertEqual(history, ["B": "completed"])
    }

    func testForegroundRefreshesStaleDataAndThrottlesRepeatedFailures() {
        defaults.set(date.addingTimeInterval(-7 * 3600), forKey: StageChangeNotifier.lastSuccessfulRefreshKey)
        let repository = StubFavoriteRefresher([])
        repository.result = .failure(URLError(.notConnectedToInternet))
        let center = StubStageNotificationCenter()
        let notifier = makeNotifier(repository, center)
        let first = expectation(description: "stale refresh")
        notifier.runIfNeeded { _ in first.fulfill() }
        wait(for: [first], timeout: 2)
        let second = expectation(description: "throttled")
        notifier.runIfNeeded { _ in second.fulfill() }
        wait(for: [second], timeout: 2)
        XCTAssertEqual(repository.refreshCount, 1)
    }
}

private final class StubFavoriteRefresher: FavoriteRefreshing {
    var snapshots: [BillSnapshot]
    var result: Result<[BillSnapshot], Error>?
    var refreshCount = 0
    var holdRefresh = false
    var wasCancelled = false
    var refreshCompletion: ((Result<[BillSnapshot], Error>) -> Void)?
    init(_ snapshots: [BillSnapshot]) { self.snapshots = snapshots }
    func favoriteSnapshots() -> [BillSnapshot] { snapshots }
    func refreshFavoriteSnapshots(cancellation: StageCheckCancellation, completion: @escaping (Result<[BillSnapshot], Error>) -> Void) {
        refreshCount += 1
        cancellation.onCancel { [weak self] in self?.wasCancelled = true }
        refreshCompletion = completion
        if !holdRefresh { completion(result ?? .success(snapshots)) }
    }
}

private final class StubStageNotificationCenter: StageNotificationSending {
    var status: UNAuthorizationStatus = .authorized
    var addError: Error?
    var requests: [UNNotificationRequest] = []
    var removals = 0
    var holdAdd = false
    var holdAuthorization = false
    var onAdd: (() -> Void)?
    var onAuthorization: (() -> Void)?
    var addCompletion: ((Error?) -> Void)?
    var authorizationCompletion: ((UNAuthorizationStatus) -> Void)?
    func authorizationStatus(completion: @escaping (UNAuthorizationStatus) -> Void) {
        authorizationCompletion = completion
        onAuthorization?()
        if !holdAuthorization { completion(status) }
    }
    func add(_ request: UNNotificationRequest, completion: @escaping (Error?) -> Void) {
        requests.append(request)
        addCompletion = completion
        onAdd?()
        if !holdAdd { completion(addError) }
    }
    func removePendingDigest() { removals += 1 }
}

final class StageCheckSchedulingTests: XCTestCase {
    private var defaults: UserDefaults!
    private var suite: String!
    override func setUp() {
        super.setUp()
        suite = "TodayBill.SchedulerTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
    }
    override func tearDown() {
        defaults.removePersistentDomain(forName: suite)
        super.tearDown()
    }
    private func drain() {
        let done = expectation(description: "scheduler callback")
        DispatchQueue.main.async { done.fulfill() }
        wait(for: [done], timeout: 2)
    }
    func testExistingRequestIsNotPostponedByRepeatedScheduling() {
        let backend = StubStageCheckScheduler()
        let original = BGAppRefreshTaskRequest(identifier: AppDelegate.stageCheckTaskIdentifier)
        original.earliestBeginDate = Date(timeIntervalSince1970: 1_800_000_000)
        backend.pending = [original]
        let scheduler = StageCheckScheduler(scheduler: backend, hasFavorites: { true }, defaults: defaults,
                                           now: { Date(timeIntervalSince1970: 1_800_000_000 - 3600) })
        scheduler.scheduleIfNeeded()
        scheduler.scheduleIfNeeded()
        drain()
        XCTAssertEqual(backend.checkCount, 1)
        XCTAssertTrue(backend.submissions.isEmpty)
        XCTAssertEqual(original.earliestBeginDate, Date(timeIntervalSince1970: 1_800_000_000))
    }
    func testConcurrentRequestsCreateOneScheduleAndUseEarlierRetryDelay() {
        let backend = StubStageCheckScheduler()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let scheduler = StageCheckScheduler(scheduler: backend, hasFavorites: { true }, defaults: defaults, now: { now })
        scheduler.scheduleIfNeeded()
        scheduler.scheduleIfNeeded(delay: StageChangeNotifier.retryInterval)
        drain()
        XCTAssertEqual(backend.submissions.count, 1)
        XCTAssertEqual(backend.submissions.first?.earliestBeginDate, now.addingTimeInterval(900))
    }
    func testFailureBringsExistingLaterRequestForwardWithoutPostponingDueWork() {
        let backend = StubStageCheckScheduler()
        let now = Date(timeIntervalSince1970: 1_800_000_000)
        let original = BGAppRefreshTaskRequest(identifier: AppDelegate.stageCheckTaskIdentifier)
        original.earliestBeginDate = now.addingTimeInterval(6 * 3600)
        backend.pending = [original]
        let scheduler = StageCheckScheduler(scheduler: backend, hasFavorites: { true }, defaults: defaults, now: { now })
        scheduler.scheduleIfNeeded(delay: 900)
        drain()
        XCTAssertEqual(backend.submissions.first?.earliestBeginDate, now.addingTimeInterval(900))
        backend.pending.first?.earliestBeginDate = nil
        scheduler.scheduleIfNeeded()
        drain()
        XCTAssertEqual(backend.submissions.count, 1, "Already eligible work stays eligible")
    }
    func testRemovingFinalFavoriteCancelsPendingRequestIncludingDuringCheck() {
        let backend = StubStageCheckScheduler()
        var hasFavorites = true
        let scheduler = StageCheckScheduler(scheduler: backend, hasFavorites: { hasFavorites }, defaults: defaults)
        scheduler.scheduleIfNeeded()
        hasFavorites = false
        scheduler.scheduleIfNeeded()
        drain()
        XCTAssertEqual(backend.cancelled, [AppDelegate.stageCheckTaskIdentifier])
        XCTAssertTrue(backend.submissions.isEmpty)
        scheduler.scheduleIfNeeded()
        XCTAssertEqual(backend.cancelled.count, 2)
    }
    func testSubmissionErrorIsRecordedAndLaterRetryCanSucceed() {
        let backend = StubStageCheckScheduler()
        backend.error = NSError(domain: "SchedulerQA", code: 1)
        let scheduler = StageCheckScheduler(scheduler: backend, hasFavorites: { true }, defaults: defaults)
        scheduler.scheduleIfNeeded()
        drain()
        XCTAssertEqual(defaults.string(forKey: StageCheckScheduler.lastErrorKey), "SchedulerQA:1")
        backend.error = nil
        scheduler.scheduleIfNeeded()
        drain()
        XCTAssertEqual(backend.submissions.count, 1)
        XCTAssertNil(defaults.object(forKey: StageCheckScheduler.lastErrorKey))
    }
    func testCompletionWaitsUntilSuccessorHasBeenSubmitted() {
        let backend = StubStageCheckScheduler()
        backend.holdPending = true
        let scheduler = StageCheckScheduler(scheduler: backend, hasFavorites: { true }, defaults: defaults)
        var completions = 0
        scheduler.scheduleIfNeeded {
            XCTAssertEqual(backend.submissions.count, 1)
            completions += 1
        }
        scheduler.scheduleIfNeeded { completions += 1 }
        XCTAssertEqual(completions, 0)
        backend.pendingCompletion?([])
        drain()
        XCTAssertEqual(completions, 2)
    }
    func testExpirationBeforeWorkRegistrationStillCancelsWork() {
        let lifetime = StageCheckCancellation()
        lifetime.cancel()
        lifetime.finish()
        let work = StageCheckCancellation()
        lifetime.onCancel { work.cancel() }
        XCTAssertTrue(work.isCancelled)
    }
}

private final class StubStageCheckScheduler: StageCheckScheduling {
    var pending: [BGTaskRequest] = []
    var submissions: [BGTaskRequest] = []
    var cancelled: [String] = []
    var checkCount = 0
    var error: Error?
    var holdPending = false
    var pendingCompletion: (([BGTaskRequest]) -> Void)?
    func pendingRequests(completion: @escaping ([BGTaskRequest]) -> Void) {
        checkCount += 1
        pendingCompletion = completion
        if !holdPending { completion(pending) }
    }
    func submit(_ request: BGTaskRequest) throws {
        if let error { throw error }
        submissions.append(request)
        pending.removeAll { $0.identifier == request.identifier }
        pending.append(request)
    }
    func cancel(identifier: String) { cancelled.append(identifier) }
}

final class FavoriteRefreshIntegrationTests: XCTestCase {
    override func tearDown() {
        ControlledFavoriteURLProtocol.onStart = nil
        ControlledFavoriteURLProtocol.onStop = nil
        super.tearDown()
    }

    private func setupRepository(ids: [String]) -> (BillRepository, CoreDataManager, URLSession) {
        let manager = CoreDataManager.makeInMemory()
        ids.forEach { id in
            _ = manager.setFavorite(snapshot: BillSnapshot(billID: id, age: 22, title: "QA", proposedDate: "2026-01-01"), isFavorite: true)
        }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ControlledFavoriteURLProtocol.self]
        let session = URLSession(configuration: config)
        return (BillRepository(apiClient: OpenAssemblyAPIClient(session: session), coreDataManager: manager), manager, session)
    }

    func testPartialNetworkFailureSavesSuccessfulBillAndReturnsPartialError() {
        ControlledFavoriteURLProtocol.mode = .mixed
        let (repository, manager, session) = setupRepository(ids: ["SUCCESS", "FAIL"])
        defer { session.invalidateAndCancel() }
        let done = expectation(description: "partial network result")
        repository.refreshFavoriteSnapshots { result in
            switch result {
            case .success: XCTFail("Partial failure must remain visible")
            case .failure(let error):
                guard let partial = error as? FavoriteRefreshFailure else { XCTFail("Missing partial details"); done.fulfill(); return }
                XCTAssertEqual(partial.failedBillIDs, ["FAIL"])
                XCTAssertEqual(partial.refreshedSnapshots.map(\.billID), ["SUCCESS"])
                XCTAssertEqual(partial.refreshedSnapshots.first?.hasUnseenStageChange, true)
            }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
        XCTAssertEqual(manager.fetchSnapshot(id: "SUCCESS")?.committeeDate, "2026-02-01")
        XCTAssertNil(manager.fetchSnapshot(id: "FAIL")?.committeeDate)
    }

    func testEmptyDetailResponseDoesNotCountAsRefreshSuccess() {
        ControlledFavoriteURLProtocol.mode = .empty
        let (repository, _, session) = setupRepository(ids: ["EMPTY"])
        defer { session.invalidateAndCancel() }
        let done = expectation(description: "empty detail")
        repository.refreshFavoriteSnapshots { result in
            if case .success = result { XCTFail("No matching bill was fetched") }
            done.fulfill()
        }
        wait(for: [done], timeout: 5)
    }

    func testCancellationCancelsRealURLSessionTasksAndBoundsConcurrency() {
        ControlledFavoriteURLProtocol.mode = .hold
        let (repository, _, session) = setupRepository(ids: (1...8).map { "HOLD-\($0)" })
        defer { session.invalidateAndCancel() }
        let started = expectation(description: "four requests started")
        started.expectedFulfillmentCount = 4
        started.assertForOverFulfill = true
        let stopped = expectation(description: "four requests cancelled")
        stopped.expectedFulfillmentCount = 4
        ControlledFavoriteURLProtocol.onStart = { started.fulfill() }
        ControlledFavoriteURLProtocol.onStop = { stopped.fulfill() }
        let done = expectation(description: "cancel result")
        let cancellation = StageCheckCancellation()
        repository.refreshFavoriteSnapshots(cancellation: cancellation) { result in
            switch result {
            case .success: XCTFail("Expected cancellation")
            case .failure(let error): XCTAssertEqual((error as? URLError)?.code, .cancelled)
            }
            done.fulfill()
        }
        wait(for: [started], timeout: 5)
        cancellation.cancel()
        wait(for: [stopped, done], timeout: 5)
        cancellation.finish()
    }
}

private final class ControlledFavoriteURLProtocol: URLProtocol {
    enum Mode { case mixed, empty, hold }
    static var mode = Mode.mixed
    static var onStart: (() -> Void)?
    static var onStop: (() -> Void)?
    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func startLoading() {
        if Self.mode == .hold { Self.onStart?(); return }
        let id = URLComponents(url: request.url!, resolvingAgainstBaseURL: false)?.queryItems?.first(where: { $0.name == "BILL_ID" })?.value ?? ""
        if id == "FAIL" {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }
        let rows: [[String: String]] = Self.mode == .empty ? [] : [[
            "BILL_ID": id, "BILL_NO": "123", "BILL_NAME": "QA", "PROPOSE_DT": "2026-01-01",
            "AGE": "22", "DETAIL_LINK": "https://example.com", "COMMITTEE_DT": "2026-02-01",
            "PROPOSER": "QA", "MEMBER_LIST": "QA"
        ]]
        let data = try! JSONSerialization.data(withJSONObject: ["nzmimeepazxkubdpn": [["row": rows]]])
        client?.urlProtocol(self, didReceive: HTTPURLResponse(url: request.url!, statusCode: 200, httpVersion: nil, headerFields: nil)!, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    override func stopLoading() { if Self.mode == .hold { Self.onStop?() } }
}
