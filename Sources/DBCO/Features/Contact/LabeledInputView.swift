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
        
        func listItem(text: String.SubSequence) -> UIView {
            if text.starts(with: "*") {
                let icon = UIImageView(image: UIImage(named: "ListItem"))
                icon.setContentHuggingPriority(.required, for: .horizontal)
                
                return HStack(spacing: 12,
                              icon.withInsets(.topBottom(7)),
                              Label(body: String(text).trimmingCharacters(in: CharacterSet(charactersIn: "* ")), textColor: Theme.colors.captionGray).multiline())
                    .alignment(.top)
            } else {
                return Label(body: String(text), textColor: Theme.colors.captionGray).multiline()
            }
        }
        
        func list(from multilineText: String) -> UIView {
            return VStack(spacing: 8, multilineText.split(separator: "\n").map(listItem))
        }
        
        return VStack(spacing: 16,
                      Label(bodyBold: labelText).multiline().hideIfEmpty(),
                      list(from: description),
                      self)
    }
}
