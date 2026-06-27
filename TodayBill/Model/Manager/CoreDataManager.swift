//
//  CoreDataManager.swift
//  TodayBill
//
//  Created by 김건호 on 4/24/25.
//

import CoreData
import Foundation

final class CoreDataManager {
    static let shared = CoreDataManager()
    
    private let persistentContainer: NSPersistentContainer
    
    private init() {
        let container = NSPersistentContainer(name: "BillEntity")
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        CoreDataManager.loadPersistentStores(for: container)
        self.persistentContainer = container
    }
    
    private init(container: NSPersistentContainer) {
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        self.persistentContainer = container
    }
    
    static func makeInMemory() -> CoreDataManager {
        let container = NSPersistentContainer(name: "BillEntity")
        let description = NSPersistentStoreDescription()
        description.type = NSInMemoryStoreType
        container.persistentStoreDescriptions = [description]
        loadPersistentStores(for: container)
        return CoreDataManager(container: container)
    }
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveAll(_ rows: [Row]) {
        saveSnapshots(rows.map(BillSnapshot.init(row:)))
    }

    func saveSnapshots(_ snapshots: [BillSnapshot]) {
        guard !snapshots.isEmpty else { return }

        performContext {
            snapshots.forEach { snapshot in
                let entity = entity(for: snapshot.billID) ?? BillEntity(context: context)
                entity.apply(snapshot: snapshot)
            }

            saveContext()
        }
    }
    
    func fetchBills(for date: String) -> [StarredBill] {
        fetchSnapshots(for: date).map { $0.toStarredBill() }
    }

    func fetchSnapshots(for date: String) -> [BillSnapshot] {
        performContext {
            let request = BillEntity.fetchRequest()
            request.predicate = NSPredicate(format: "date == %@", date)
            request.sortDescriptors = [
                NSSortDescriptor(key: "date", ascending: false),
                NSSortDescriptor(key: "title", ascending: true)
            ]

            do {
                let result = try context.fetch(request)
                return result.map(BillSnapshot.init(entity:))
            } catch {
                print("CoreData fetch 실패: \(error)")
                return []
            }
        }
    }

    func fetchSnapshot(id: String) -> BillSnapshot? {
        performContext {
            entity(for: id).map(BillSnapshot.init(entity:))
        }
    }

    func fetchLatestSnapshots() -> [BillSnapshot] {
        guard let latestDate = getLastestAvailableDate() else { return [] }
        return fetchSnapshots(for: latestDate)
    }

    func fetchRecentSnapshots(limit: Int = 300) -> [BillSnapshot] {
        performContext {
            let request = BillEntity.fetchRequest()
            request.sortDescriptors = [
                NSSortDescriptor(key: "date", ascending: false),
                NSSortDescriptor(key: "updatedAt", ascending: false),
                NSSortDescriptor(key: "title", ascending: true)
            ]
            request.fetchLimit = limit

            do {
                return try context.fetch(request).map(BillSnapshot.init(entity:))
            } catch {
                print("최근 법안 fetch 실패: \(error)")
                return []
            }
        }
    }

    func searchSnapshots(filter: BillFilter) -> [BillSnapshot] {
        performContext {
            let request = BillEntity.fetchRequest()
            request.sortDescriptors = [NSSortDescriptor(key: "date", ascending: filter.sortOrder == .oldest)]

            do {
                let snapshots = try context.fetch(request).map(BillSnapshot.init(entity:))
                let filtered = snapshots.filter { $0.matches(filter: filter) }
                return BillSnapshot.sort(filtered, order: filter.sortOrder)
            } catch {
                print("CoreData search 실패: \(error)")
                return []
            }
        }
    }

    func fetchFavoriteSnapshots() -> [BillSnapshot] {
        performContext {
            let request = BillEntity.fetchRequest()
            request.predicate = NSPredicate(format: "isFavorite == YES")
            request.sortDescriptors = [
                NSSortDescriptor(key: "favoriteCreatedAt", ascending: false),
                NSSortDescriptor(key: "updatedAt", ascending: false)
            ]

            do {
                return try context.fetch(request).map(BillSnapshot.init(entity:))
            } catch {
                print("즐겨찾기 fetch 실패: \(error)")
                return []
            }
        }
    }

