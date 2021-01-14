//
//  PostListViewController.swift
//  Peynir
//
//  Created by tolga on 12/22/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class PostListViewController: UIViewController {
    weak var deinitDelegate: DeinitDelegate?

    private let dataProvider: PostListDataProvider
    private let webCacheManager: WebCacheManagerInterface
    private let tableView: UITableView
    private var postContentWidth: CGFloat = 0

    // Reusing cells with dynamically resizable webviews proved to be surprisingly difficult and prone to lots of nasty bugs.
    // It's much simpler to allocate them statically without reusing. That's what we do here ¯\_(ツ)_/¯
    private var cells: [PostCell] = []

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlDidTrigger), for: .valueChanged)
        return refreshControl
    }()

    init(dataProvider: PostListDataProvider) {
        self.dataProvider = dataProvider
        self.webCacheManager = WebCacheManager(dataCacheManager: DataCacheManager.sharedInstance)
        self.tableView = UITableView()

        super.init(nibName: nil, bundle: nil)

        self.resetCells()
        NotificationCenter.default.addObserver(self, selector: #selector(dataProviderDidUpdate), name: dataProvider.didUpdateNotification, object: nil)
    }

    deinit {
        self.deinitDelegate?.didDeinit(sender: self)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.dataProvider.topicTitle

        self.tableView.dataSource = self
        self.tableView.rowHeight = UITableView.automaticDimension
        self.tableView.estimatedRowHeight = 44
        self.tableView.tableFooterView = UIView()

        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tableView)
        self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        if self.postContentWidth != 0 && self.postContentWidth != self.tableView.frame.width {
            // Cells need to be resized.
            self.resetCells()
            self.tableView.reloadData()
        }
    }

    func resetCells() {
        self.cells = self.dataProvider.items.map { _ in
            PostCell(style: .default, reuseIdentifier: nil)
        }
    }

    private func generateHtmlContent(forPostContent postContent: String) -> String {
        return """
            <html>
                <head>
                    <style>
                        @media (prefers-color-scheme: dark) {
                            body {
                                background-color: rgb(0,0,0);
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

    @objc func refreshControlDidTrigger() {
        self.dataProvider.fetch()
    }

    @objc func dataProviderDidUpdate() {
        DispatchQueue.main.async {
            self.resetCells()
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
}

extension PostListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.cells.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let post = self.dataProvider.items[safe: indexPath.row],
            let cell = self.cells[safe: indexPath.row] else {
                return UITableViewCell()
        }

        self.postContentWidth = self.tableView.frame.width
        if cell.viewModel == nil {
            let postCellViewModel = PostCellViewModel(id: "\(post.id)",
                                                      name: post.name,
                                                      username: post.username,
                                                      avatarTemplate: post.avatarTemplate,
                                                      createdAt: post.createdAt,
                                                      postContent: post.cooked,
                                                      cacheKey: "\(self.dataProvider.topicId)-\(post.id)",
                                                      postWidth: self.tableView.frame.width)

            cell.delegate = self
            cell.cacheManager = self.webCacheManager
            cell.viewModel = postCellViewModel
            cell.postContentSnapshotPromise = WebSnapshotManager.sharedInstance.snapshot(withId: postCellViewModel.cacheKey,
                                                                                         htmlString: self.generateHtmlContent(forPostContent: post.cooked),
                                                                                         width: tableView.frame.width)
        }
        return cell
    }
}

extension PostListViewController: PostCellDelegate {
    func postCellDidResize(_ cell: PostCell) {
        UIView.performWithoutAnimation {
            self.tableView.beginUpdates()
            self.tableView.endUpdates()
        }
    }
}

struct PostCellViewModel: PostCellViewModelInterface {
    let id: String
    let name: String
    let username: String
    let avatarTemplate: String
    let createdAt: String
    let postContent: String
    let cacheKey: String
    let postWidth: CGFloat
}
