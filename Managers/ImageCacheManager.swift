//
//  ImageCacheManager.swift
//  Peynir
//
//  Created by Tolga AKIN on 8/16/20.
//  Copyright © 2020 Tolga AKIN. All rights reserved.
//

import Foundation
import PromiseKit

enum CachedImageResult {
    case notCached
    case cached(UIImage)
}

enum ImageCachingError: Error {
    case invalidImageData
}

protocol ImageCacheManagerInterface {
    func saveImage(image: UIImage, withKey key: String, group: String?) -> Promise<Void>
    func loadImage(withKey key: String, group: String?) -> Guarantee<CachedImageResult>
}

class ImageCacheManager: ImageCacheManagerInterface {
    static let sharedInstance = ImageCacheManager(dataCacheManager: DataCacheManager.sharedInstance)
    
    private let dataCacheManager: DataCacheManagerInterface
    
    init(dataCacheManager: DataCacheManagerInterface) {
        self.dataCacheManager = dataCacheManager
    }

    @discardableResult
    func saveImage(image: UIImage, withKey key: String, group: String?) -> Promise<Void> {
        guard let pngData = image.pngData() else {
            return Promise(error: ImageCachingError.invalidImageData)
        }
        return self.dataCacheManager.saveData(pngData, withKey: key, group: "snapshots")
    }
    
    func loadImage(withKey key: String, group: String?) -> Guarantee<CachedImageResult> {
        return self.dataCacheManager.loadData(withKey: key, group: group).map { data in
            if let image = UIImage(data: data, scale: UIScreen.main.scale) {
                return CachedImageResult.cached(image)
            } else {
                return CachedImageResult.notCached
            }
        }.recover { error -> Guarantee<CachedImageResult> in
            return Guarantee.value(CachedImageResult.notCached)
        }
    }
}
