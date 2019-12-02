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
}

public enum CacheError: Error {
    case unknown(String)
}

public class CacheManager: CacheManagerInterface {
    private let managedContext: NSManagedObjectContext

    init() {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        self.managedContext = appDelegate.persistentContainer.viewContext
    }

    public func save(json: JSON, withId id: String) -> CacheError? {
        guard let entity = NSEntityDescription.entity(forEntityName: "JSON", in: self.managedContext) else {
            return CacheError.unknown("Invalid CoreData entity")
        }

        let managedArticleObject = NSManagedObject(entity: entity, insertInto: self.managedContext)
        managedArticleObject.setValue(json.toString(), forKey: "string")

        do {
            try self.managedContext.save()
        } catch {
            return CacheError.unknown("Could not save CoreData object")
        }

        return nil
    }
}
