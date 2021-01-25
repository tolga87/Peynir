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
import WebKit

public protocol CacheOperationsManagerInterface: AnyObject {
    func cacheSize() -> Promise<Int>
    func clearCache() -> Promise<Void>
}

public protocol JsonCacheManagerInterface: AnyObject {
    func saveJson(_ json: JSON, key: String) -> Promise<Void>
    func saveObject(_ object: JSONConvertable, key: String) -> Promise<Void>
    func loadJson(key: String) -> Promise<JSON>
    func clearAllJsons() -> Promise<Void>
}

public protocol ImageCacheManagerInterface: AnyObject {
    func saveImage(_ image: UIImage, key: String, group: String?) -> Promise<Void>
    func loadImage(key: String, group: String?) -> Promise<UIImage>
}

typealias WebSnapshot = UIImage
typealias WebSnapshotCacheManagerInterface = ImageCacheManagerInterface

typealias CacheManagerInterface = (JsonCacheManagerInterface & ImageCacheManagerInterface & WebSnapshotCacheManagerInterface & CacheOperationsManagerInterface)

public enum CacheError: Error {
    case unknown
    case dataNotFound
    case invalidImageData
    case couldNotSnapshotWebView
    case couldNotCalculateCacheSize
    case couldNotClearCache
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

    // MARK: - JSON

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

    // MARK: - Data

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

    // MARK: - Image

    public func saveImage(_ image: UIImage, key: String, group: String?) -> Promise<Void> {
        guard let pngData = image.pngData() else {
            return Promise(error: CacheError.invalidImageData)
        }
        return self.saveData(pngData, key: key, group: group)
    }

    public func loadImage(key: String, group: String?) -> Promise<UIImage> {
        return self.loadData(key: key, group: group).compactMap { data in
            return UIImage(data: data, scale: UIScreen.main.scale)
        }
    }

    // MARK: - Cache Operations

    private func documentDirectorySize() -> Promise<Int> {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return Promise(error: CacheError.couldNotCalculateCacheSize)
        }

        guard
            let documentUrls = FileManager.default.enumerator(at: documentDirectoryUrl, includingPropertiesForKeys: nil)?.allObjects as? [URL] else {
            return Promise(error: CacheError.couldNotCalculateCacheSize)
        }

        let sizeGuarantees: [Guarantee<Int>] = documentUrls.lazy.map { (documentUrl: URL) -> Guarantee<Int> in
            // Keep trying to calculate total size even if we can't get size data from some directories.
            return documentUrl.fileSize().recover { error -> Guarantee<Int> in
                return .value(0)
            }
        }

        return when(fulfilled: sizeGuarantees).then { (results: [Int]) -> Promise<Int> in
            let totalSize = results.reduce(0, +)
            if totalSize == 0 {
                return Promise(error: CacheError.couldNotCalculateCacheSize)
            } else {
                return Promise.value(totalSize)
            }
        }
    }

    private func databaseSize() -> Promise<Int> {
        guard let storeUrl = self.managedContext.persistentStoreCoordinator?.persistentStores.first?.url else {
            return Promise(error: CacheError.couldNotCalculateCacheSize)
        }

        return storeUrl.fileSize()
    }

    public func cacheSize() -> Promise<Int> {
        let sizePromises = [self.databaseSize(), self.documentDirectorySize()]

        return when(fulfilled: sizePromises).then { (results: [Int]) -> Promise<Int> in
            let totalSize = results.reduce(0, +)
            if totalSize == 0 {
                return Promise(error: CacheError.couldNotCalculateCacheSize)
            } else {
                return Promise.value(totalSize)
            }
        }
    }

    private func removeFile(at url: URL) -> Promise<Void> {
        return Promise<Void> { seal in
            do {
                try FileManager.default.removeItem(at: url)
                seal.fulfill(())
            } catch {
                logError("Could not remove file at: `\(url.absoluteString)`: \(error)")
                seal.reject(error)
            }
        }
    }

    public func clearCache() -> Promise<Void> {
        // `skipsSubdirectoryDescendants` performs a shallow search;
        // i.e. it'll return only files and folders immediately under the `Documents` folder.
        guard
            let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            let documentUrls = FileManager.default.enumerator(at: documentDirectoryUrl,
                                                              includingPropertiesForKeys: nil,
                                                              options: [.skipsSubdirectoryDescendants])?.allObjects as? [URL] else {
                return Promise(error: CacheError.couldNotClearCache)
        }

        let fileRemovalPromises = documentUrls.map {
            self.removeFile(at: $0)
        }

        // Try to remove all files/folders even if we encounter errors.
        return when(resolved: fileRemovalPromises).then { results -> Promise<Void> in
            let fulfilled = results.filter {
                if case .fulfilled = $0 {
                    return true
                } else {
                    return false
                }
            }

            // Consider it a success if we have at least one successful removal.
            if fulfilled.count > 0 {
                return Promise.value(())
            } else {
                return Promise(error: CacheError.couldNotClearCache)
            }
        }
    }
}

private extension URL {
    func fileSize() -> Promise<Int> {
        return Promise<Int> { seal in
            do {
                let resourceValues = try self.resourceValues(forKeys: [.totalFileAllocatedSizeKey, .fileAllocatedSizeKey])
                guard let size = resourceValues.totalFileAllocatedSize ?? resourceValues.fileAllocatedSize else {
                    seal.reject(CacheError.couldNotCalculateCacheSize)
                    return
                }
                seal.fulfill(size)
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
