//
//  BillsRepository.swift
//  TodayBill
//
//  Created by 김건호 on 2/18/25.
//

import Foundation
import UserNotifications

enum BillsRepositoryError: Error {
    case dateConversionFailed
    case missingSnapshot
}

protocol BillRepositoryProtocol {
    func fetchHomeBills(date: Date, completion: @escaping (Result<[BillSnapshot], Error>) -> Void)
    func fetchHomeDashboard(date: Date, completion: @escaping (Result<HomeDashboard, Error>) -> Void)
    func fetchHotBills(limit: Int, completion: @escaping (Result<[HotBillSnapshot], Error>) -> Void)
    func fetchLawEnforcements(range: LawEnforcementDateRange, completion: @escaping (Result<[LawEnforcementSnapshot], Error>) -> Void)
    func refreshHomeDashboard(completion: @escaping (Result<HomeDashboard, Error>) -> Void)
    func searchBills(filter: BillFilter, page: Int, completion: @escaping (Result<[BillSnapshot], Error>) -> Void)
    func fetchDetail(id: String, age: Int, completion: @escaping (Result<BillSnapshot, Error>) -> Void)
    func toggleFavorite(id: String, completion: @escaping (Result<BillSnapshot, Error>) -> Void)
    func refreshFavoriteSnapshots(completion: @escaping (Result<[BillSnapshot], Error>) -> Void)
    func markStageSeen(id: String)
    func fetchSummary(for snapshot: BillSnapshot, completion: @escaping (Result<BillSnapshot, Error>) -> Void)
    func fetchVoteSummary(billID: String, age: Int, completion: @escaping (Result<BillVoteSummary?, Error>) -> Void)
    func fetchRepresentative(proposer: String?, age: Int, completion: @escaping (Result<Representative?, Error>) -> Void)
    func cachedSnapshot(id: String) -> BillSnapshot?
}

final class HomeDashboardCache {
    private let defaults: UserDefaults
    private let key = "HomeDashboardCache.v1"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func save(_ dashboard: HomeDashboard) {
        guard let data = try? JSONEncoder().encode(dashboard) else { return }
        defaults.set(data, forKey: key)
    }

    func load() -> HomeDashboard? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(HomeDashboard.self, from: data)
    }

    func clear() {
        defaults.removeObject(forKey: key)
    }
}

final class BillRepository: BillRepositoryProtocol, FavoriteRefreshing {
    static let shared = BillRepository()

    private let apiClient: OpenAssemblyAPIClient
    private let voteAPIClient: OpenAssemblyVoteAPIClient
    private let representativeAPIClient: OpenAssemblyRepresentativeAPIClient
    private let summaryClient: AssemblySummaryClient
    private let lawInfoClient: LawInfoAPIClient
    private let coreDataManager: CoreDataManager
    private let dashboardCache: HomeDashboardCache

    init(
        apiClient: OpenAssemblyAPIClient = .shared,
        voteAPIClient: OpenAssemblyVoteAPIClient = .shared,
        representativeAPIClient: OpenAssemblyRepresentativeAPIClient = .shared,
        summaryClient: AssemblySummaryClient = AssemblySummaryClient(),
        lawInfoClient: LawInfoAPIClient = .shared,
        coreDataManager: CoreDataManager = .shared,
        dashboardCache: HomeDashboardCache = HomeDashboardCache()
    ) {
        self.apiClient = apiClient
        self.voteAPIClient = voteAPIClient
        self.representativeAPIClient = representativeAPIClient
        self.summaryClient = summaryClient
        self.lawInfoClient = lawInfoClient
        self.coreDataManager = coreDataManager
        self.dashboardCache = dashboardCache
    }

