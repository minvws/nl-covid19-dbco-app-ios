/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol LabeledInputView: UIView {
    associatedtype LabelType: UILabel
    
    var label: LabelType { get }
    var labelText: String? { get set }
    var isLabelHidden: Bool { get set }
    
    var isEmphasized: Bool { get }
}

extension LabeledInputView {
    var isLabelHidden: Bool {
        get { return label.isHidden }
        set { label.isHidden = newValue }
    }
    
    var labelText: String? {
        get { return label.text }
        set {
            label.text = newValue
            label.isHidden = newValue == nil
        }
    }
}

extension TextField: LabeledInputView {}
extension InputTextView: LabeledInputView {}
extension ToggleGroup: LabeledInputView {}

extension LabeledInputView {
    func decorateWithDescriptionIfNeeded(description: String?) -> UIView {
        guard let description = description else {
            return self
        }
        
        isLabelHidden = true
        
        let isEmphasized = self.isEmphasized
        
        let labelFont = isEmphasized ? Theme.fonts.bodyBold : Theme.fonts.subhead
        let descriptionFont = isEmphasized ? Theme.fonts.body : Theme.fonts.subhead
        let spacing: CGFloat = isEmphasized ? 16 : 0
        
        accessibilityLabel = labelText
        accessibilityHint = description
        
        return VStack(spacing: max(spacing, 6),
                      VStack(spacing: spacing,
                             UILabel(labelText)
                                .applyFont(labelFont)
                                .multiline()
                                .hideIfEmpty()
                                .isAccessibilityElement(false),
                             TextView(htmlText: description,
                                      font: descriptionFont,
                                      textColor: Theme.colors.captionGray)
                                .isAccessibilityElement(false)),
                      self)
            .setAccessibilityElements([self])
    }
}
