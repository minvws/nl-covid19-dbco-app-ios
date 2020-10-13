/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class Label: UILabel {
    
    init(_ text: String, font: UIFont = Theme.fonts.body, textColor: UIColor = .darkText) {
        super.init(frame: .zero)
        
        self.text = text
        self.font = font
        self.textColor = textColor
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
}
