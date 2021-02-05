/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// A styled subclass of UITextField showing 3 groups of 3 digits representing a pairing code.
/// Calls listeners when a valid pairincode is entered or removed.
class PairingCodeField: UITextField {
    private var pairingCodeHandlers = [(String?) -> Void]()
    
    private(set) var pairingCode: String? {
        didSet {
            pairingCodeHandlers.forEach { $0(pairingCode) }
        }
    }
    
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
    
    @discardableResult
    func didUpdatePairingCode(handler: @escaping (String?) -> Void) -> Self {
        pairingCodeHandlers.append(handler)
        return self
    }
    
    private func setup() {
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: Constants.kerning,
            .font: UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
        ]
        
        placeholderLabel.embed(in: self)
        sendSubviewToBack(placeholderLabel)
        updatePlaceholder()
        
        font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
        tintColor = Theme.colors.primary
        
        typingAttributes = attributes
        defaultTextAttributes = attributes
        
        textContentType = .oneTimeCode
        keyboardType = .numberPad
        autocorrectionType = .no
        
        delegate = self
    }
    
    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        return CGSize(width: superSize.width, height: superSize.height + 18)
    }
    
    private func updatePlaceholder(textLength: Int = 0) {
        let fullPlaceholder = "0000-0000-0000"
        
        let text = NSMutableAttributedString(string: fullPlaceholder, attributes: [
            .kern: Constants.kerning,
            .font: UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
        ])
        
        let clearColor = UIColor.clear
        let visibleColor = Theme.colors.captionGray.withAlphaComponent(0.5)
        
        text.addAttributes([.foregroundColor: clearColor],
                           range: NSRange(location: 0, length: textLength))
        text.addAttributes([.foregroundColor: visibleColor],
                           range: NSRange(location: textLength, length: fullPlaceholder.count - textLength))
        
        placeholderLabel.attributedText = text
    }
    
    private let placeholderLabel = UILabel()
    
    private struct Constants {
        static let kerning: CGFloat = UIScreen.main.bounds.width < 330 ? 6.5 : 10.5
    }
}

extension PairingCodeField: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !isIgnoringInput else { return false }
        
        let text = (self.text ?? "") as NSString
        
        let allowedCharacters = CharacterSet(charactersIn: "0123456789")
        
        let trimmedCode = text
            .replacingCharacters(in: range, with: string)
            .components(separatedBy: allowedCharacters.inverted)
            .joined()
            .prefix(12)
        
        var codeWithSeparators = String()
        String(trimmedCode).enumerated().forEach { index, character in
            if index % 4 == 0, index > 0 {
                codeWithSeparators.append("-")
            }
            codeWithSeparators.append(character)
        }
        
        self.text = codeWithSeparators
        
        if #available(iOS 13.0, *) {
            accessibilityAttributedValue = NSAttributedString(
                string: codeWithSeparators,
                attributes: [.accessibilitySpeechSpellOut: true]
            )
        }

        updatePlaceholder(textLength: codeWithSeparators.count)
        
        if trimmedCode.count == 12 {
            pairingCode = String(trimmedCode)
        } else {
            pairingCode = nil
        }
    
        return false
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        // Fix cursor position to end
        let endRange = textField.textRange(from: textField.endOfDocument,
                                           to: textField.endOfDocument)
        
        guard selectedTextRange != endRange else { return }
        
        selectedTextRange = endRange
    }
    
}
