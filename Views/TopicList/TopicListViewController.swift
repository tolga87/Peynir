//
//  TopicListViewController.swift
//  Peynir
//
//  Created by tolga on 12/8/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class TopicListViewController: UIViewController {
    weak var actionHandler: TopicListActionHandler?

    private let dataProvider: TopicListDataProvider
    private let tableView: UITableView

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlDidTrigger), for: .valueChanged)
        return refreshControl
    }()

    init(dataProvider: TopicListDataProvider) {
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
        self.title = self.dataProvider.categoryName

        self.tableView.register(TopicListTableViewCell.self, forCellReuseIdentifier: Consts.tableViewReuseId)
        self.tableView.dataSource = self
        self.tableView.delegate = self

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

extension TopicListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataProvider.items.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let topic = self.dataProvider.items[safe: indexPath.row] else {
            return TopicListTableViewCell()
        }

        guard let cell = tableView.dequeueReusableCell(withIdentifier: Consts.tableViewReuseId, for: indexPath) as? TopicListTableViewCell else {
            return TopicListTableViewCell()
        }

        cell.viewModel = TopicListTableViewCellViewModel(title: topic.title,
                                                        likeCount: topic.likeCount,
                                                        postCount: topic.postsCount,
                                                        viewCount: topic.views,
                                                        lastPostedAt: topic.lastPostedAt,
                                                        hasAcceptedAnswer: topic.hasAcceptedAnswer)
        return cell
    }
}

extension TopicListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let topic = self.dataProvider.items[safe: indexPath.row] else { return }
        self.actionHandler?.didSelectTopic(topic)
    }
}

private extension TopicListViewController {
    struct Consts {
        static let tableViewReuseId = "TopicListTableView"
    }
}
