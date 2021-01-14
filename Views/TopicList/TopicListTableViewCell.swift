//
//  TopicListTableViewCell.swift
//  Peynir
//
//  Created by Tolga AKIN on 1/13/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import UIKit

class TopicListTableViewCell: UITableViewCell {
    var viewModel: TopicListTableViewCellViewModel? {
        didSet {
            guard let vm = viewModel else {
                self.titleLabel.text = nil
                self.metadataLabel.text = nil
                return
            }

            self.titleLabel.text = vm.title
            let timeString = TimeFormatter.diffTimeString(withIso8601DateString: vm.lastPostedAt, mode: .short)
            self.metadataLabel.text = "♡ \(vm.likeCount)   💬 \(vm.postCount)   👀 \(vm.viewCount)   🕒 \(timeString)"
        }
    }

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 16, weight: .regular)
        return label
    }()

    private lazy var metadataLabel: UILabel = {
        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.font = UIFont.systemFont(ofSize: 12, weight: .light)
        return label
    }()

    private lazy var stackView: UIStackView = {
        let view = UIStackView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.axis = .vertical
        view.distribution = .fillEqually

        view.addArrangedSubview(self.titleLabel)
        view.addArrangedSubview(self.metadataLabel)

        return view
    }()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)

        self.contentView.addSubview(self.stackView)
        self.stackView.constrainToEdges(ofView: self.contentView, insets: UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 4))
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func update() {

    }
}
