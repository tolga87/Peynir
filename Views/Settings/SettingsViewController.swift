//
//  SettingsViewController.swift
//  Peynir
//
//  Created by Tolga AKIN on 1/18/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import UIKit
import PromiseKit

class SettingsViewController: UITableViewController {
    private let viewModel: SettingsViewModel

    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel

        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "Settings"
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: Consts.tableViewReuseId)
        self.tableView.tableFooterView = UIView()
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        guard section == 0 else { return 0 }

        return self.viewModel.actions.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(withIdentifier: Consts.tableViewReuseId),
            let action = self.viewModel.actions[safe: indexPath.row] else {
                return UITableViewCell()
        }

        cell.textLabel?.text = "..."
        firstly {
            action.title
        }.done {
            cell.textLabel?.text = $0
        }

        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        guard let action = self.viewModel.actions[safe: indexPath.row] else {
            return
        }

        action.callback?()
    }
}

private extension SettingsViewController {
    enum Consts {
        static let tableViewReuseId = "SettingsViewControllerTableViewReuseId"
    }
}
