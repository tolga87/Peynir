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
    var id: String { get }
    var name: String { get }
    var username: String { get }
    var avatarTemplate: String { get }
    var createdAt: String { get }
    var postContent: String { get }
    var cacheKey: String { get }
    var postWidth: CGFloat { get }
}

class PostCell: UITableViewCell {
    weak var delegate: PostCellDelegate?

    var viewModel: PostCellViewModelInterface? {
        didSet {
            self.setupViews()
        }
    }
    var postContentSnapshotPromise: Promise<UIImage>? {
        didSet {
            self.postContentView.snapshotImagePromise = postContentSnapshotPromise
        }
    }

    private var postMetadataView: PostMetadataView?
    private lazy var postMetadataContainerView = UIView()
    private var postMetadataHeightConstraint: NSLayoutConstraint!

    private lazy var postContentView = PostContentView(frame: .zero)

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
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func resetContent() {
        self.setupViews()
    }

    private func setupViews() {
        self.postMetadataContainerView.removeFromSuperview()
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

        self.postMetadataHeightConstraint.priority = .defaultHigh
        self.postMetadataHeightConstraint.isActive = true

        self.postContentView.removeFromSuperview()
        self.postContentView.translatesAutoresizingMaskIntoConstraints = false

        self.contentView.addSubview(self.postContentView)

        self.postContentView.leadingAnchor.constraint(equalTo: self.contentView.leadingAnchor).isActive = true
        self.postContentView.trailingAnchor.constraint(equalTo: self.contentView.trailingAnchor).isActive = true
        self.postContentView.topAnchor.constraint(equalTo: self.postMetadataContainerView.bottomAnchor).isActive = true
        self.postContentView.bottomAnchor.constraint(lessThanOrEqualTo: self.contentView.bottomAnchor).isActive = true

        self.postContentView.contentSizeChangeCallback = { [weak self] contentSize in
            guard let self = self else { return }
            self.delegate?.postCellDidResize(self)
        }
    }
}

private extension PostCell {
    struct Consts {
        static let postMetadataHeight: CGFloat = 60
    }
}
