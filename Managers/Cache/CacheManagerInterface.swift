//
//  NewCacheManagerInterface.swift
//  Peynir
//
//  Created by Tolga AKIN on 1/14/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import CoreData
import Foundation
import PromiseKit
import UIKit

public protocol CacheManagerInterface {
    func saveJson(_ json: JSON, key: String) -> Promise<Void>
    func saveObject(_ object: JSONConvertable, key: String) -> Promise<Void>
    func loadJson(key: String) -> Promise<JSON>
    func clearAllJsons() -> Promise<Void>
}

public enum CacheError: Error {
    case unknown(String)
}

// TODO: Add assertions to make sure we're not passing format characters without arguments.
public class CacheManager: CacheManagerInterface {
    private let managedContext: NSManagedObjectContext

    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.managedContext = appDelegate.persistentContainer.viewContext
    }

    public func saveJson(_ json: JSON, key: String) -> Promise<Void> {
        return Promise<Void> { seal in
            self.checkCacheRecordId(key)

            guard let entity = NSEntityDescription.entity(forEntityName: Consts.jsonObjectEntityName, in: self.managedContext) else {
                seal.reject(CacheError.unknown("Invalid CoreData entity"))
                return
            }

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Consts.jsonObjectEntityName)
            fetchRequest.predicate = NSPredicate(format: "id == %@", key)

            do {
                let fetchedRecords = try self.managedContext.fetch(fetchRequest)

                // If record exists, update it. Otherwise, create a new record.
                let managedObject = fetchedRecords.first ?? NSManagedObject(entity: entity, insertInto: self.managedContext)

                managedObject.setValue(key, forKey: "id")
                managedObject.setValue(json.toString(), forKey: "value")

                try self.managedContext.save()
                seal.fulfill(())
            } catch {
                seal.reject(CacheError.unknown("Could not save CoreData object"))
            }
        }
    }

    public func saveObject(_ object: JSONConvertable, key: String) -> Promise<Void> {
        self.checkCacheRecordId(key)

        guard let json = object.toJson() else {
            return Promise(error: CacheError.unknown("Could not save CoreData object"))
        }

        return self.saveJson(json, key: key)
    }

    public func loadJson(key: String) -> Promise<JSON> {
        return Promise<JSON> { seal in
            self.checkCacheRecordId(key)

            let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Consts.jsonObjectEntityName)
            fetchRequest.predicate = NSPredicate(format: "id == %@", key)

            var managedObjects: [NSManagedObject] = []
            do {
                managedObjects = try self.managedContext.fetch(fetchRequest)
            } catch {
                // Something bad happened.
                seal.reject(error)
                return
            }

            guard
                let managedObject = managedObjects.first,
                let jsonString = managedObject.value(forKey: "value") as? String,
                let json = jsonString.toJson() else {
                    // Article headers does not exist in cache.
                    seal.reject(CacheError.unknown("Could not convert string to JSON"))
                return
            }

            seal.fulfill(json)
        }
    }

    public func clearAllJsons() -> Promise<Void> {
        return Promise<Void> { seal in
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Consts.jsonObjectEntityName)
            let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

            do {
                try self.managedContext.execute(batchDeleteRequest)
                seal.fulfill(())
            } catch {
                seal.reject(error)
            }
        }
    }
}

private extension CacheManager {
    struct Consts {
        static let jsonObjectEntityName = "JSONObject"
    }

    func checkCacheRecordId(_ id: String) {
        assert(!id.contains("@"), "Cache record ids should not contain format specifiers.")
    }
}