    func fetchHomeBills(date: Date, completion: @escaping (Result<[BillSnapshot], Error>) -> Void) {
        guard let formattedDate = formatDate(date) else {
            completion(.failure(BillsRepositoryError.dateConversionFailed))
            return
        }

        let cached = coreDataManager.fetchSnapshots(for: formattedDate)
        if !cached.isEmpty {
            completion(.success(cached))
            return
        }

        apiClient.fetchBills(page: 1, age: 22) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let rows):
                self.coreDataManager.saveAll(rows)
                let requestedDateSnapshots = self.coreDataManager.fetchSnapshots(for: formattedDate)
                if !requestedDateSnapshots.isEmpty {
                    completion(.success(requestedDateSnapshots))
                } else {
                    completion(.success(self.coreDataManager.fetchLatestSnapshots()))
                }
            case .failure(let error):
                let fallback = self.coreDataManager.fetchLatestSnapshots()
                fallback.isEmpty ? completion(.failure(error)) : completion(.success(fallback))
            }
        }
    }

    func fetchHomeDashboard(date: Date, completion: @escaping (Result<HomeDashboard, Error>) -> Void) {
        fetchHomeBills(date: date) { [weak self] billResult in
            guard let self = self else { return }

            switch billResult {
            case .success(let selectedDateBills):
                let range = LawEnforcementDateRange.aroundToday()
                self.fetchLawEnforcements(range: range) { lawResult in
                    var failedSections: [HomeDashboardSection] = []
                    var lawEnforcements: [LawEnforcementSnapshot] = []
                    var isUsingCache = false

                    switch lawResult {
                    case .success(let snapshots):
                        lawEnforcements = snapshots
                    case .failure:
                        failedSections.append(.lawEnforcements)
                        if let cached = self.dashboardCache.load() {
                            lawEnforcements = cached.lawEnforcements
                            isUsingCache = !lawEnforcements.isEmpty
                        }
                    }

                    var dashboard = self.makeHomeDashboard(
                        selectedDateBills: selectedDateBills,
                        lawEnforcements: lawEnforcements,
                        failedSections: failedSections
                    )
                    dashboard.isUsingCache = isUsingCache

                    if failedSections.isEmpty {
                        self.dashboardCache.save(dashboard)
                    }
                    completion(.success(dashboard))
                }
            case .failure(let error):
                if var cached = self.dashboardCache.load() {
                    cached.isUsingCache = true
                    cached.failedSections = HomeDashboardSection.allCases
                    completion(.success(cached))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    func fetchHotBills(limit: Int, completion: @escaping (Result<[HotBillSnapshot], Error>) -> Void) {
        let cachedSnapshots = coreDataManager.fetchRecentSnapshots()
        if !cachedSnapshots.isEmpty {
            completion(.success(makeHotBills(from: cachedSnapshots, limit: limit)))
            return
        }

        apiClient.fetchBills(page: 1, age: 22) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let rows):
                self.coreDataManager.saveAll(rows)
                completion(.success(self.makeHotBills(from: self.coreDataManager.fetchRecentSnapshots(), limit: limit)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchLawEnforcements(
        range: LawEnforcementDateRange,
        completion: @escaping (Result<[LawEnforcementSnapshot], Error>) -> Void
    ) {
        lawInfoClient.fetchLawEnforcements(range: range) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let snapshots):
                let bills = self.coreDataManager.fetchRecentSnapshots(limit: 500)
                completion(.success(LawBillMatcher.match(lawEnforcements: snapshots, bills: bills)))
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func refreshHomeDashboard(completion: @escaping (Result<HomeDashboard, Error>) -> Void) {
        fetchHomeDashboard(date: Date(), completion: completion)
    }

    func searchBills(filter: BillFilter, page: Int, completion: @escaping (Result<[BillSnapshot], Error>) -> Void) {
        apiClient.searchBills(filter: filter, page: page) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let rows):
                let fetchedSnapshots = rows.map(BillSnapshot.init(row:))
                self.coreDataManager.saveSnapshots(fetchedSnapshots)
                let snapshots = rows.compactMap { self.coreDataManager.fetchSnapshot(id: $0.BILL_ID) }
                    .filter { $0.matches(filter: filter) }
                completion(.success(BillSnapshot.sort(snapshots, order: filter.sortOrder)))
            case .failure(let error):
                let cached = self.coreDataManager.searchSnapshots(filter: filter)
                cached.isEmpty ? completion(.failure(error)) : completion(.success(cached))
            }
        }
    }

    func fetchDetail(id: String, age: Int, completion: @escaping (Result<BillSnapshot, Error>) -> Void) {
        apiClient.fetchDetail(id: id, age: age) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let rows):
                self.coreDataManager.saveAll(rows)
                if let snapshot = self.coreDataManager.fetchSnapshot(id: id) {
                    completion(.success(snapshot))
                } else {
                    completion(.failure(BillsRepositoryError.missingSnapshot))
                }
            case .failure(let error):
                if let cached = self.coreDataManager.fetchSnapshot(id: id) {
                    completion(.success(cached))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    func toggleFavorite(id: String, completion: @escaping (Result<BillSnapshot, Error>) -> Void) {
        guard let snapshot = coreDataManager.toggleFavorite(id: id) else {
            completion(.failure(BillsRepositoryError.missingSnapshot))
            return
        }

        if snapshot.isFavorite {
            StarBillManager.shared.addBillToStarred(snapshot.toStarredBill())
            UserDefaults.standard.removeObject(forKey: StageChangeNotifier.lastSuccessfulRefreshKey)
            UserDefaults.standard.removeObject(forKey: StageChangeNotifier.lastRefreshAttemptKey)
            if coreDataManager.fetchFavoriteSnapshots().count == 1 {
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
            }
        } else {
            StarBillManager.shared.removeBillFromStarred(by: id)
            StageChangeNotifier.clearNotified(billID: id)
        }
        NotificationCenter.default.post(name: StageChangeNotifier.favoritesDidChange, object: nil)
        completion(.success(snapshot))
    }

    func refreshFavoriteSnapshots(completion: @escaping (Result<[BillSnapshot], Error>) -> Void) {
        let cancellation = StageCheckCancellation()
        refreshFavoriteSnapshots(cancellation: cancellation) { result in
            cancellation.finish()
            completion(result)
        }
    }

    func refreshFavoriteSnapshots(
        cancellation: StageCheckCancellation,
        completion: @escaping (Result<[BillSnapshot], Error>) -> Void
    ) {
        DispatchQueue.main.async {
            let favorites = self.coreDataManager.fetchFavoriteSnapshots()
            var nextIndex = 0
            var inFlight = 0
            var successfulIDs = Set<String>()
            var failedIDs: [String] = []
            var firstError: Error?
            var finished = false

            func finish(_ result: Result<[BillSnapshot], Error>) {
                guard !finished else { return }
                finished = true
                completion(result)
            }

            cancellation.onCancel {
                DispatchQueue.main.async { finish(.failure(URLError(.cancelled))) }
            }

            func fetchNext() {
                guard !finished else { return }
                guard !cancellation.isCancelled else { finish(.failure(URLError(.cancelled))); return }
                if nextIndex == favorites.count && inFlight == 0 {
                    let refreshed = self.coreDataManager.fetchFavoriteSnapshots().filter { successfulIDs.contains($0.billID) }
                    if let firstError {
                        finish(.failure(FavoriteRefreshFailure(
                            refreshedSnapshots: refreshed,
                            failedBillIDs: failedIDs,
                            underlyingError: firstError
                        )))
                    } else {
                        finish(.success(refreshed))
                    }
                    return
                }

                // Bound concurrent requests so a large favorites list does not flood the API.
                while inFlight < 4 && nextIndex < favorites.count && !cancellation.isCancelled {
                    let snapshot = favorites[nextIndex]
                    nextIndex += 1
                    inFlight += 1
                    let task = self.apiClient.fetchDetail(id: snapshot.billID, age: snapshot.age) { result in
                        DispatchQueue.main.async {
                            guard !finished, !cancellation.isCancelled else { return }
                            inFlight -= 1
                            switch result {
                            case .success(let rows) where rows.contains(where: { $0.BILL_ID == snapshot.billID }):
                                self.coreDataManager.saveAll(rows.filter { $0.BILL_ID == snapshot.billID })
                                successfulIDs.insert(snapshot.billID)
                            case .success:
                                failedIDs.append(snapshot.billID)
                                firstError = firstError ?? BillsRepositoryError.missingSnapshot
                            case .failure(let error):
                                failedIDs.append(snapshot.billID)
                                firstError = firstError ?? error
                            }
                            fetchNext()
                        }
                    }
                    if let task { cancellation.onCancel { task.cancel() } }
                }
            }
            fetchNext()
        }
    }

    func markStageSeen(id: String) {
        coreDataManager.markStageSeen(id: id)
    }

    func fetchSummary(for snapshot: BillSnapshot, completion: @escaping (Result<BillSnapshot, Error>) -> Void) {
        guard !snapshot.detailLink.isEmpty else {
            completion(.failure(URLError(.badURL)))
            return
        }

        summaryClient.fetchSummary(from: snapshot.detailLink) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .success(let summary):
                if let updated = self.coreDataManager.updateSummary(id: snapshot.billID, summary: summary) {
                    completion(.success(updated))
                } else {
                    completion(.failure(BillsRepositoryError.missingSnapshot))
                }
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }

    func fetchVoteSummary(
        billID: String,
        age: Int,
        completion: @escaping (Result<BillVoteSummary?, Error>) -> Void
    ) {
        voteAPIClient.fetchVoteSummary(billID: billID, age: age, completion: completion)
    }

    func fetchRepresentative(
        proposer: String?,
        age: Int,
        completion: @escaping (Result<Representative?, Error>) -> Void
    ) {
        guard let name = RepresentativeLookup.proposerName(from: proposer) else {
            completion(.success(nil))
            return
        }

        representativeAPIClient.fetchRepresentative(named: name, age: age, completion: completion)
    }

    func cachedSnapshot(id: String) -> BillSnapshot? {
        coreDataManager.fetchSnapshot(id: id)
    }

    func favoriteSnapshots() -> [BillSnapshot] {
        coreDataManager.fetchFavoriteSnapshots()
    }

    static func makeTrackingSections(from snapshots: [BillSnapshot]) -> [BillTrackingSection] {
        let changed = snapshots.filter(\.hasUnseenStageChange)
        let unchanged = snapshots.filter { !$0.hasUnseenStageChange }

        let committee = unchanged.filter { $0.stage == .proposed || $0.stage == .committee }
        let lawAndPlenary = unchanged.filter { $0.stage == .lawReview || $0.stage == .plenary }
        let completed = unchanged.filter { $0.stage == .completed || $0.stage == .unknown }

        return [
            BillTrackingSection(title: "진행 변경 있음", snapshots: changed),
            BillTrackingSection(title: "위원회 심사", snapshots: committee),
            BillTrackingSection(title: "법사위/본회의", snapshots: lawAndPlenary),
            BillTrackingSection(title: "완료/기타", snapshots: completed)
        ].filter { !$0.snapshots.isEmpty }
    }

    private func makeHomeDashboard(
        selectedDateBills: [BillSnapshot],
        lawEnforcements: [LawEnforcementSnapshot],
        failedSections: [HomeDashboardSection]
    ) -> HomeDashboard {
        let recentSnapshots = coreDataManager.fetchRecentSnapshots(limit: 500)
        let latestSnapshots = coreDataManager.fetchLatestSnapshots()
        let dashboardSource = recentSnapshots.isEmpty ? selectedDateBills : recentSnapshots
        let todaySnapshots = formatDate(Date()).map { coreDataManager.fetchSnapshots(for: $0) } ?? []
        let newProposalsSource = todaySnapshots.isEmpty ? latestSnapshots : todaySnapshots
        let favorites = coreDataManager.fetchFavoriteSnapshots()
        let matchedLawEnforcements = LawBillMatcher.match(
            lawEnforcements: lawEnforcements,
            bills: Array((dashboardSource + selectedDateBills + latestSnapshots).uniqueByBillID())
        )

        return HomeDashboard(
            newProposals: Array(newProposalsSource.prefix(10)),
            stageChanges: Array(favorites.filter(\.hasUnseenStageChange).prefix(10)),
            hotBills: makeHotBills(from: dashboardSource, limit: 10),
            lawEnforcements: Array(matchedLawEnforcements.prefix(12)),
            selectedDateBills: selectedDateBills,
            updatedAt: Date(),
            isUsingCache: false,
            failedSections: failedSections
        )
    }

    private func makeHotBills(from snapshots: [BillSnapshot], limit: Int) -> [HotBillSnapshot] {
        let favorites = coreDataManager.fetchFavoriteSnapshots()
        let context = HotBillScoringContext(
            recentSearchTerms: RecentSearchManager().load(),
            trackedCommittees: favorites.compactMap(\.committee),
            favoriteBillIDs: Set(favorites.map(\.billID))
        )
        return HotBillScorer.rank(snapshots, limit: limit, context: context)
    }

    private func formatDate(_ date: Date) -> String? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }
}

private extension Array where Element == BillSnapshot {
    func uniqueByBillID() -> [BillSnapshot] {
        var seen = Set<String>()
        return filter { snapshot in
            guard !seen.contains(snapshot.billID) else { return false }
            seen.insert(snapshot.billID)
            return true
        }
    }
}

final class HomeViewModel {
    private let repository: BillRepositoryProtocol
    var onStateChange: ((ViewState<HomeDashboard>) -> Void)?

    init(repository: BillRepositoryProtocol = BillRepository.shared) {
        self.repository = repository
    }

    func load(date: Date) {
        onStateChange?(.loading("오늘의 법안을 불러오는 중입니다."))
        repository.fetchHomeDashboard(date: date) { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dashboard):
                    dashboard.hasVisibleContent
                    ? self?.onStateChange?(.loaded(dashboard))
                    : self?.onStateChange?(.empty("표시할 법안 흐름이 없습니다."))
                case .failure(let error):
                    self?.onStateChange?(.error(error.localizedDescription))
                }
            }
        }
    }

    func refresh() {
        onStateChange?(.loading("대시보드를 새로고침하는 중입니다."))
        repository.refreshHomeDashboard { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let dashboard):
                    dashboard.hasVisibleContent
                    ? self?.onStateChange?(.loaded(dashboard))
                    : self?.onStateChange?(.empty("표시할 법안 흐름이 없습니다."))
                case .failure(let error):
                    self?.onStateChange?(.error(error.localizedDescription))
                }
            }
        }
    }
}

