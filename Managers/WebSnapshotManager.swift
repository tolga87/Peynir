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
    func snapshot(withId id: String, htmlString: String, width: CGFloat) -> Promise<UIImage>
}

enum WebSnapshotManagerError: Error {
    case unknown
    case invalidImageData
}

class WebSnapshotManager: WebSnapshotManagerInterface {
    static let sharedInstance = WebSnapshotManager(imageCacheManager: ImageCacheManager.sharedInstance)
    
    private let imageCacheManager: ImageCacheManagerInterface
    private var renderers: [String: SnapshotRenderer] = [:]

    private init(imageCacheManager: ImageCacheManagerInterface) {
        self.imageCacheManager = imageCacheManager
    }
    
    func snapshot(withId id: String, htmlString: String, width: CGFloat) -> Promise<UIImage> {
        let key = WebSnapshotManager.keyForImage(withId: id, width: width)
        
        return firstly {
            self.imageCacheManager.loadImage(withKey: key, group: "snapshots")
        }.then { (result: CachedImageResult) -> Promise<UIImage> in
            switch result {
            case CachedImageResult.cached(let image):
                return .value(image)
                
            case CachedImageResult.notCached:
                var renderer: SnapshotRenderer
                let key = WebSnapshotManager.keyForImage(withId: id, width: width)

                if let r = self.renderers[key] {
                    renderer = r
                } else {
                    renderer = SnapshotRenderer(id: id, htmlString: htmlString, width: width)
                    self.renderers[key] = renderer
                }
                return renderer.loadSnapshot()
            }
        }
    }
    
    static func keyForImage(withId id: String, width: CGFloat) -> String {
        return "\(id)@\(width).png"
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

                if let image = image {
                    let imageKey = WebSnapshotManager.keyForImage(withId: self.id, width: self.width)
                    ImageCacheManager.sharedInstance.saveImage(image: image, withKey: imageKey, group: "snapshots")
                }
            }
    }
    
    struct Consts {
        static let contentSizeKey = "scrollView.contentSize"
    }
}

