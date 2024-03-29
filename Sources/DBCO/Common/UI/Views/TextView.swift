/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

/// Styled subclass of UITextView that can handle (simple) html.
/// Auto expands to fit its content.
/// By default the content is not editable or selectable.
/// Can listen to selected links and updated text.
///
/// # See also:
/// [linkTouched(handler:)](x-source-tag://TextView.linkTouched),
/// [textChanged(handler:)](x-source-tag://TextView.textChanged)
/// Styled subclass of UIStackView that displays one or more TextElement's, which can handle (simple) html
/// Auto expands to fit its content.
/// By default the content is not editable or selectable.
/// Can listen to selected links and updated text.
class TextView: UIStackView {
    
    var paragraphMarginMultiplier: CGFloat = 0.5
    var headerMarginMultiplier: CGFloat = 0.6
    var listItemMarginMultiplier: CGFloat = 0.5
    
    /// Helper variable to display the given text by using a TextElement
    var text: String? {
        didSet {
            removeAllArrangedSubviews()
            
            let element = TextElement(text: text)
            addArrangedSubview(element)
        }
    }
    
    /// Helper variable to display a TextElement for each paragraph in the attributed string
    var attributedText: NSAttributedString? {
        didSet {
            removeAllArrangedSubviews()
            
            guard let attributedText = attributedText else { return }
            
            // Split attributed text on new line
            let parts = attributedText.split("\n")
            
            for part in parts {
                // 1. Determine spacing of previous element
                if let previousElement = arrangedSubviews.last {
                    var spacing = part.lineHeight
                    
                    if part.isHeader {
                        spacing *= headerMarginMultiplier
                    } else if part.isListItem {
                        spacing *= listItemMarginMultiplier
                    } else {
                        spacing *= paragraphMarginMultiplier
                    }
                    
                    setCustomSpacing(spacing, after: previousElement)
                }
                
                // 2. Add current TextElement
                let element: UIView
                
                if part.isHeader {
                    element = UILabel(attributedString: part)
                    element.accessibilityTraits = .header
                } else {
                    element = TextElement(attributedText: part)
                }
                
                // Hide for assistive technologies?
                if part.isBlank {
                    element.isAccessibilityElement = false
                }
                
                addArrangedSubview(element)
            }
        }
    }
    
    /// Helper variable to retrieve all subviews
    var textElements: [TextElement] {
        return arrangedSubviews.compactMap { view in
            return view as? TextElement
        }
    }
    
    /// Helper variable to pass linkTextAttributes to each subview
    var linkTextAttributes: [NSAttributedString.Key: Any]? {
        didSet {
            textElements.forEach { $0.linkTextAttributes = linkTextAttributes }
        }
    }
    
    /// Helper variable to pass textAlignment to each subview
    var textAlignment: NSTextAlignment {
        get { textElements.first?.textAlignment ?? NSTextAlignment.natural }
        set { textElements.forEach { $0.textAlignment = newValue } }
    }
    
    /// Initializes the TextView by parsing the given string to HTML
    init(htmlText: String, font: UIFont = Theme.fonts.body, textColor: UIColor = Theme.colors.captionGray, boldTextColor: UIColor = .black) {
        super.init(frame: .zero)
        setup()
        
        html(htmlText, font: font, textColor: textColor, boldTextColor: boldTextColor)
    }
    
    //// Initializes the TextView with a string
    init(text: String? = nil) {
        super.init(frame: .zero)
        setup()
        
        self.text = text
    }
    
    /// Initializes the TextView with an attributed string
    init(attributedText: NSAttributedString) {
        super.init(frame: .zero)
        setup()
        
        self.attributedText = attributedText
    }
    
    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Set vertical alignment
    private func setup() {
        axis = .vertical
    }
        
    /// Sets the content to the supplied html string.
    @discardableResult
    func html(_ htmlText: String?, font: UIFont = Theme.fonts.body, textColor: UIColor = Theme.colors.captionGray, boldTextColor: UIColor = .black) -> Self {
        attributedText = .makeFromHtml(text: htmlText, style: .init(font: font, textColor: textColor, boldTextColor: boldTextColor))
        return self
    }
    
    /// Add a listener for selected links. Calling this method will set `isSelectable` to `true`
    ///
    /// - parameter handler: The closure to be called when the user selects a link
    @discardableResult
    func linkTouched(handler: @escaping (URL) -> Void) -> Self {
        textElements.forEach({ $0.linkTouched(handler: handler) })
        return self
    }
    
