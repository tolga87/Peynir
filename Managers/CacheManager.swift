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

    var keys: CacheKeys { get }
}

public enum CacheError: Error {
    case unknown(String)
}

public struct CacheKeys {
    public let categoryListKey = "categories.json"
    public let topicListKey = "c/%@.json"
}

public class CacheManager: CacheManagerInterface {
    private let managedContext: NSManagedObjectContext

    public let keys = CacheKeys()

    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.managedContext = appDelegate.persistentContainer.viewContext
    }

    public func save(json: JSON, withId id: String) -> CacheError? {
        guard let entity = NSEntityDescription.entity(forEntityName: "JSONObject", in: self.managedContext) else {
            return CacheError.unknown("Invalid CoreData entity")
        }

        let managedArticleObject = NSManagedObject(entity: entity, insertInto: self.managedContext)
        managedArticleObject.setValue(id, forKey: "id")
        managedArticleObject.setValue(json.toString(), forKey: "value")

        do {
            try self.managedContext.save()
        } catch {
            return .unknown("Could not save CoreData object")
        }

        return nil
    }

    public func save(object: JSONConvertable, withId id: String) -> CacheError? {
        guard let json = object.toJson() else {
            return .unknown("Could not save CoreData object")
        }

        return self.save(json: json, withId: id)
    }

    public func loadJson(withId id: String) -> Result<JSON, Error> {
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "JSONObject")
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
}
