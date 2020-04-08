//
//  PostContentView.swift
//  Peynir
//
//  Created by tolga on 12/29/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation
import WebKit

class PostContentView: WKWebView {
    var contentHeight: Observable<CGFloat> = Observable(44)

    var htmlString: String = "" {
        didSet {
            self.loadHTMLString(self.htmlString, baseURL: nil)
        }
    }

    private var postHeightConstraint: NSLayoutConstraint?

    override init(frame: CGRect, configuration: WKWebViewConfiguration) {
        super.init(frame: frame, configuration: configuration)

        self.addObserver(self, forKeyPath: Consts.contentSizeKeyPath, options: .new, context: nil)
        self.contentHeight.addObserver { [weak self] in
            self?.setNeedsUpdateConstraints()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        self.removeObserver(self, forKeyPath: Consts.contentSizeKeyPath, context: nil)
    }

    override func updateConstraints() {
        if let constraint = self.postHeightConstraint {
            constraint.constant = self.contentHeight.value
        } else {
            let constraint = self.heightAnchor.constraint(equalToConstant: self.contentHeight.value)
            constraint.priority = .defaultLow
            constraint.isActive = true
            self.postHeightConstraint = constraint
        }

        super.updateConstraints()
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        guard
            let keyPath = keyPath,
            keyPath == Consts.contentSizeKeyPath,
            let contentSize = change?[.newKey] as? CGSize else {
                return
        }

        let newHeight = contentSize.height
        if newHeight != self.contentHeight.value {
            self.contentHeight.value = newHeight
        }
    }
}

private extension PostContentView {
    struct Consts {
        static let contentSizeKeyPath = "scrollView.contentSize"
    }
}
