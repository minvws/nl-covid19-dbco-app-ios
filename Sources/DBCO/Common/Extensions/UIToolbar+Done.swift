/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension UIToolbar {
    static func doneToolbar(for target: Any?, selector: Selector?) -> UIToolbar {
        let toolBar = UIToolbar(frame: CGRect(x: 0, y: 0, width: 100, height: 35))
        toolBar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil), UIBarButtonItem(barButtonSystemItem: .done, target: target, action: selector)], animated: false)
        toolBar.barTintColor = .white
        toolBar.tintColor = Theme.colors.primary
        toolBar.sizeToFit()
        
        return toolBar
    }
}
