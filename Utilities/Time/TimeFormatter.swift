//
//  TimeFormatter.swift
//  Peynir
//
//  Created by tolga on 1/12/20.
//  Copyright © 2020 Tolga AKIN. All rights reserved.
//

import Foundation

class TimeFormatter {
    static func diffTimeString(withTimeElapsed time: Int) -> String {
        let seconds = time
        if seconds < 60 {
            return self.formattedText(withNumber: seconds, component: "second")
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return self.formattedText(withNumber: minutes, component: "minute")
        }

        let hours = minutes / 60
        if hours < 24 {
            return self.formattedText(withNumber: hours, component: "hour")
        }

        let days = hours / 24
        if days < 30 {
            return self.formattedText(withNumber: days, component: "day")
        }

        let months = days / 30
        if months < 12 {
            return self.formattedText(withNumber: months, component: "month")
        }

        let years = months / 12
        return self.formattedText(withNumber: years, component: "year")
    }
}

private extension TimeFormatter {
    static func formattedText(withNumber number: Int, component: String) -> String {
        let pluralSuffix = (number == 1 ? "" : "s")
        return "\(number) \(component)\(pluralSuffix) ago"
    }
}
