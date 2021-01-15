//
//  WebSnapshotManager.swift
//  Peynir
//
//  Created by Tolga AKIN on 8/15/20.
//  Copyright © 2020 Tolga AKIN. All rights reserved.
//

import PromiseKit
import WebKit

protocol WebSnapshotManagerInterface {
    func snapshot(withId id: String, htmlString: String, width: CGFloat) -> Promise<WebSnapshot>
}

enum WebSnapshotManagerError: Error {
    case unknown
    case invalidImageData
}

class WebSnapshotManager: WebSnapshotManagerInterface {
    private let cacheManager: WebSnapshotCacheManagerInterface
    private var renderers: [String: SnapshotRenderer] = [:]

    init(cacheManager: WebSnapshotCacheManagerInterface) {
        self.cacheManager = cacheManager
    }
    
    func snapshot(withId id: String, htmlString: String, width: CGFloat) -> Promise<WebSnapshot> {
        let key = WebSnapshotManager.keyForImage(withId: id, width: width)

        return firstly {
            self.cacheManager.loadImage(key: key, group: Consts.snapshotFileGroupName)
        }.recover { error -> Promise<UIImage> in
            var renderer: SnapshotRenderer
            let snapshotImageKey = WebSnapshotManager.keyForImage(withId: id, width: width)

            if let r = self.renderers[snapshotImageKey] {
                renderer = r
            } else {
                renderer = SnapshotRenderer(id: id, htmlString: htmlString, width: width)
                self.renderers[key] = renderer
            }

            let loadSnapshotPromise = renderer.loadSnapshot()
            firstly {
                loadSnapshotPromise
            }.then { image in
                // Save newly generated web snapshot to cache
                self.cacheManager.saveImage(image, key: snapshotImageKey, group: Consts.snapshotFileGroupName)
            }.done {
                logDebug("Web snapshot `\(snapshotImageKey)` saved to cache.")
            }.catch { error in
                logDebug("Web snapshot `\(snapshotImageKey)` could not be saved to cache: \(error)")
            }

            return loadSnapshotPromise
        }
    }
    
    static func keyForImage(withId id: String, width: CGFloat) -> String {
        return "\(id)@\(width).png"
    }

    private enum Consts {
        static let snapshotFileGroupName = "snapshots"
    }
}

fileprivate class SnapshotRenderer: NSObject {
    let webView: WKWebView
    let id: String
    let htmlString: String
    let width: CGFloat
    var imageSnapshotCallback: ((UIImage?, Error?) -> Void)?
    var imagePromise: Promise<UIImage>?
    
    private static let webViewConfig: WKWebViewConfiguration = {
        let viewPortScriptSource = """
            var meta = document.createElement('meta');
            meta.setAttribute('name', 'viewport');
            meta.setAttribute('content', 'width=device-width, user-scalable=no');
            document.getElementsByTagName('head')[0].appendChild(meta);
        """
        let viewPortScript = WKUserScript(source: viewPortScriptSource, injectionTime: .atDocumentEnd, forMainFrameOnly: true)

        let userContentController = WKUserContentController()
        userContentController.addUserScript(viewPortScript)

        let config = WKWebViewConfiguration()
        config.userContentController = userContentController
        return config
    }()
    
    init(id: String, htmlString: String, width: CGFloat) {
        self.id = id
        self.htmlString = htmlString
        self.width = width
        self.webView = WKWebView(frame: CGRect(x: 0, y: 0, width: width, height: 0), configuration: SnapshotRenderer.webViewConfig)

        super.init()
        
        self.webView.scrollView.isScrollEnabled = false
        self.webView.isOpaque = false
        self.webView.backgroundColor = .clear
        self.webView.addObserver(self, forKeyPath: Consts.contentSizeKey, options: .new, context: nil)
    }
    
    func loadSnapshot() -> Promise<UIImage> {
        if let imagePromise = self.imagePromise {
            return imagePromise
        }
        
        let imagePromise = Promise<UIImage> { seal in
            self.getSnapshot(withHtmlString: htmlString) { (image, error) in
                if let image = image {
                    seal.fulfill(image)
                } else if let error = error {
                    seal.reject(error)
                } else {
                    seal.reject(WebSnapshotManagerError.unknown)
                }
            }
        }
        self.imagePromise = imagePromise
        return imagePromise
    }
    
    func getSnapshot(withHtmlString htmlString: String, completion: @escaping (UIImage?, Error?) -> Void) {
        self.imageSnapshotCallback = completion

        DispatchQueue.main.async {
            self.webView.loadHTMLString(htmlString, baseURL: nil)
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard
            let contentSize = change?[.newKey] as? CGSize,
            contentSize.width == self.width,
            !self.webView.isLoading else {
                return
        }
        self.webView.removeObserver(self, forKeyPath: Consts.contentSizeKey)

            let snapshotConfig = WKSnapshotConfiguration()
            snapshotConfig.rect = CGRect(origin: .zero, size: contentSize)
            self.webView.takeSnapshot(with: snapshotConfig) { (image, error) in
                DispatchQueue.main.async {
                    self.imageSnapshotCallback?(image, error)
                    self.imageSnapshotCallback = nil
                }
            }
    }
    
    enum Consts {
        static let contentSizeKey = "scrollView.contentSize"
    }
}

