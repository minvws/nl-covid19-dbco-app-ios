/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension UILabel {
    
    @discardableResult
    func multiline() -> Self {
        numberOfLines = 0
        return self
    }

    @discardableResult
    func textAlignment(_ alignment: NSTextAlignment) -> Self {
        textAlignment = alignment
        return self
    }

    @discardableResult
    func hideIfEmpty() -> Self {
        isHidden = text == nil || text!.isEmpty == true
        return self
    }

    @discardableResult
    func applyFont(_ font: UIFont) -> Self {
        self.font = font
        return self
    }

}
