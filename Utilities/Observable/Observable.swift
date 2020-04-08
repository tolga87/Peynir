//
//  Observable.swift
//  Peynir
//
//  Created by tolga on 4/7/20.
//  Copyright © 2020 Tolga AKIN. All rights reserved.
//

import Foundation

typealias UpdateCallback = () -> Void

protocol ObservableInterface {
    associatedtype T

    func addObserver(_ callback: @escaping UpdateCallback)
}

class Observable<T>: ObservableInterface {
    private var callbacks: [UpdateCallback] = []
    var value: T {
        didSet {
            DispatchQueue.main.async {
                self.callbacks.forEach { $0() }
            }
        }
    }

    init(_ value: T) {
        self.value = value
    }

    func addObserver(_ callback: @escaping UpdateCallback) {
        DispatchQueue.main.async {
            self.callbacks.append(callback)
        }
    }
}
