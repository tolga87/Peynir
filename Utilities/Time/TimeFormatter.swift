//
//  TimeFormatter.swift
//  Peynir
//
//  Created by tolga on 1/12/20.
//  Copyright © 2020 Tolga AKIN. All rights reserved.
//

import Foundation

// TODO: Add tests.
class TimeFormatter {
    enum Mode {
        case short
        case long
    }

    static func diffTimeString(withTimeElapsed time: Int, mode: Mode) -> String {
        let seconds = time
        if seconds < 60 {
            return self.formattedText(withNumber: seconds, component: "second", mode: mode)
        }

        let minutes = seconds / 60
        if minutes < 60 {
            return self.formattedText(withNumber: minutes, component: "minute", mode: mode)
        }

        let hours = minutes / 60
        if hours < 24 {
            return self.formattedText(withNumber: hours, component: "hour", mode: mode)
        }

        let days = hours / 24
        if days < 30 {
            return self.formattedText(withNumber: days, component: "day", mode: mode)
        }

        let months = days / 30
        if months < 12 {
            return self.formattedText(withNumber: months, component: "month", mode: mode)
        }

        let years = months / 12
        return self.formattedText(withNumber: years, component: "year", mode: mode)
    }

    static func diffTimeString(withIso8601DateString dateString: String, mode: Mode) -> String {
        guard let date = self.date(fromIso8601DateString: dateString) else { return "" }

        let timeElapsed = -Int(date.timeIntervalSinceNow)
        return self.diffTimeString(withTimeElapsed: timeElapsed, mode: mode)
    }

    static func date(fromIso8601DateString dateString: String) -> Date? {
        let utcISODateFormatter = ISO8601DateFormatter()
        utcISODateFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]

        return utcISODateFormatter.date(from: dateString)
    }
}

private extension TimeFormatter {
    static func formattedText(withNumber number: Int, component: String, mode: Mode) -> String {
        var text = "\(number)"

        switch mode {
        case .short:
            text += String(component[component.startIndex])

        case .long:
            let pluralSuffix = (number == 1 ? "" : "s")
            text += " \(component)\(pluralSuffix) ago"
        }

        return text
    }
}
