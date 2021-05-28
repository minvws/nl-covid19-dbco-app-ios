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
    
    private let scaledFont = UIFontMetrics(forTextStyle: .title2)
        .scaledFont(for: UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .regular))
    
    private func setup() {
        accessibilityLabel = codeDescription.accessibilityLabel
        accessibilityHint = codeDescription.accessibilityHint
        
        placeholderLabel.embed(in: self)
        sendSubviewToBack(placeholderLabel)
        updatePlaceholder()
        
        font = scaledFont
        tintColor = Theme.colors.primary
        
        textContentType = .oneTimeCode
        keyboardType = .numberPad
        autocorrectionType = .no
        
        delegate = self
        attributedPlaceholder = NSAttributedString(string: fullPlaceholder, attributes: [.foregroundColor: UIColor.clear])
        
        updateKerning()
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
            .font: scaledFont
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
        if codeDescription.adjustKerningForWidth && UIScreen.main.bounds.width < 380 {
            return Constants.minKerning
        } else {
            return Constants.preferredKerning
        }
    }
    
    private func updateKerning() {
        let attributes: [NSAttributedString.Key: Any] = [
            .kern: kerning,
            .font: scaledFont
        ]
        
        typingAttributes = attributes
        defaultTextAttributes = attributes
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        
        updateKerning()
    }
}

extension CodeField: UITextFieldDelegate {
    
    private var maxLength: Int {
        return codeDescription.digitGroupSize * codeDescription.numberOfGroups
    }
    
    private func trim(_ text: String) -> String {
        let allowedCharacters = CharacterSet(charactersIn: "0123456789")
        
        let trimmed = text
            .components(separatedBy: allowedCharacters.inverted)
            .joined()
            .prefix(maxLength)
        
        return String(trimmed)
    }
    
    private func addSeparators(to text: String) -> String {
        var separated = String()
        
        text.enumerated().forEach { index, character in
            if index % codeDescription.digitGroupSize == 0, index > 0 {
                separated.append("-")
            }
            separated.append(character)
        }
        
        return separated
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard !isIgnoringInput else { return false }

        let text = (self.text ?? "") as NSString
        let trimmedCode = trim(text.replacingCharacters(in: range, with: string))
        
        let codeWithSeparators = addSeparators(to: trimmedCode)
        self.text = codeWithSeparators
        
        if #available(iOS 13.0, *) {
            accessibilityAttributedValue = NSAttributedString(
                string: codeWithSeparators,
                attributes: [.accessibilitySpeechSpellOut: true]
            )
        }

        updatePlaceholder(textLength: codeWithSeparators.count)
        
        if trimmedCode.count == maxLength {
            code = trimmedCode
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
