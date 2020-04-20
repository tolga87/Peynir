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
    func saveData(_ data: Data, withKey key: String) -> Promise<Void>
    func loadData(withKey key: String) -> Promise<Data>
}

enum DataCacheError: Error {
    case unknown
    case dataNotFound
}

class DataCacheManager: DataCacheManagerInterface {
    static let sharedInstance = DataCacheManager()

    func saveData(_ data: Data, withKey key: String) -> Promise<Void> {
        return Promise<Void> { seal in
            guard let fileUrl = self.fileUrlForData(withKey: key) else {
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

    func loadData(withKey key: String) -> Promise<Data> {
        return Promise<Data> { seal in
            guard let fileUrl = self.fileUrlForData(withKey: key) else {
                seal.reject(DataCacheError.unknown)
                return
            }

            DispatchQueue.global(qos: .userInitiated).async {
                let data = FileManager.default.contents(atPath: fileUrl.path)
                DispatchQueue.main.async {
                    if let data = data {
                        seal.fulfill(data)
                    } else {
                        seal.reject(DataCacheError.dataNotFound)
                    }
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
