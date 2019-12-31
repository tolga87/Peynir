//
//  DataCacheManager.swift
//  Peynir
//
//  Created by tolga on 12/30/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

typealias DataCacheSaveCallback = (Error?) -> Void
typealias DataCacheLoadCallback = (Result<Data, Error>) -> Void

protocol DataCacheManagerInterface {
    func saveData(_ data: Data, withKey key: String, completion: DataCacheSaveCallback?)
    func loadData(withKey key: String, completion: DataCacheLoadCallback?)
}

enum DataCacheError: Error {
    case unknown
    case dataNotFound
}

class DataCacheManager: DataCacheManagerInterface {
    static let sharedInstance = DataCacheManager()

    func saveData(_ data: Data, withKey key: String, completion: DataCacheSaveCallback?) {
        guard let fileUrl = self.fileUrlForData(withKey: key) else {
            DispatchQueue.main.async { completion?(DataCacheError.unknown) }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            do {
                try data.write(to: fileUrl, options: .atomic)
            } catch {
                DispatchQueue.main.async { completion?(error) }
            }
            DispatchQueue.main.async { completion?(nil) }
        }
    }

    func loadData(withKey key: String, completion: DataCacheLoadCallback?) {
        guard let fileUrl = self.fileUrlForData(withKey: key) else {
            DispatchQueue.main.async { completion?(.failure(DataCacheError.unknown)) }
            return
        }

        DispatchQueue.global(qos: .userInitiated).async {
            let data = FileManager.default.contents(atPath: fileUrl.path)
            DispatchQueue.main.async {
                if let data = data {
                    completion?(.success(data))
                } else {
                    completion?(.failure(DataCacheError.dataNotFound))
                }
            }
        }
    }
}

private extension DataCacheManager {
    func fileUrlForData(withKey key: String) -> URL? {
        guard let documentDirectoryUrl = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            return nil
        }
        return documentDirectoryUrl.appendingPathComponent(key)
    }
}
