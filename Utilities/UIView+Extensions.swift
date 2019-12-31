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
}
