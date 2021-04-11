//
//  CategoryListCell.swift
//  Peynir
//
//  Created by tolga on 2/17/20.
//  Copyright © 2020 Tolga AKIN. All rights reserved.
//

import UIKit

class CategoryListCell: UITableViewCell {
    var viewModel: CategoryListCellViewModel? {
        didSet {
            self.updateView()
        }
    }

    private func updateView() {
        guard let viewModel = self.viewModel else {
            self.textLabel?.attributedText = nil
            return
        }

        let nameAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.label,
            .font: UIFont.systemFont(ofSize: 14)
        ]
        let topicCountAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.secondaryLabel,
            .font: UIFont.systemFont(ofSize: 12)
        ]

        let attrString = NSMutableAttributedString()
        attrString.append(NSAttributedString(string: viewModel.name, attributes: nameAttributes))
        attrString.append(NSAttributedString(string: " 💬 \(viewModel.numTopics)", attributes: topicCountAttributes))

        self.textLabel?.numberOfLines = 1
        self.textLabel?.attributedText = attrString
    }
}
