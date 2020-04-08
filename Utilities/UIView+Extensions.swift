//
//  UIView+Extensions.swift
//  Peynir
//
//  Created by tolga on 12/30/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

extension UIView {
    func constrainToEdges(ofView superview: UIView) {
        guard self.superview == superview else {
            logError("Can only constrain view to edges of its superview")
            return
        }

        self.leadingAnchor.constraint(equalTo: superview.leadingAnchor).isActive = true
        self.trailingAnchor.constraint(equalTo: superview.trailingAnchor).isActive = true
        self.topAnchor.constraint(equalTo: superview.topAnchor).isActive = true
        self.bottomAnchor.constraint(equalTo: superview.bottomAnchor).isActive = true
    }

    func constrainToCenter(ofView superview: UIView) {
        guard self.superview == superview else {
            logError("Can only constrain view to center of its superview")
            return
        }

        self.centerXAnchor.constraint(equalTo: superview.centerXAnchor).isActive = true
        self.centerYAnchor.constraint(equalTo: superview.centerYAnchor).isActive = true
    }

    func calculateHeightThatFits() -> CGFloat {
        if self.subviews.isEmpty {
            return self.bounds.height
        }

        var subviewHeights = self.subviews.map { $0.calculateHeightThatFits() }
        subviewHeights.append(self.bounds.height)
        return subviewHeights.max() ?? 0
    }

    func debug_highlightBorder() {
        self.layer.borderColor = UIColor.red.cgColor
        self.layer.borderWidth = 1
        self.layer.cornerRadius = 8
    }
}
