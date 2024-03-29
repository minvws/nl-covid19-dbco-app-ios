/*
 * Copyright (c) 2021 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Styled subclass of UITextView that can handle (simple) html.
/// Auto expands to fit its content.
/// By default the content is not editable or selectable.
/// Can listen to selected links and updated text.
class TextElement: UITextView, UITextViewDelegate {
    
    private var linkHandlers = [(URL) -> Void]()
    private var textChangedHandlers = [(String?) -> Void]()
    
    init(attributedText: NSAttributedString, font: UIFont = Theme.fonts.body, textColor: UIColor = Theme.colors.captionGray, boldTextColor: UIColor = .black) {
        super.init(frame: .zero, textContainer: nil)
        setup()
        
        self.attributedText = attributedText
        setupAttributedStringLinks()
        
    }
    
    ///  Initializes the TextView with the given string
    init(text: String? = nil) {
        super.init(frame: .zero, textContainer: nil)
        setup()
        
        self.text = text
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Sets up the TextElement with the default settings
    private func setup() {
        isAccessibilityElement = true
        delegate = self
        
        font = Theme.fonts.body
        isScrollEnabled = false
        isEditable = false
        isSelectable = false
        backgroundColor = nil
        layer.cornerRadius = 0
        textContainer.lineFragmentPadding = 0
        textContainerInset = .zero
        linkTextAttributes = [
            .foregroundColor: Theme.colors.primary,
            .underlineColor: UIColor.clear]
    }
    
    private func setupAttributedStringLinks() {
        // Improve accessibility by trimming whitespace and newline characters
        if let mutableAttributedText = attributedText.mutableCopy() as? NSMutableAttributedString {
            accessibilityAttributedValue = mutableAttributedText.trim()
        }
        
        if let linkNSRange = attributedText.rangeOfFirstLink,
           let linkRange = Range(linkNSRange, in: attributedText.string) {
            
            // Add word "(Link)" after reading the portion of text that is tappable:
            // e.g. "Tap here (Link) to go to page"
            accessibilityValue = {
                var textWithWordLinkAdded = attributedText.string
                textWithWordLinkAdded.insert(contentsOf: " (Link)", at: linkRange.upperBound)
                return textWithWordLinkAdded
            }()

            // Work out the title of the linked text:
            let linkTitle = attributedText.attributedSubstring(from: linkNSRange).string

            if #available(iOS 13.0, *) {
                // Label the paragraph with the link title (VoiceControl), whilst
                // preventing _audibly_ labelling the whole paragraph with the link title (VoiceOver).
                accessibilityUserInputLabels = [linkTitle]
            } else {
                // Non-ideal fallback for <iOS 13: label the paragraph using the link name, so that
                // the user can tap it using Voice Control. (i.e. also reads it out using Voice Over too).
                accessibilityLabel = linkTitle
            }

            accessibilityTraits = .link
            isAccessibilityElement = true
        } else {
            self.accessibilityLabel = nil
            self.accessibilityValue = nil
            self.accessibilityTraits = .staticText
            self.isAccessibilityElement = false
        }
    }
    
    /// Calculates the intrisic content size
    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        
        if isEditable {
            return CGSize(width: 200, height: max(114, superSize.height))
        } else {
            return superSize
        }
    }
    
    /// Add a listener for selected links. Calling this method will set `isSelectable` to `true`
    ///
    /// - parameter handler: The closure to be called when the user selects a link
    @discardableResult
    func linkTouched(handler: @escaping (URL) -> Void) -> Self {
        isSelectable = true
        linkHandlers.append(handler)
        return self
    }
    
    /// Add a listener for updated text. Calling this method will set `isSelectable` and `isEditable` to `true`
    ///
    /// - parameter handler: The closure to be called when the text is updated
    @discardableResult
    func textChanged(handler: @escaping (String?) -> Void) -> Self {
        isSelectable = true
        isEditable = true
        textChangedHandlers.append(handler)
        return self
    }
    
    /// Delegate method to determine whether a URL can be interacted with
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            linkHandlers.forEach { $0(URL) }
        default:
            return false
        }
        
        return false
    }
    
    /// Delegate method which is called when the user has ended editing
    func textViewDidEndEditing(_ textView: UITextView) {
        textChangedHandlers.forEach { $0(textView.text) }
    }
    
    /// Delegate method which is called when the user has changed selection
    func textViewDidChangeSelection(_ textView: UITextView) {
        guard !isEditable else { return }
        
        // Allows links to be tapped but disables text selection
        textView.selectedTextRange = nil
    }
}
