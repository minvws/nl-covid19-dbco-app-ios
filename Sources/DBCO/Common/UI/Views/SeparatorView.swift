/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class SeparatorView: UIView {
    
    enum Style {
        case gray
        case blue
    }
    
    var style: Style {
        didSet { setup() }
    }
    
    init(style: Style = .blue) {
        self.style = style
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.style = .blue
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        switch style {
        case .blue:
            backgroundColor = Theme.colors.separator
        case .gray:
            backgroundColor = Theme.colors.graySeparator
        }
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: 0.5)
    }
}
