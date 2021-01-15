//
//  UserCredentialTextField.swift
//  Peynir
//
//  Created by Tolga AKIN on 1/15/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import UIKit

class UserCredentialTextField: UITextField {
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return super.textRect(forBounds: bounds).inset(by: Consts.textInsets)
    }

    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return super.editingRect(forBounds: bounds).inset(by: Consts.textInsets)
    }

    enum Consts {
        static let textInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8)
    }
}
