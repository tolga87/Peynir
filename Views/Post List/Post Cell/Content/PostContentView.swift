//
//  PostContentView.swift
//  Peynir
//
//  Created by tolga on 12/29/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation
import PromiseKit

class PostContentView: UIView {
    private let snapshotView: UIImageView
    private let imageHeightConstraint: NSLayoutConstraint
    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()

    var snapshotImagePromise: Promise<UIImage>? {
        didSet {
            guard let promise = snapshotImagePromise else { return }
            if self.snapshotView.image != nil { return }

            self.spinner.startAnimating()

            firstly {
                promise
            }.done { image in
                self.imageHeightConstraint.constant = image.size.height
                self.snapshotView.image = image
                self.contentSizeChangeCallback?(image.size)
            }.catch { error in
                // TODO: Show error in the UI.
                logError("Could not get web snapshot in PostContentView. Error: \(error)")
            }.finally {
                self.spinner.stopAnimating()
            }
        }
    }
    var contentSizeChangeCallback: ((CGSize) -> Void)?
    
    override init(frame: CGRect) {
        self.snapshotView = UIImageView(image: nil)
        self.snapshotView.translatesAutoresizingMaskIntoConstraints = false
        self.imageHeightConstraint = self.snapshotView.heightAnchor.constraint(equalToConstant: Consts.defaultPostHeight)
        self.imageHeightConstraint.priority = UILayoutPriority.defaultHigh
        
        super.init(frame: frame)
        
        self.translatesAutoresizingMaskIntoConstraints = false
        self.addSubview(self.snapshotView)
        self.addSubview(self.spinner)
        
        self.snapshotView.leadingAnchor.constraint(equalTo: self.leadingAnchor).isActive = true
        self.snapshotView.trailingAnchor.constraint(equalTo: self.trailingAnchor).isActive = true
        self.snapshotView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        self.snapshotView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true

        self.spinner.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        self.spinner.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true

        self.imageHeightConstraint.isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension PostContentView {
    struct Consts {
        static let defaultPostHeight: CGFloat = 44.0
    }
}
