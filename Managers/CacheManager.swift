//
//  CacheManager.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit
import Foundation
import CoreData

public protocol CacheManagerInterface {
    func save(json: JSON, withId id: String) -> CacheError?
    func save(object: JSONConvertable, withId id: String) -> CacheError?
    func loadJson(withId id: String) -> Result<JSON, Error>
    func clearAllJsons() -> Error?

    var keys: CacheKeys { get }
}

public enum CacheError: Error {
    case unknown(String)
}

public struct CacheKeys {
    public let categoryListKey = "categories.json"
    public let topicListKeyFormat = "c/%d.json"
    public let postListKeyFormat = "t/%d.json"
}

// TODO: Add assertions to make sure we're not passing format characters without arguments.
public class CacheManager: CacheManagerInterface {
    private let managedContext: NSManagedObjectContext

    public let keys = CacheKeys()

    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.managedContext = appDelegate.persistentContainer.viewContext
    }

    public func save(json: JSON, withId id: String) -> CacheError? {
        guard let entity = NSEntityDescription.entity(forEntityName: Consts.jsonObjectEntityName, in: self.managedContext) else {
            return CacheError.unknown("Invalid CoreData entity")
        }

        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Consts.jsonObjectEntityName)
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        do {
            let fetchedRecords = try self.managedContext.fetch(fetchRequest)

            // If record exists, update it. Otherwise, create a new record.
            let managedObject = fetchedRecords.first ?? NSManagedObject(entity: entity, insertInto: self.managedContext)

            managedObject.setValue(id, forKey: "id")
            managedObject.setValue(json.toString(), forKey: "value")

            try self.managedContext.save()
            return nil
        } catch {
            return .unknown("Could not save CoreData object")
        }
    }

    public func save(object: JSONConvertable, withId id: String) -> CacheError? {
        guard let json = object.toJson() else {
            return .unknown("Could not save CoreData object")
        }

        return self.save(json: json, withId: id)
    }

    public func loadJson(withId id: String) -> Result<JSON, Error> {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: Consts.jsonObjectEntityName)
        fetchRequest.predicate = NSPredicate(format: "id == %@", id)

        var managedObjects: [NSManagedObject] = []
        do {
            managedObjects = try self.managedContext.fetch(fetchRequest)
        } catch {
            // Something bad happened.
            return .failure(error)
        }

        guard
            let managedObject = managedObjects.first,
            let jsonString = managedObject.value(forKey: "value") as? String,
            let json = jsonString.toJson() else {
                // Article headers does not exist in cache.
                return .failure(CacheError.unknown("Could not convert string to JSON"))
        }

        return .success(json)
    }

    public func clearAllJsons() -> Error? {
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: Consts.jsonObjectEntityName)
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)

        do {
            try self.managedContext.execute(batchDeleteRequest)
            return nil
        } catch {
            return error
        }
    }
}

private extension CacheManager {
    struct Consts {
        static let jsonObjectEntityName = "JSONObject"
    }
}