final class SearchViewModel {
    private let repository: BillRepositoryProtocol
    private(set) var filter = BillFilter()
    private(set) var currentPage = 1
    private(set) var canLoadMore = true
    private var isLoading = false
    private var results: [BillSnapshot] = []
    var onStateChange: ((ViewState<[BillSnapshot]>) -> Void)?

    init(repository: BillRepositoryProtocol = BillRepository.shared) {
        self.repository = repository
    }

    func updateFilter(_ filter: BillFilter) {
        self.filter = filter
    }

    func search(query: String? = nil, reset: Bool = true) {
        if let query {
            filter.query = query
        }

        guard !filter.normalizedQuery.isEmpty, !isLoading else { return }

        if reset {
            currentPage = 1
            canLoadMore = true
            results = []
            onStateChange?(.loading("검색 중입니다."))
        }

        isLoading = true
        repository.searchBills(filter: filter, page: currentPage) { [weak self] result in
            guard let self = self else { return }

            DispatchQueue.main.async {
                self.isLoading = false
                switch result {
                case .success(let snapshots):
                    self.canLoadMore = !snapshots.isEmpty
                    let mergedResults = reset ? snapshots : self.mergeUnique(self.results + snapshots)
                    self.results = BillSnapshot.sort(mergedResults, order: self.filter.sortOrder)
                    self.results.isEmpty
                    ? self.onStateChange?(.empty("검색 결과가 없습니다."))
                    : self.onStateChange?(.loaded(self.results))
                case .failure(let error):
                    if reset {
                        self.onStateChange?(.error("검색에 실패했습니다.\n\(error.localizedDescription)"))
                    } else {
                        self.canLoadMore = false
                    }
                }
            }
        }
    }

