//
//  CategoryListActionHandler.swift
//  Peynir
//
//  Created by tolga on 12/8/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

protocol CategoryListActionHandler: class {
    func didSelectCategory(_ category: Category)
}
