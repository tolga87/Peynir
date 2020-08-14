//
//  WebCacheManager.swift
//  Peynir
//
//  Created by tolga on 7/26/20.
//  Copyright © 2020 Tolga AKIN. All rights reserved.
//

import PromiseKit
import WebKit

protocol WebCacheManagerInterface: class {
    func save(webView: WKWebView, key: String) -> Promise<Void>
    func load(withKey key: String) -> Promise<UIImage>
}

enum WebCacheManagerError: Error {
    case couldNotSnapshotWebView
    case couldNotConvertImageToPng
    case couldNotConvertDataToImage
}

class WebCacheManager: WebCacheManagerInterface {
    private let dataCacheManager: DataCacheManagerInterface

    init(dataCacheManager: DataCacheManagerInterface) {
        self.dataCacheManager = dataCacheManager
    }

    // MARK: - WebCacheManagerInterface

    func save(webView: WKWebView, key: String) -> Promise<Void> {
        return self.save(webView: webView, key: key, fileExtension: "png")
    }

    func load(withKey key: String) -> Promise<UIImage> {
        return self.load(withKey: key, fileExtension: "png")
    }
}

private extension WebCacheManager {
    func save(webView: WKWebView, key: String, fileExtension: String) -> Promise<Void> {
        return Promise<Void> { seal in
            webView.takeSnapshot(with: nil) { (image, error) in
                guard let image = image else {
                    let error = error ?? WebCacheManagerError.couldNotSnapshotWebView
                    seal.reject(error)
                    return
                }

                let key = "\(key)_\(webView.frame.width)x\(webView.frame.height).\(fileExtension)"
                guard let pngData = image.pngData() else {
                    seal.reject(WebCacheManagerError.couldNotConvertImageToPng)
                    return
                }

                firstly {
                    self.dataCacheManager.saveData(pngData, withKey: key, group: "snapshots")
                }.done {
                    seal.fulfill(())
                }.catch { error in
                    seal.reject(error)
                }
            }
        }
    }

    func load(withKey key: String, fileExtension: String) -> Promise<UIImage> {
        return Promise<UIImage> { seal in
            firstly {
                self.dataCacheManager.loadData(withKey: "\(key).\(fileExtension)")
            }.done {
                guard let image = UIImage(data: $0) else {
                    seal.reject(WebCacheManagerError.couldNotConvertDataToImage)
                    return
                }
                seal.fulfill(image)
            }.catch { error in
                seal.reject(error)
            }
        }
    }
}
