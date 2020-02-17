//
//  PostCell.swift
//  Peynir
//
//  Created by tolga on 12/29/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit
import WebKit

protocol PostCellDelegate: class {
    func postCellDidResize(_ cell: PostCell)
}

protocol PostCellViewModelInterface {
    var name: String { get }
    var username: String { get }
    var avatarTemplate: String { get }
    var createdAt: String { get }
    var postContent: String { get }
}

class PostCell: UITableViewCell {
    static let reuseIdentifier = "PostCellReuseIdentifier"
    weak var delegate: PostCellDelegate?

    var viewModel: PostCellViewModelInterface? {
        didSet {
            self.setupViews()
        }
    }

    private var htmlContent: String {
        guard let postContent = self.viewModel?.postContent else {
            return ""
        }

        return """
            <html>
                <head>
                    <style>
                        /* TODO: This is not a perfect solution. Find a way to properly size the content. */
                        img {
                            width:auto;
                            height:auto;
                            max-width:100%;
                            max-height:100vh;
                        }

                        /*
                         * When dark mode is enabled, this begins to load the white background, and then switches to the dark color,
                         * which causes a flicker. Obviously, this isn't great. But it's good enough for now.
                         * TODO: Fix this.
                         */
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
    private var postHeightConstraint: NSLayoutConstraint!

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

        self.postHeightConstraint = self.postContentView.heightAnchor.constraint(equalToConstant: 44)
        self.postHeightConstraint.priority = .defaultLow
        self.postHeightConstraint.isActive = true

        self.spinner.removeFromSuperview()
        self.postContentView.addSubview(self.spinner)
        self.spinner.constrainToCenter(ofView: self.postContentView)
        self.spinner.startAnimating()

        self.postContentView.navigationDelegate = self
    }
}

extension PostCell: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.spinner.stopAnimating()

        self.postContentView.evaluateJavaScript("document.readyState") { (complete, error) in
            if complete != nil {
                self.postContentView.evaluateJavaScript("document.body.scrollHeight") { (height, error) in
                    DispatchQueue.main.async {
                        if let height = height as? CGFloat {
                            self.postHeightConstraint.constant = height
                            self.delegate?.postCellDidResize(self)
                        }
                    }
                }
            }
        }
    }
}

private extension PostCell {
    struct Consts {
        static let postMetadataHeight: CGFloat = 60
    }
}
