/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Styled UILabel convenience initializers for each text style supported in the [Theme](x-source-tag://Theme)
extension UILabel {
    
    convenience init(_ text: String?, font: UIFont = Theme.fonts.body, textColor: UIColor = .darkText, isHeader: Bool = false) {
        self.init()
        
        self.text = text
        self.font = font
        self.textColor = textColor
        
        if isHeader {
            accessibilityTraits = .header
        } else {
            accessibilityTraits.remove(.header)
        }
        
        numberOfLines = 0
        lineBreakMode = .byWordWrapping
        
        setContentCompressionResistancePriority(.required, for: .vertical)
        setContentCompressionResistancePriority(.required, for: .horizontal)
    }
    
    convenience init(largeTitle: String?, textColor: UIColor = .darkText) {
        self.init(largeTitle, font: Theme.fonts.largeTitle, textColor: textColor, isHeader: true)
    }
    
    convenience init(title1: String?, textColor: UIColor = .darkText) {
        self.init(title1, font: Theme.fonts.title1, textColor: textColor, isHeader: true)
    }
    
    convenience init(title2: String?, textColor: UIColor = .darkText) {
        self.init(title2, font: Theme.fonts.title2, textColor: textColor, isHeader: true)
    }
    
    convenience init(title3: String?, textColor: UIColor = .darkText) {
        self.init(title3, font: Theme.fonts.title3, textColor: textColor)
    }
    
    convenience init(headline: String?, textColor: UIColor = .darkText) {
        self.init(headline, font: Theme.fonts.headline, textColor: textColor)
    }
    
    convenience init(body: String?, textColor: UIColor = .darkText) {
        self.init(body, font: Theme.fonts.body, textColor: textColor)
    }
    
    convenience init(bodyBold: String?, textColor: UIColor = .darkText) {
        self.init(bodyBold, font: Theme.fonts.bodyBold, textColor: textColor)
    }
    
    convenience init(callout: String?, textColor: UIColor = .darkText) {
        self.init(callout, font: Theme.fonts.callout, textColor: textColor)
    }
    
    convenience init(subhead: String?, textColor: UIColor = .darkText) {
        self.init(subhead, font: Theme.fonts.subhead, textColor: textColor)
    }
    
    convenience init(subheadBold: String?, textColor: UIColor = .darkText) {
        self.init(subheadBold, font: Theme.fonts.subheadBold, textColor: textColor)
    }
    
    convenience init(footnote: String?, textColor: UIColor = .darkText) {
        self.init(footnote, font: Theme.fonts.footnote, textColor: textColor)
    }
    
    convenience init(caption1: String?, textColor: UIColor = .darkText) {
        self.init(caption1, font: Theme.fonts.caption1, textColor: textColor)
    }
    
    convenience init(attributedString: NSAttributedString?, textColor: UIColor = .darkText) {
        self.init(nil, font: Theme.fonts.body, textColor: textColor)
        self.attributedText = attributedString
    }
    
    func accessibleText(text: String) -> Self {
        accessibilityLabel = text
        return self
    }
    
}