    func loadNextPageIfNeeded() {
        guard canLoadMore, !isLoading, !filter.normalizedQuery.isEmpty else { return }
        currentPage += 1
        search(reset: false)
    }

    func clearResults() {
        filter.query = ""
        currentPage = 1
        canLoadMore = true
        results = []
        onStateChange?(.idle)
    }

    private func mergeUnique(_ snapshots: [BillSnapshot]) -> [BillSnapshot] {
        var seen = Set<String>()
        return snapshots.filter { snapshot in
            guard !seen.contains(snapshot.billID) else { return false }
            seen.insert(snapshot.billID)
            return true
        }
    }
}

final class FavoritesViewModel {
    private let repository: BillRepository
    var onStateChange: ((ViewState<[BillTrackingSection]>) -> Void)?

    init(repository: BillRepository = .shared) {
        self.repository = repository
    }

    func load(refresh: Bool) {
        onStateChange?(.loading(refresh ? "저장한 법안의 진행 상태를 확인 중입니다." : "저장한 법안을 불러오는 중입니다."))

        let finish: (Result<[BillSnapshot], Error>) -> Void = { [weak self] result in
            DispatchQueue.main.async {
                switch result {
                case .success(let snapshots):
                    let sections = BillRepository.makeTrackingSections(from: snapshots)
                    sections.isEmpty
                    ? self?.onStateChange?(.empty("즐겨찾기한 법안이 없습니다.\n관심 있는 법안의 별을 눌러 저장해보세요."))
                    : self?.onStateChange?(.loaded(sections))
                case .failure(let error):
                    // Offline display is separate from a successful background refresh.
                    let cached = self?.repository.favoriteSnapshots() ?? []
                    if cached.isEmpty {
                        self?.onStateChange?(.error(error.localizedDescription))
                    } else {
                        self?.onStateChange?(.loaded(BillRepository.makeTrackingSections(from: cached)))
                    }
                }
            }
        }

        if refresh {
            repository.refreshFavoriteSnapshots(completion: finish)
        } else {
            finish(.success(repository.favoriteSnapshots()))
        }
    }