    @discardableResult
    func toggleFavorite(id: String) -> BillSnapshot? {
        performContext {
            guard let entity = entity(for: id) else { return nil }
            let nextValue = !entity.isFavorite
            entity.isFavorite = nextValue
            entity.favoriteCreatedAt = nextValue ? (entity.favoriteCreatedAt ?? Date()) : nil
            let snapshot = BillSnapshot(entity: entity)
            entity.lastSeenStageKey = nextValue ? snapshot.stageKey : nil
            saveContext()
            return BillSnapshot(entity: entity)
        }
    }

    @discardableResult
    func setFavorite(snapshot: BillSnapshot, isFavorite: Bool) -> BillSnapshot {
        performContext {
            let entity = entity(for: snapshot.billID) ?? BillEntity(context: context)
            entity.apply(snapshot: snapshot)
            entity.isFavorite = isFavorite
            entity.favoriteCreatedAt = isFavorite ? (entity.favoriteCreatedAt ?? Date()) : nil
            entity.lastSeenStageKey = isFavorite ? BillSnapshot(entity: entity).stageKey : nil
            saveContext()
            return BillSnapshot(entity: entity)
        }
    }

    func markStageSeen(id: String) {
        performContext {
            guard let entity = entity(for: id) else { return }
            entity.lastSeenStageKey = BillSnapshot(entity: entity).stageKey
            saveContext()
        }
    }

    func updateSummary(id: String, summary: BillSummary) -> BillSnapshot? {
        performContext {
            guard let entity = entity(for: id) else { return nil }
            entity.summaryProposalReason = summary.proposalReason
            entity.summaryKeyContent = summary.keyContent
            entity.summaryFetchedAt = Date()
            entity.updatedAt = Date()
            saveContext()
            return BillSnapshot(entity: entity)
        }
    }

    func migrateUserDefaultsFavorites(_ starredBills: [StarredBill]) {
        guard !starredBills.isEmpty else { return }

        performContext {
            starredBills.forEach { bill in
                let entity = entity(for: bill.ID) ?? BillEntity(context: context)
                if entity.id == nil {
                    let snapshot = BillSnapshot(
                        billID: bill.ID,
                        age: bill.age,
                        title: bill.name,
                        isFavorite: true,
                        favoriteCreatedAt: Date()
                    )
                    entity.apply(snapshot: snapshot, preservingUserFields: false)
                }
                entity.isFavorite = true
                entity.favoriteCreatedAt = entity.favoriteCreatedAt ?? Date()
                entity.lastSeenStageKey = BillSnapshot(entity: entity).stageKey
            }

            saveContext()
        }
    }
    
    func getLastestAvailableDate() -> String? {
        performContext {
            let request = BillEntity.fetchRequest()
            let sortDescriptior = NSSortDescriptor(key: "date" , ascending: false)
            request.sortDescriptors = [sortDescriptior]
            request.fetchLimit = 1

            do {
                if let entity = try context.fetch(request).first {
                    return entity.date
                }
            } catch {
                print("최신 날짜 가져오기 실패")
            }
            return nil
        }
    }
    
    private func fetchExistingBillIDs() -> Set<String> {
        let request = NSFetchRequest<NSDictionary>(entityName: "BillEntity")
        request.resultType = .dictionaryResultType
        request.propertiesToFetch = ["id"]
        
        do {
            let results = try context.fetch(request)
            let ids = results.compactMap { $0["id"] as? String }
            return Set(ids)
        } catch {
            print("기존 ID 불러오기 실패: \(error)")
            return []
        }
    }

    private func entity(for id: String) -> BillEntity? {
        let request = BillEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1

        do {
            return try context.fetch(request).first
        } catch {
            print("BillEntity fetch 실패: \(error)")
            return nil
        }
    }

    private func saveContext() {
        guard context.hasChanges else { return }

        do {
            try context.save()
        } catch {
            context.rollback()
            print("Core Data 저장 실패: \(error)")
        }
    }

    private func performContext<T>(_ work: () -> T) -> T {
        var value: T?
        context.performAndWait {
            value = work()
        }
        return value!
    }
    
    private static func loadPersistentStores(for container: NSPersistentContainer) {
        container.persistentStoreDescriptions.forEach { description in
            description.shouldMigrateStoreAutomatically = true
            description.shouldInferMappingModelAutomatically = true
        }

        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData 초기화 실패 \(error)")
            }
        }
    }
}
