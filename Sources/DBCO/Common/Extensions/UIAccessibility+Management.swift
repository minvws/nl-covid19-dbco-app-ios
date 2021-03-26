/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension UIAccessibility {
    
    /// Helper method to move focus to the provided element after a layout change occurred,
    /// executed after the given amount of seconds
    static func layoutChanged(_ element: Any, after seconds: Double = 0.0) {
        delay(seconds) {
            UIAccessibility.post(notification: .layoutChanged, argument: element)
        }
    }
    
    /// Helper method to move focus to the provided element after a screen change occurred,
    /// executed after the given amount of seconds
    static func screenChanged(_ element: Any, after seconds: Double = 0.0) {
        delay(seconds) {
            UIAccessibility.post(notification: .screenChanged, argument: element)
        }
    }

    /// Helper method to announce the provided message to assistive technologies,
    /// executed after the given amount of seconds
    static func announce(_ message: String, after seconds: Double = 0.0) {
        delay(seconds) {
            UIAccessibility.post(notification: .announcement, argument: message)
        }
    }
}
