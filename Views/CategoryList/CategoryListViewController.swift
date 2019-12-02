//
//  CategoryListViewController.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class CategoryListViewController: UIViewController {
    let dataProvider: CategoryListDataProvider

    let tableView: UITableView

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlDidTrigger), for: .valueChanged)
        return refreshControl
    }()

    init(dataProvider: CategoryListDataProvider) {
        self.dataProvider = dataProvider
        self.tableView = UITableView()

        super.init(nibName: nil, bundle: nil)

        NotificationCenter.default.addObserver(self, selector: #selector(dataProviderDidUpdate), name: dataProvider.didUpdateNotification, object: nil)

        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tableView)
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Consts.tableViewReuseId)
        self.tableView.dataSource = self
        self.tableView.refreshControl = self.refreshControl

        self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor, constant: 10).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor, constant: -10).isActive = true
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor, constant: 0).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: 0).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        if case .loading = self.dataProvider.state {
            self.refreshControl.beginRefreshing()
        }
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

extension CategoryListViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.dataProvider.numberOfItems()
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let item = self.dataProvider.item(atIndexPath: indexPath) else {
            return UITableViewCell()
        }

        let cell = tableView.dequeueReusableCell(withIdentifier: Consts.tableViewReuseId, for: indexPath)
        cell.textLabel?.text = "Category: `\(item.name)`"
        return cell
    }
}

private extension CategoryListViewController {
    struct Consts {
        static let tableViewReuseId = "CategoryListTableView"
    }
}
