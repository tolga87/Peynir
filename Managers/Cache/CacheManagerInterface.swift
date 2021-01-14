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

    func saveData(_ data: Data, key: String, group: String?) -> Promise<Void>
    func loadData(key: String, group: String?) -> Promise<Data>
}

public enum CacheError: Error {
    case unknown
    case dataNotFound
    case other(String)
}

// TODO: Add assertions to make sure we're not passing format characters without arguments.
public class CacheManager: CacheManagerInterface {
    static let sharedInstance = CacheManager()

    private let managedContext: NSManagedObjectContext

    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.managedContext = appDelegate.persistentContainer.viewContext
    }

    public func saveJson(_ json: JSON, key: String) -> Promise<Void> {
        return Promise<Void> { seal in
            self.checkCacheRecordId(key)

            guard let entity = NSEntityDescription.entity(forEntityName: Consts.jsonObjectEntityName, in: self.managedContext) else {
                seal.reject(CacheError.other("Invalid CoreData entity"))
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
                seal.reject(CacheError.other("Could not save CoreData object"))
            }
        }
    }

    public func saveObject(_ object: JSONConvertable, key: String) -> Promise<Void> {
        self.checkCacheRecordId(key)

        guard let json = object.toJson() else {
            return Promise(error: CacheError.other("Could not save CoreData object"))
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
                    seal.reject(CacheError.other("Could not convert string to JSON"))
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

    public func saveData(_ data: Data, key: String, group: String? = nil) -> Promise<Void> {
        return Promise<Void> { seal in
            if let group = group {
                self.createGroupIfNecessary(group)
            }

            guard let fileUrl = self.fileUrlForData(withKey: key, group: group) else {
                seal.reject(CacheError.unknown)
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try data.write(to: fileUrl, options: .atomic)
                } catch {
                    seal.reject(error)
                }
                seal.fulfill(())
            }
        }
    }

    public func loadData(key: String, group: String? = nil) -> Promise<Data> {
        return Promise<Data> { seal in
            if let group = group {
                self.createGroupIfNecessary(group)
            }

            guard let fileUrl = self.fileUrlForData(withKey: key, group: group) else {
                seal.reject(CacheError.unknown)
                return
            }

            let data = FileManager.default.contents(atPath: fileUrl.path)
            if let data = data {
                seal.fulfill(data)
            } else {
                seal.reject(CacheError.dataNotFound)
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

    func createGroupIfNecessary(_ groupId: String) {
        guard let groupUrl = self.fileUrlForData(withKey: groupId, group: nil) else { return }
        if FileManager.default.fileExists(atPath: groupUrl.absoluteString) {
            return
        }

        try? FileManager.default.createDirectory(at: groupUrl, withIntermediateDirectories: true, attributes: nil)
    }

    func fileUrlForData(withKey key: String, group: String?) -> URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }

        if let group = group, group.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines).count > 0 {
            return documentDirectoryUrl.appendingPathComponent(group).appendingPathComponent(key)
        } else {
            return documentDirectoryUrl.appendingPathComponent(key)
        }
    }
}
