/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Combine

class PairingCodeField: UITextField {
    
    @Published private(set) var pairingCode: String?
    
    /// Setting this to `true` lets the field stay first responder, ignoring all input
    var isIgnoringInput: Bool = false
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: 11,
            .font: UIFont.monospacedSystemFont(ofSize: 22, weight: .regular)
        ]
        
        placeholderLabel.embed(in: self)
        sendSubviewToBack(placeholderLabel)
        updatePlaceholder()
        
        font = UIFont.monospacedSystemFont(ofSize: 22, weight: .regular)
        tintColor = Theme.colors.primary
        
        typingAttributes = attributes
        defaultTextAttributes = attributes
        
        textContentType = .oneTimeCode
        keyboardType = .numberPad
        
        delegate = self
    }
    
    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        return CGSize(width: superSize.width, height: superSize.height + 18)
    }
    
    private func updatePlaceholder(textLength: Int = 0) {
        let fullPlaceholder = "000-000-000"
        let remainingPlaceholder = Array(repeating: " ", count: textLength).joined() + String(fullPlaceholder.suffix(fullPlaceholder.count - textLength))
        placeholderLabel.textColor = Theme.colors.captionGray.withAlphaComponent(0.5)
        placeholderLabel.attributedText = NSAttributedString(string: remainingPlaceholder, attributes: [
            .foregroundColor: Theme.colors.captionGray.withAlphaComponent(0.5),
            .kern: 11,
            .font: UIFont.monospacedSystemFont(ofSize: 22, weight: .regular)
        ])
    }
    
    private let placeholderLabel = UILabel()
}

extension PairingCodeField: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !isIgnoringInput else { return false }
        
        let text = (self.text ?? "") as NSString
        
        let trimmedCode = text
            .replacingCharacters(in: range, with: string)
            .components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined()
            .prefix(9)
        
        var codeWithSeparators = String()
        String(trimmedCode).enumerated().forEach { index, character in
            if index % 3 == 0, index > 0 {
                codeWithSeparators.append("-")
            }
            codeWithSeparators.append(character)
        }
        
        self.text = codeWithSeparators

        updatePlaceholder(textLength: codeWithSeparators.count)
        
        if trimmedCode.count == 9 {
            pairingCode = String(trimmedCode)
        } else {
            pairingCode = nil
        }
    
        return false
    }
    
}