    func toggleFavorite(id: String, completion: @escaping () -> Void) {
        repository.toggleFavorite(id: id) { _ in
            DispatchQueue.main.async {
                completion()
            }
        }
    }

    func markStageSeen(id: String) {
        repository.markStageSeen(id: id)
    }
}

final class DetailViewModel {
    private let repository: BillRepositoryProtocol
    private let billID: String
    private let age: Int
    private var currentSnapshot: BillSnapshot?
    var onStateChange: ((ViewState<BillSnapshot>) -> Void)?
    var onSummaryUpdate: ((BillSnapshot) -> Void)?
    var onVoteSummaryUpdate: ((BillVoteSummary?) -> Void)?
    var onRepresentativeUpdate: ((Representative?) -> Void)?

    init(billID: String, age: Int, repository: BillRepositoryProtocol = BillRepository.shared) {
        self.billID = billID
        self.age = age
        self.repository = repository
    }

    func load() {
        if let cached = repository.cachedSnapshot(id: billID) {
            currentSnapshot = cached
            onStateChange?(.loaded(cached))
        } else {
            onStateChange?(.loading("법안 정보를 불러오는 중입니다."))
        }

        repository.fetchDetail(id: billID, age: age) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let snapshot):
                    self.repository.markStageSeen(id: snapshot.billID)
                    var visibleSnapshot = snapshot
                    visibleSnapshot.lastSeenStageKey = snapshot.stageKey
                    self.currentSnapshot = visibleSnapshot
                    self.onStateChange?(.loaded(visibleSnapshot))
                    self.refreshSummaryIfNeeded(snapshot: visibleSnapshot)
                    self.refreshVoteSummary(snapshot: visibleSnapshot)
                    self.refreshRepresentative(snapshot: visibleSnapshot)
                case .failure:
                    self.onStateChange?(.error("법안 정보를 불러오는 데 실패했습니다."))
                }
            }
        }
    }

    func retry() {
        load()
    }

    func toggleFavorite() {
        guard let previousSnapshot = currentSnapshot else { return }

        var optimisticSnapshot = previousSnapshot
        optimisticSnapshot.isFavorite.toggle()
        optimisticSnapshot.favoriteCreatedAt = optimisticSnapshot.isFavorite ? (optimisticSnapshot.favoriteCreatedAt ?? Date()) : nil
        optimisticSnapshot.lastSeenStageKey = optimisticSnapshot.isFavorite ? optimisticSnapshot.stageKey : nil

        currentSnapshot = optimisticSnapshot
        onStateChange?(.loaded(optimisticSnapshot))

        repository.toggleFavorite(id: billID) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let updatedSnapshot):
                    self.currentSnapshot = updatedSnapshot
                    self.onStateChange?(.loaded(updatedSnapshot))
                case .failure:
                    self.currentSnapshot = previousSnapshot
                    self.onStateChange?(.loaded(previousSnapshot))
                }
            }
        }
    }

    private func refreshSummaryIfNeeded(snapshot: BillSnapshot) {
        repository.fetchSummary(for: snapshot) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                if case let .success(updated) = result {
                    self.currentSnapshot = updated
                    self.onSummaryUpdate?(updated)
                }
            }
        }
    }

    private func refreshVoteSummary(snapshot: BillSnapshot) {
        repository.fetchVoteSummary(billID: snapshot.billID, age: snapshot.age) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let summary):
                    self.onVoteSummaryUpdate?(summary)
                case .failure:
                    self.onVoteSummaryUpdate?(nil)
                }
            }
        }
    }

    private func refreshRepresentative(snapshot: BillSnapshot) {
        repository.fetchRepresentative(proposer: snapshot.proposer, age: snapshot.age) { [weak self] result in
            guard let self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let representative):
                    self.onRepresentativeUpdate?(representative)
                case .failure:
                    self.onRepresentativeUpdate?(nil)
                }
            }
        }
    }
}

