/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Styled UILabel subclass providing convenience initialization for each text style support in the [Theme](x-source-tag://Theme)
class Label: UILabel {
    
    init(_ text: String?, font: UIFont = Theme.fonts.body, textColor: UIColor = .darkText, isHeader: Bool = false) {
        super.init(frame: .zero)
        
        self.text = text
        self.font = font
        self.textColor = textColor
        
        if isHeader {
            accessibilityTraits = .header
        } else {
            accessibilityTraits.remove(.header)
        }
    }
    
    init(_ text: NSAttributedString) {
        super.init(frame: .zero)
        self.attributedText = text
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
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
        isHidden = text?.isEmpty == true
        return self
    }
    
    @discardableResult
    func applyFont(_ font: UIFont) -> Self {
        self.font = font
        return self
    }
}
