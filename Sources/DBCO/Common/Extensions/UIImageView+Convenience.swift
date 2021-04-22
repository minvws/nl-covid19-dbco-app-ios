/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

extension UIImageView {
    
    convenience init(imageName: String, highlightedImageName: String? = nil) {
        self.init(image: UIImage(named: imageName))
        
        if let highlightedImageName = highlightedImageName {
            highlightedImage = UIImage(named: highlightedImageName)
        }
    }
    
}

extension UIImageView {
    
    @discardableResult
    func asIcon(color: UIColor = Theme.colors.primary) -> Self {
        contentMode = .center
        setContentHuggingPriority(.required, for: .horizontal)
        tintColor = color
        return self
    }
    
}
