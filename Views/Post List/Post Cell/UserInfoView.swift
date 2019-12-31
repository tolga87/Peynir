//
//  UserInfoView.swift
//  Peynir
//
//  Created by tolga on 12/30/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

protocol UserInfoViewModelInterface {
    var name: String { get }
    var username: String { get }
    var avatarTemplate: String { get }
}

class UserInfoView: UIView {
    // TODO: Make this Optional, and implement "Loading" state.
    private let viewModel: UserInfoViewModelInterface
    private let networkManager: NetworkManagerInterface

    private let avatarView: NetworkImageView

    private lazy var userNameLabel: UILabel = {
        let label = UILabel()
        label.text = "\(self.viewModel.name) - \(self.viewModel.username)"
        return label
    }()

    private lazy var timestampLabel: UILabel = {
        let label = UILabel()
        label.text = "<TIMESTAMP>"
        return label
    }()

    init(height: CGFloat, viewModel: UserInfoViewModelInterface, networkManager: NetworkManagerInterface = NetworkManager.sharedInstance) {
        self.viewModel = viewModel
        self.networkManager = networkManager

        let imageSize = Int(height - 2.0 * Consts.verticalPadding)
        let fullAvatarTemplate = "\(self.networkManager.baseUrl)\(self.viewModel.avatarTemplate)"
        let avatarUrl = fullAvatarTemplate.replacingOccurrences(of: "{size}", with: "\(imageSize)")
        let fileName = "avatar_\(self.viewModel.username)_\(imageSize).png"

        self.avatarView = NetworkImageView(url: avatarUrl, fileName: fileName, networkManager: self.networkManager)

        super.init(frame: .zero)

        [self.avatarView, self.userNameLabel, self.timestampLabel].forEach { subview in
            subview.translatesAutoresizingMaskIntoConstraints = false
            self.addSubview(subview)
        }

        self.avatarView.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: Consts.horizontalPadding).isActive = true
        self.avatarView.topAnchor.constraint(equalTo: self.topAnchor, constant: Consts.verticalPadding).isActive = true
        self.avatarView.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Consts.verticalPadding).isActive = true
        self.avatarView.widthAnchor.constraint(equalToConstant: CGFloat(imageSize)).isActive = true
        self.avatarView.heightAnchor.constraint(equalTo: self.avatarView.widthAnchor).isActive = true

        self.userNameLabel.leadingAnchor.constraint(equalTo: self.avatarView.trailingAnchor, constant: Consts.horizontalPadding).isActive = true
        self.userNameLabel.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -Consts.horizontalPadding).isActive = true
        self.userNameLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: Consts.verticalPadding).isActive = true

        self.timestampLabel.leadingAnchor.constraint(equalTo: self.userNameLabel.leadingAnchor).isActive = true
        self.timestampLabel.trailingAnchor.constraint(equalTo: self.userNameLabel.trailingAnchor).isActive = true
        self.timestampLabel.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -Consts.verticalPadding).isActive = true

        self.timestampLabel.topAnchor.constraint(equalTo: self.userNameLabel.bottomAnchor, constant: Consts.verticalPadding).isActive = true
        self.userNameLabel.heightAnchor.constraint(equalTo: self.timestampLabel.heightAnchor).isActive = true
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

private extension UserInfoView {
    struct Consts {
        static let horizontalPadding: CGFloat = 8
        static let verticalPadding: CGFloat = 8
    }
}
