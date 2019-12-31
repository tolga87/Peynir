//
//  PostContentView.swift
//  Peynir
//
//  Created by tolga on 12/29/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation
import WebKit

// TODO(tolga): Rework this.
class PostContentView: WKWebView {
    var htmlString: String = "" {
        didSet {
            self.loadHTMLString(self.htmlString, baseURL: nil)
        }
    }
}
