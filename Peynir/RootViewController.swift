//
//  RootViewController.swift
//  Peynir
//
//  Created by tolga on 11/24/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import UIKit

protocol RootViewControllerInterface {
    func push(_ viewController: UIViewController, animated: Bool)
    func pop(animated: Bool)
    func popToRoot(animated: Bool)
}

class RootViewController: UINavigationController, RootViewControllerInterface {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setNavigationBarHidden(true, animated: false)
    }

    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: DebugOptionsManager.shakeGestureNotification, object: self)
        }
    }

    // MARK: - RootViewControllerInterface

    func push(_ viewController: UIViewController, animated: Bool) {
        self.pushViewController(viewController, animated: animated)
    }

    func pop(animated: Bool) {
        self.popViewController(animated: animated)
    }

    func popToRoot(animated: Bool) {
        self.popToRootViewController(animated: animated)
    }
}

