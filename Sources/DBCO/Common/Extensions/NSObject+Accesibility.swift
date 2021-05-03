/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */


import Foundation

extension NSObject {
    
    @discardableResult
    func isAccessibilityElement(_ value: Bool) -> Self {
        self.isAccessibilityElement = value
        return self
    }
    
    @discardableResult
    func setAccessibilityElements(_ value: [Any]?) -> Self {
        self.accessibilityElements = value
        return self
    }
    
}