final class BillsRepository {
    private let billsService = BillsService()
    private let coreDataManager = CoreDataManager.shared
    private var pageIndexByAge: [Int: Int] = [22: 1, 21: 1]
    private var age: Int = 22
    var selectedDate: String?
    
    func fetchBills(for date: Date, isUserSelectingDate: Bool, completion: @escaping (Result<[StarredBill], Error>) -> Void) {
        guard let formattedDate = formatDate(date) else {
            completion(.failure(BillsRepositoryError.dateConversionFailed))
            return
        }
        
        selectedDate = formattedDate
        
        if let cached = fetchCachedBills(for: formattedDate) {
            completion(.success(cached))
            return
        }
        
        fetchBillsFromNetwork(for: date, isUserSelectingDate: isUserSelectingDate, formattedDate: formattedDate, completion: completion)
    }
    
    private func fetchCachedBills(for formattedDate: String) -> [StarredBill]? {
        let cachedBills = coreDataManager.fetchBills(for: formattedDate)
        return cachedBills.isEmpty ? nil : cachedBills
    }

    private func fetchBillsFromNetwork(
        for date: Date,
        isUserSelectingDate: Bool,
        formattedDate: String,
        completion: @escaping (Result<[StarredBill], Error>) -> Void
    ) {
        loadBills { [weak self] result in
            guard let self = self else { return }
            
            switch result {
            case .success(let rows):
                self.processFetchedRows(rows)
                self.handlePagination(rows, for: date) {
                    self.finalizeFetchedBills(for: formattedDate, isUserSelectingDate: isUserSelectingDate, completion: completion)
                }
                
            case .failure(let error):
                if let cached = self.fetchCachedBills(for: formattedDate) {
                    completion(.success(cached))
                } else {
                    completion(.failure(error))
                }
            }
        }
    }

