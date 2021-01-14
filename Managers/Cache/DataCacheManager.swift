//
//  DataCacheManager.swift
//  Peynir
//
//  Created by tolga on 12/30/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit
import PromiseKit

protocol DataCacheManagerInterface {
    func saveData(_ data: Data, withKey key: String, group: String?) -> Promise<Void>
    func loadData(withKey key: String, group: String?) -> Promise<Data>
}

extension DataCacheManagerInterface {
    func saveData(_ data: Data, withKey key: String) -> Promise<Void> {
        return self.saveData(data, withKey: key, group: nil)
    }
    
    func loadData(withKey key: String) -> Promise<Data> {
        return self.loadData(withKey: key, group: nil)
    }
}

enum DataCacheError: Error {
    case unknown
    case dataNotFound
}

class DataCacheManager: DataCacheManagerInterface {
    static let sharedInstance = DataCacheManager()

    @discardableResult
    func saveData(_ data: Data, withKey key: String, group: String? = nil) -> Promise<Void> {
        return Promise<Void> { seal in
            if let group = group {
                self.createGroupIfNecessary(group)
            }

            guard let fileUrl = self.fileUrlForData(withKey: key, group: group) else {
                seal.reject(DataCacheError.unknown)
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

    func loadData(withKey key: String, group: String?) -> Promise<Data> {
        return Promise<Data> { seal in
            if let group = group {
                self.createGroupIfNecessary(group)
            }

            guard let fileUrl = self.fileUrlForData(withKey: key, group: group) else {
                seal.reject(DataCacheError.unknown)
                return
            }

            let data = FileManager.default.contents(atPath: fileUrl.path)
            if let data = data {
                seal.fulfill(data)
            } else {
                seal.reject(DataCacheError.dataNotFound)
            }
        }
    }
}

private extension DataCacheManager {
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
