/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

struct CodeDescription {
    let digitGroupSize: Int
    let numberOfGroups: Int
    let accessibilityLabel: String
    let accessibilityHint: String
    let adjustKerningForWidth: Bool
}

/// A styled subclass of UITextField showing `CodeDescription.numberOfGroups` groups of`CodeDescription.digitGroupSize` digits separated by a `-` representing a code.
/// Calls listeners when a valid code is entered or removed.
class CodeField: UITextField {
    private let codeDescription: CodeDescription
    private var codeHandlers = [(String?) -> Void]()
    
    private(set) var code: String? {
        didSet {
            codeHandlers.forEach { $0(code) }
        }
    }
    
    /// Setting this to `true` lets the field stay first responder, ignoring all input
    var isIgnoringInput: Bool = false
    
    init(with description: CodeDescription) {
        self.codeDescription = description
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    func didUpdatePairingCode(handler: @escaping (String?) -> Void) -> Self {
        codeHandlers.append(handler)
        return self
    }
    
    private func setup() {
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: kerning,
            .font: UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular)
        ]
        
        accessibilityLabel = codeDescription.accessibilityLabel
        accessibilityHint = codeDescription.accessibilityHint
        
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
    
    private lazy var fullPlaceholder: String = {
        let group = Array(repeating: "0",
                          count: codeDescription.digitGroupSize)
            .joined()
        
        return Array(repeating: group,
                     count: codeDescription.numberOfGroups)
            .joined(separator: "-")
    }()
    
    private func updatePlaceholder(textLength: Int = 0) {
        let text = NSMutableAttributedString(string: fullPlaceholder, attributes: [
            .kern: kerning,
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
        static let minKerning: CGFloat = 6
        static let preferredKerning: CGFloat = 10.5
    }
    
    private var kerning: CGFloat {
        if codeDescription.adjustKerningForWidth && UIScreen.main.bounds.width < 330 {
            return Constants.minKerning
        } else {
            return Constants.preferredKerning
        }
    }
}

extension CodeField: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !isIgnoringInput else { return false }
        
        let maxLength = codeDescription.digitGroupSize * codeDescription.numberOfGroups

        let text = (self.text ?? "") as NSString
        
        let allowedCharacters = CharacterSet(charactersIn: "0123456789")
        
        let trimmedCode = text
            .replacingCharacters(in: range, with: string)
            .components(separatedBy: allowedCharacters.inverted)
            .joined()
            .prefix(maxLength)
        
        var codeWithSeparators = String()
        String(trimmedCode).enumerated().forEach { index, character in
            if index % codeDescription.digitGroupSize == 0, index > 0 {
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
        
        if trimmedCode.count == maxLength {
            code = String(trimmedCode)
            resignFirstResponder() // Hide keyboard to show submit button
        } else {
            code = nil
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
