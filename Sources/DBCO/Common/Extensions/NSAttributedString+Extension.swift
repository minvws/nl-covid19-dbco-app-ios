/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

public extension NSAttributedString {

    static func makeFromHtml(text: String, font: UIFont, textColor: UIColor, textAlignment: NSTextAlignment = .left, lineHeight: CGFloat? = nil, underlineColor: UIColor? = nil) -> NSAttributedString {

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        
        // create custom tabstops to align lists
        let tabInterval: CGFloat = 20
        var tabStops = [NSTextTab]()
        tabStops.append(NSTextTab(textAlignment: .natural, location: 1))
        for i in 1...12 {
            tabStops.append(NSTextTab(textAlignment: .natural, location: CGFloat(i)*tabInterval))
        }
        
        paragraphStyle.tabStops = tabStops
        paragraphStyle.headIndent = tabInterval
        paragraphStyle.paragraphSpacing = 8
        
        var attributes: [Key: Any] = [
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle,
        ]
        if let underlineColor = underlineColor {
            attributes[.underlineColor] = underlineColor
            attributes[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        let data: Data = text.data(using: .unicode) ?? Data(text.utf8)

        if let attributedTitle = try? NSMutableAttributedString(data: data,
                                                                options: [.documentType: NSAttributedString.DocumentType.html],
                                                                documentAttributes: nil) {

            let fullRange = NSRange(location: 0, length: attributedTitle.length)
            attributedTitle.addAttributes(attributes, range: fullRange)

            let boldFontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold)
            let boldFont = boldFontDescriptor.map { UIFont(descriptor: $0, size: font.pointSize) }

            // replace default font with desired font - maintain bold style if possible
            attributedTitle.enumerateAttribute(.font, in: fullRange, options: []) { value, range, finished in
                guard let currentFont = value as? UIFont else { return }

                let newFont: UIFont

                if let boldFont = boldFont, currentFont.fontDescriptor.symbolicTraits.contains(.traitBold) {
                    newFont = boldFont
                } else {
                    newFont = font
                }

                attributedTitle.removeAttribute(.font, range: range)
                attributedTitle.addAttribute(.font, value: newFont, range: range)
            }
            
            // Replace added bullets with styled bullets
            let bulletFont = font.withSize(10)
            let bulletAttributes: [NSAttributedString.Key: Any] = [
                .font: bulletFont,
                .foregroundColor: Theme.colors.primary,
                .baselineOffset: (font.xHeight - bulletFont.xHeight) / 2
            ]
            
            let currentText = attributedTitle.string
            var searchRange = NSRange(location: 0, length:currentText.count)
            var foundRange = NSRange()
            while searchRange.location < currentText.count {
                searchRange.length = currentText.count - searchRange.location
                foundRange = (currentText as NSString).range(of: "•", options: [], range: searchRange)
                if foundRange.location != NSNotFound {
                    searchRange.location = foundRange.location + foundRange.length
                    attributedTitle.replaceCharacters(in: foundRange, with: NSAttributedString(string: "\u{25CF}", attributes: bulletAttributes))
                } else {
                    break
                }
            }

            return attributedTitle
        }

        return NSAttributedString(string: text)
    }
}
