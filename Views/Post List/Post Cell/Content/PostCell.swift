//
//  PostCell.swift
//  Peynir
//
//  Created by tolga on 12/29/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit
import WebKit
import PromiseKit

protocol PostCellDelegate: class {
    func postCellDidResize(_ cell: PostCell)
}

protocol PostCellViewModelInterface {
    var name: String { get }
    var username: String { get }
    var avatarTemplate: String { get }
    var createdAt: String { get }
    var postContent: String { get }
    var cacheKey: String { get }
}

class PostCell: UITableViewCell {
    static let reuseIdentifier = "PostCellReuseIdentifier"
    weak var delegate: PostCellDelegate?
    weak var cacheManager: WebCacheManagerInterface?

    var viewModel: PostCellViewModelInterface? {
        didSet {
            self.setupViews()
        }
    }

    private var htmlContent: String {
        let postContent = self.viewModel?.postContent ?? ""

        return """
            <html>
                <head>
                    <style>
                        @media (prefers-color-scheme: dark) {
                            body {
                                background-color: rgb(38,38,41);
                                color: white;
                            }
                            a:link {
                                color: #0096e2;
                            }
                            a:visited {
                                color: #9d57df;
                            }
                        }
                    </style>
                </head>
            <body>
            \(postContent)
            </body>
            </html>
        """
    }

    private var postMetadataView: PostMetadataView?
    private var postMetadataContainerView: UIView!
    private var postMetadataHeightConstraint: NSLayoutConstraint!

    private var postContentView: PostContentView!

    private lazy var spinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .medium)
        spinner.translatesAutoresizingMaskIntoConstraints = false
        spinner.hidesWhenStopped = true
        return spinner
    }()

    private lazy var webViewConfig: WKWebViewConfiguration = {

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

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.setupViews()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resetContent() {
        self.setupViews()
    }

    private func setupViews() {
        self.postMetadataContainerView?.removeFromSuperview()
        self.postMetadataContainerView = UIView()
        self.postMetadataContainerView.translatesAutoresizingMaskIntoConstraints = false
        self.contentView.addSubview(self.postMetadataContainerView)

        self.postMetadataContainerView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        self.postMetadataContainerView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        self.postMetadataContainerView.topAnchor.constraint(equalTo: self.contentView.topAnchor).isActive = true

        if let viewModel = self.viewModel {
            let postMetadataViewModel = PostMetadataViewModel(name: viewModel.name,
                                                              username: viewModel.username,
                                                              avatarTemplate: viewModel.avatarTemplate,
                                                              createdAt: viewModel.createdAt)
            let postMetadataView = PostMetadataView(height: Consts.postMetadataHeight, viewModel: postMetadataViewModel)
            postMetadataView.translatesAutoresizingMaskIntoConstraints = false

            self.postMetadataContainerView.addSubview(postMetadataView)
            postMetadataView.constrainToEdges(ofView: self.postMetadataContainerView)
            self.postMetadataHeightConstraint = self.postMetadataContainerView.heightAnchor.constraint(equalToConstant: Consts.postMetadataHeight)
        } else {
            self.postMetadataHeightConstraint = self.postMetadataContainerView.heightAnchor.constraint(equalToConstant: 0)
        }

        self.postMetadataHeightConstraint.isActive = true

        self.postContentView?.navigationDelegate = nil
        self.postContentView?.removeFromSuperview()
        self.postContentView = PostContentView(frame: .zero, configuration: self.webViewConfig)
        self.postContentView.scrollView.isScrollEnabled = false
        self.postContentView.translatesAutoresizingMaskIntoConstraints = false
        self.postContentView.htmlString = self.htmlContent
        self.contentView.addSubview(self.postContentView)

        self.postContentView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        self.postContentView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        self.postContentView.topAnchor.constraint(equalTo: self.postMetadataContainerView.bottomAnchor).isActive = true
        self.postContentView.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor).isActive = true

        self.spinner.removeFromSuperview()
        self.postContentView.addSubview(self.spinner)
        self.spinner.constrainToCenter(ofView: self.postContentView)
        self.spinner.startAnimating()

        self.postContentView.navigationDelegate = self

        self.postContentView.contentHeight.addObserver { [weak self] in
            guard let self = self else { return }

            self.delegate?.postCellDidResize(self)

            if let viewModel = self.viewModel {
                let _ = self.cacheManager?.save(webView: self.postContentView, key: viewModel.cacheKey)
            }
        }
    }
}

extension PostCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.spinner.stopAnimating()

//        guard let viewModel = self.viewModel else { return }

//        DispatchQueue.main.asyncAfter(deadline: .now()) {
//            let _ = self.cacheManager?.save(webView: self.postContentView, key: viewModel.cacheKey)
//        }
    }
}

private extension PostCell {
    struct Consts {
        static let postMetadataHeight: CGFloat = 60
    }
}
