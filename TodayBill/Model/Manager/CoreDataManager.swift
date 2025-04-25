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
    
    private init() {}
    
    private lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "BillEntity")
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("CoreData 초기화 실패 \(error)")
            }
        }
        return container
    }()
    
    var context: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    func saveAll(_ bills: [BillEntity]) {
        let existingIDs = fetchExistingBillIDs()
        let newBills = bills.filter{
            !existingIDs.contains($0.id ?? "")
        }
        
        for bill in newBills {
            let entity = BillEntity(context: context)
            entity.id = bill.id
            entity.title = bill.title
            entity.date = bill.date
            entity.age = bill.age
        }
        
        do {
            try context.save()
        } catch {
            print("Core Data 저장 실패")
        }
    }
    
    func fetchBills(for date: String) -> [StarredBill] {
        let request = BillEntity.fetchRequest()        
        request.predicate = NSPredicate(format: "date == %@", date)
        
        do {
            let result = try context.fetch(request)
            return result.map{
                StarredBill(ID: $0.id ?? "", age: Int($0.age), name: $0.title ?? "")
            }
        } catch {
            print("CoreData fetch 실패: \(error)")
            return []
        }
    }
    
    func getLastestAvailableDate() -> String? {
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
}
