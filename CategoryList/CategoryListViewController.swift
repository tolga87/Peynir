//
//  CategoryListViewController.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Combine
import UIKit

class CategoryListViewController: UIViewController {
    weak var actionHandler: CategoryListActionHandler?

    private let dataProvider: CategoryListDataProvider
    private let tableView: UITableView
    private var cancellables: [AnyCancellable] = []

    lazy var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshControlDidTrigger), for: .valueChanged)
        return refreshControl
    }()

    init(dataProvider: CategoryListDataProvider) {
        self.dataProvider = dataProvider
        self.tableView = UITableView()

        super.init(nibName: nil, bundle: nil)

        self.dataProvider.subject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] viewState in
                guard let self = self, self.isViewLoaded else { return }

                switch viewState {
                case .unknown, .loading:
                    self.setRefreshing(true)
                case .loaded, .error:
                    self.setRefreshing(false)
                }

                self.tableView.reloadData()
            }
            .store(in: &self.cancellables)

        self.tableView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(self.tableView)
        self.tableView.register(CategoryListCell.self, forCellReuseIdentifier: Consts.tableViewReuseId)
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.rowHeight = 44//UITableView.automaticDimension
        self.tableView.refreshControl = self.refreshControl
        self.tableView.tableFooterView = UIView()

        self.tableView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        self.tableView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        self.tableView.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true
        self.tableView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "Home"
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if case .loading = self.dataProvider.subject.value {
            self.refreshControl.beginRefreshing()
        }
    }

    @objc func refreshControlDidTrigger() {
        self.dataProvider.requestFetch()
    }

    private func setRefreshing(_ refreshing: Bool) {
        if refreshing {
            self.refreshControl.beginRefreshing()
            self.tableView.setContentOffset(CGPoint(x: 0, y: self.tableView.contentOffset.y - (self.refreshControl.frame.height)), animated: true)
        } else {
            self.refreshControl.endRefreshing()
        }
    }
}

extension CategoryListViewController: UITableViewDataSource {
    private func getCategory(atIndexPath indexPath: IndexPath) -> Category? {
        guard let categories = self.dataProvider.subject.value.getData()?.categories else { return nil }

        return categories[safe: indexPath.row]
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let categories = self.dataProvider.subject.value.getData()?.categories
        return categories?.count ?? 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let category = self.getCategory(atIndexPath: indexPath),
            let cell = tableView.dequeueReusableCell(withIdentifier: Consts.tableViewReuseId, for: indexPath) as? CategoryListCell else {
                return UITableViewCell()
        }

        cell.viewModel = CategoryListCellViewModel(name: category.name,
                                                   color: category.color,
                                                   numTopics: category.topicsAllTime)
        return cell
    }
}

extension CategoryListViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let category = self.getCategory(atIndexPath: indexPath) else { return }
        self.actionHandler?.didSelectCategory(category)
    }
}

private extension CategoryListViewController {
    struct Consts {
        static let tableViewReuseId = "CategoryListTableView"
    }
}
