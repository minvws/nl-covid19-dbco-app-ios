/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension UIScrollView {
    
    @discardableResult
    func contentWidth(equalTo view: UIView) -> Self {
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: self, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        return self
    }
    
}
