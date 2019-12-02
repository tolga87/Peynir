//
//  Result+Extensions.swift
//  Peynir
//
//  Created by tolga on 12/1/19.
//  Copyright © 2019 Tolga AKIN. All rights reserved.
//

import Foundation

extension Result {
    public var successValue: Success? {
        if case .success(let value) = self {
            return value
        }
        return nil
    }

    public var failureValue: Failure? {
        if case .failure(let value) = self {
            return value
        }
        return nil
    }
}
