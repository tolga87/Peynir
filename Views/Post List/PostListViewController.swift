//
//  PostListViewController.swift
//  Peynir
//
//  Created by tolga on 12/22/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class PostListViewController: UIViewController {
    private let dataProvider: PostListDataProvider
    private let tableView: UITableView

    private var rowHeights: [IndexPath: CGFloat] = [:]

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlDidTrigger), for: .valueChanged)
        return refreshControl
    }()

    init(dataProvider: PostListDataProvider) {
        self.dataProvider = dataProvider
        self.tableView = UITableView()

        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(dataProviderDidUpdate), name: dataProvider.didUpdateNotification, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = self.dataProvider.topicTitle

        self.tableView.register(PostCell.self, forCellReuseIdentifier: PostCell.reuseIdentifier)
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

    @objc func refreshControlDidTrigger() {
        self.dataProvider.fetch()
    }

    @objc func dataProviderDidUpdate() {
        DispatchQueue.main.async {
            self.refreshControl.endRefreshing()
            self.tableView.reloadData()
        }
    }
}

extension PostListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataProvider.numberOfItems()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let post = self.dataProvider.item(atIndexPath: indexPath) else {
            return UITableViewCell()
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: PostCell.reuseIdentifier, for: indexPath) as? PostCell else {
            return UITableViewCell()
        }

        cell.resetContent()
        cell.delegate = self
        cell.htmlContent = post.cooked
        return cell
    }
}

extension PostListViewController: PostCellDelegate {
    func postCellDidResize(_ cell: PostCell) {
        // TODO(tolga): It looks like this can sometimes cause a crash. Investigate.
        self.tableView.beginUpdates()
        self.tableView.endUpdates()
    }
}
