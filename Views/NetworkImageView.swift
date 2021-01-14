//
//  NetworkImageView.swift
//  Peynir
//
//  Created by tolga on 12/30/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit
import PromiseKit

enum NetworkImageViewError: Error {
    case badImageData
}

class NetworkImageView: UIView {
    private let cacheManager: CacheManagerInterface
    private let networkManager: NetworkManagerInterface

    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()

    init(url: String, fileName: String, cacheManager: CacheManagerInterface = CacheManager.sharedInstance, networkManager: NetworkManagerInterface = NetworkManager.sharedInstance) {
        self.cacheManager = cacheManager
        self.networkManager = networkManager

        super.init(frame: .zero)

        self.addSubview(self.imageView)
        self.imageView.constrainToEdges(ofView: self)

        self.imageView.addSubview(self.spinner)
        self.spinner.constrainToCenter(ofView: self.imageView)

        self.spinner.startAnimating()

        firstly {
            cacheManager.loadData(key: fileName, group: nil)
        }.done(on: .main) {
            guard let image = UIImage(data: $0) else {
                logError("Could not convert image date to UIImage")
                return
            }

            self.setImage(image)
        }.catch { _ in
            logDebug("Could not find image in cache. Starting download from `\(url)`")
            self.downloadAndSetImage(fromUrl: url, fileName: fileName)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension NetworkImageView {
    func setImage(_ image: UIImage) {
        self.imageView.image = image
        self.spinner.stopAnimating()
    }

    func downloadAndSetImage(fromUrl url: String, fileName: String) {
        firstly {
            self.networkManager.getData(atUrl: url)
        }.done(on: .main) { imageData in
            guard let image = UIImage(data: imageData) else {
                throw NetworkImageViewError.badImageData
            }

            self.setImage(image)
            _ = self.cacheManager.saveData(imageData, key: fileName, group: nil)
        }.catch { error in
            logError("Could not download image from `\(url): \(error)`")
        }
    }
}
