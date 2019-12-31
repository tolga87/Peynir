//
//  NetworkImageView.swift
//  Peynir
//
//  Created by tolga on 12/30/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class NetworkImageView: UIView {
    private let cacheManager: DataCacheManagerInterface
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

    init(url: String, fileName: String, cacheManager: DataCacheManagerInterface = DataCacheManager.sharedInstance, networkManager: NetworkManagerInterface = NetworkManager.sharedInstance) {
        self.cacheManager = cacheManager
        self.networkManager = networkManager

        super.init(frame: .zero)

        self.addSubview(self.imageView)
        self.imageView.constrainToEdges(ofView: self)

        self.imageView.addSubview(self.spinner)
        self.spinner.constrainToCenter(ofView: self.imageView)

        self.spinner.startAnimating()

        cacheManager.loadData(withKey: fileName) { result in
            switch result {
            case .failure(let error):
                logDebug("Could not find image in cache. Starting download from `\(url): \(error)`")
                self.downloadAndSetImage(fromUrl: url, fileName: fileName)

            case .success(let imageData):
                guard let image = UIImage(data: imageData) else {
                    logError("Could not convert image date to UIImage")
                    return
                }

                self.setImage(image)
            }
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
        self.networkManager.getData(atUrl: url) { result in
            switch result {
            case .failure(let error):
                logError("Could not download image from `\(url): \(error)`")

            case .success(let imageData):
                guard let image = UIImage(data: imageData) else {
                    logError("Could not convert image date to UIImage")
                    return
                }

                self.setImage(image)
                self.cacheManager.saveData(imageData, withKey: fileName, completion: nil)
            }
        }
    }
}