    private func processFetchedRows(_ rows: [Row]) {
        coreDataManager.saveAll(rows)
    }

    private func finalizeFetchedBills(
        for formattedDate: String,
        isUserSelectingDate: Bool,
        completion: @escaping (Result<[StarredBill], Error>) -> Void
    ) {
        var bills = coreDataManager.fetchBills(for: formattedDate)
        
        if !isUserSelectingDate, let latest = getLatestAvailableDate(), bills.isEmpty {
            selectedDate = latest
            bills = coreDataManager.fetchBills(for: latest)
        }
        
        completion(.success(bills))
    }
    
    // API 호출
    private func loadBills(completion: @escaping (Result<[Row], Error>) -> Void) {
        let currentPIndex = pageIndexByAge[age] ?? 1
        billsService.fetchBills(pIndex: currentPIndex, age: age, completion: completion)
    }
    
    
    /// 페이징 처리를 위한 로직: oldestDate를 기준으로 age나 pIndex를 조정
    private func handlePagination(_ rows: [Row], for date: Date, completion: @escaping () -> Void) {
        
        guard let oldestDate = rows.map({ $0.PROPOSE_DT }).min() else {
            completion()
            return
        }
        
        // 2020년 5월 30일 이전 법안은 더 이상 요청하지 않음
        if oldestDate <= "2020-05-30" {
            completion()
            return
        }
        
        // 2024년 5월 30일 이전이면 22대에서 21대로 전환
        if oldestDate <= "2024-05-30" {
            if age == 22 {
                age = 21
                // 재귀적으로 다시 fetch
                fetchBills(for: date, isUserSelectingDate: true) { _ in
                    completion()
                }
                return
            } else if age == 21 {
                age = 22
                fetchBills(for: date, isUserSelectingDate: true) { _ in
                    completion()
                }
                return
            }
        } else {
            pageIndexByAge[age]! += 1
        }
        completion()
    }
    
    private func formatDate(_ date: Date) -> String? {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        guard let year = components.year, let month = components.month, let day = components.day else {
            return nil
        }
        return String(format: "%04d-%02d-%02d", year, month, day)
    }
    
    /// 저장된 법안 중 최신 날짜를 반환
    func getLatestAvailableDate() -> String? {
        return self.coreDataManager.getLastestAvailableDate()
    }
}
