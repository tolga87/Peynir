//
//  HomeViewController.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

class HomeViewController: UITabBarController {
    let containedViewControllers: [UIViewController]

    public init(viewControllers: [UIViewController]) {
        self.containedViewControllers = viewControllers
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.viewControllers = self.containedViewControllers
    }
}
