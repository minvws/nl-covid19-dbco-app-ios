/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension Date {
    
    var start: Date {
        return Calendar.current.startOfDay(for: self)
    }
    
    func dateByAddingDays(_ days: Int) -> Date {
        return Calendar.current.date(byAdding: .day, value: -1, to: self) ?? self
    }
    
    func numberOfDaysSince(_ date: Date) -> Int {
        return Calendar.current.dateComponents([.day], from: date.start, to: self.start).day ?? 0
    }
    
    var numberOfDaysAgo: Int {
        return Date.today.numberOfDaysSince(self)
    }
    
    static var today: Date {
        return Date().start
    }
    
    static var now: Date {
        return Date()
    }
    
}
