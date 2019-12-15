//
//  TopicListViewController.swift
//  Peynir
//
//  Created by tolga on 12/8/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class TopicListViewController: UIViewController {
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
        self.title = "Topics"

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Consts.tableViewReuseId)
        self.tableView.dataSource = self

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
        return self.dataProvider.numberOfItems()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let topic = self.dataProvider.item(atIndexPath: indexPath) else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: Consts.tableViewReuseId, for: indexPath)
        cell.textLabel?.text = "Topic: `\(topic.title)`"
        return cell
    }
}

private extension TopicListViewController {
    struct Consts {
        static let tableViewReuseId = "TopicListTableView"
    }
}