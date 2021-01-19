//
//  SettingsViewModel.swift
//  Peynir
//
//  Created by Tolga AKIN on 1/18/21.
//  Copyright © 2021 Tolga AKIN. All rights reserved.
//

import Foundation

class SettingsAction {
    let title: String
    let callback: (() -> Void)?

    init(title: String, callback: (() -> Void)?) {
        self.title = title
        self.callback = callback
    }
}

class SettingsViewModel {
    let actions: [SettingsAction]

    init(actions: [SettingsAction]) {
        self.actions = actions
    }
}
