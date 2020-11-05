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
}

extension LabeledInputView {
    var isLabelHidden: Bool {
        get { label.isHidden }
        set { label.isHidden = newValue }
    }
    
    var labelText: String? {
        get { label.text }
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
        
        return VStack(spacing: 16,
                      Label(bodyBold: labelText).multiline().hideIfEmpty(),
                      TextView(htmlText: description),
                      self)
    }
}