    /// Add a listener for updated text. Calling this method will set `isSelectable` and `isEditable` to `true`
    ///
    /// - parameter handler: The closure to be called when the text is updated
    @discardableResult
    func textChanged(handler: @escaping (String?) -> Void) -> Self {
        textElements.forEach({ $0.textChanged(handler: handler) })
        return self
    }
    
    /// Removes all arranged subviews
    @discardableResult
    func removeAllArrangedSubviews() -> [UIView] {
        let removedSubviews = arrangedSubviews.reduce([]) { removedSubviews, subview -> [UIView] in
            self.removeArrangedSubview(subview)
            NSLayoutConstraint.deactivate(subview.constraints)
            subview.removeFromSuperview()
            return removedSubviews + [subview]
        }
        return removedSubviews
    }
}

extension NSAttributedString {
    
    /// Helper method to split an attributed string by using the given separator
    func split(_ separator: String) -> [NSAttributedString] {
        var substrings = [NSAttributedString]()
        
        var index = 0
        for component in self.string.components(separatedBy: separator) {
            let range = NSRange(location: index, length: component.utf16.count)
            
            let substring = self.attributedSubstring(from: range)
            substrings.append(substring)
            
            index += range.length + separator.count
        }
        
        return substrings
    }
    
    /// Helper method to find certain attributes of an attributed string
    func attributes(find: (_ key: Key, _ value: Any, _ range: NSRange) -> (Bool)) -> Bool {
        var result = false
        enumerateAttributes(in: NSRange(location: 0, length: self.length)) { attributes, range, stop in
            for (key, value) in attributes {
                if find(key, value, range) {
                    result = true
                    break
                }
            }
        }
        return result
    }
    
    func fontAttributes(allSatisfy: (_ value: UIFont?) -> (Bool)) -> Bool {
        var result = true
        enumerateAttribute(.font, in: NSRange(location: 0, length: self.length)) { value, range, stop in
            if !allSatisfy(value as? UIFont) {
                result = false
            }
        }
        return result
    }
    
    /// Determines whether the attributed string is a header
    var isHeader: Bool {
        let headerLevel = attributes { key, value, range in
            // Check if header level is h1 or higher
            if key == NSAttributedString.Key.paragraphStyle,
               let paragraphStyle = value as? NSParagraphStyle,
               paragraphStyle.headerLevel >= 1 {
                return true
            }
        
            return false
        }
        
        let completelyBold = fontAttributes { $0?.fontDescriptor.symbolicTraits.contains(.traitBold) ?? false }
        
        return headerLevel || completelyBold
    }
    
    /// Determines whether the attributed string contains a link
    var containsLink: Bool {
        return attributes { key, value, range in
            return key == NSAttributedString.Key.link
        }
    }
    
    /// Determines whether the attributed string contains a link
    var rangeOfFirstLink: NSRange? {
        var foundRange: NSRange?
        
        _ = attributes { key, value, range in
            guard key == NSAttributedString.Key.link else { return false }
            foundRange = range
            return true
        }
        
        return foundRange
    }
    
    // swiftlint:disable empty_count
    /// Determines whether the attributed string is a list item
    var isListItem: Bool {
        // Check if strings starts with tabbed bullet character
        if string.starts(with: "\t●") || string.starts(with: "\t•") {
            return true
        }
        
        // Check if textLists attribute contains one or more elements
        return attributes { key, value, _ in
            
            if key == NSAttributedString.Key.paragraphStyle,
               let paragraphStyle = value as? NSParagraphStyle,
               paragraphStyle.textLists.count > 0 {
                return true
            }
            return false
        }
    }

    /// Determines the line height used for the attributed string
    var lineHeight: CGFloat {
        var height: CGFloat = 22
        
        // Retrieve the maximum value set for minimumLineHeight in NSParagraphStyle
        enumerateAttributes(in: NSRange(location: 0, length: self.length)) { attributes, range, stop in
            for (key, value) in attributes {
                if key == NSAttributedString.Key.paragraphStyle,
                   let paragraphStyle = value as? NSParagraphStyle,
                   paragraphStyle.minimumLineHeight > height {
                    height = paragraphStyle.minimumLineHeight
                }
            }
        }
        
        return height
    }
    
    /// Determines if the attributed string is blank
    var isBlank: Bool {
        return string.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

extension NSParagraphStyle {
    
    var headerLevel: Int {
        let key = "headerLevel"
        if responds(to: NSSelectorFromString(key)) {
            return value(forKey: key) as? Int ?? 0
        }
        return 0
    }
    
    var textLists: NSArray {
        let key = "textLists"
        if responds(to: NSSelectorFromString(key)) {
            return value(forKey: key) as? NSArray ?? []
        }
        return []
    }
}
