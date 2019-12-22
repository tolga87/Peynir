//
//  DebugOptionsManager.swift
//  Peynir
//
//  Created by tolga on 12/15/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

protocol ShakeGestureListener: class {
    func didReceiveShakeGesture()
}

class DebugOptionsManager {
    static let sharedInstance = DebugOptionsManager()

    static let shakeGestureNotification = Notification.Name("ShakeGestureNotification")
    private var listeners: [WeakShakeGestureListener]

    fileprivate init() {
        self.listeners = []
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(didReceiveShakeGesture),
                                               name: DebugOptionsManager.shakeGestureNotification,
                                               object: nil)
    }

    func addShakeGestureListener(listener: ShakeGestureListener) {
        self.listeners.append(WeakShakeGestureListener(listener: listener))
    }

    @objc func didReceiveShakeGesture() {
        self.listeners.forEach {
            $0.wrappedListener?.didReceiveShakeGesture()
        }

        // Filter nilled out listeners.
        self.listeners = self.listeners.filter {
            $0.wrappedListener != nil
        }
    }
}

fileprivate class WeakShakeGestureListener {
    weak var wrappedListener: ShakeGestureListener?

    init(listener: ShakeGestureListener) {
        self.wrappedListener = listener
    }
}
