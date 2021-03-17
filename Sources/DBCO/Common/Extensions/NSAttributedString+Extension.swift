/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

public extension NSAttributedString {

    static func makeFromHtml(text: String?, font: UIFont, textColor: UIColor, boldTextColor: UIColor? = nil, textAlignment: NSTextAlignment = .left) -> NSAttributedString {
        let text = text ?? ""
        
        let attributes = createAttributes(textAlignment: textAlignment, textColor: textColor)
        
        let data: Data = text.data(using: .unicode) ?? Data(text.utf8)
        
        guard let attributedText = try? NSMutableAttributedString(data: data,
                                                                   options: [.documentType: NSAttributedString.DocumentType.html],
                                                                   documentAttributes: nil) else {
            return NSAttributedString(string: text)
        }

        let fullRange = NSRange(location: 0, length: attributedText.length)
        attributedText.addAttributes(attributes, range: fullRange)

        replaceFonts(in: attributedText, font: font, textColor: textColor, boldTextColor: boldTextColor)
        replaceBullets(in: attributedText, font: font)
        replaceListParagraphStyle(in: attributedText, textAlignment: textAlignment)
        removeTrailingNewlines(in: attributedText)

        return attributedText
    }
    
    private static func createAttributes(textAlignment: NSTextAlignment, textColor: UIColor) -> [Key: Any] {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = textAlignment
        paragraphStyle.paragraphSpacing = 8
        
        let attributes: [Key: Any] = [
            .foregroundColor: textColor,
            .paragraphStyle: paragraphStyle
        ]
        
        return attributes
    }
    
    private static func createListParagraphStyle(textAlignment: NSTextAlignment) -> NSParagraphStyle {
        let tabInterval: CGFloat = 20
        var tabStops = [NSTextTab]()
        tabStops.append(NSTextTab(textAlignment: .natural, location: 1))
        for index in 1...12 {
            tabStops.append(NSTextTab(textAlignment: .natural, location: CGFloat(index) * tabInterval))
        }
        
        let listParagraphStyle = NSMutableParagraphStyle()
        listParagraphStyle.alignment = textAlignment
        listParagraphStyle.paragraphSpacing = 8
        listParagraphStyle.tabStops = tabStops
        listParagraphStyle.headIndent = tabInterval
        listParagraphStyle.firstLineHeadIndent = 0
        
        return listParagraphStyle
    }
    
    private static func replaceFonts(in text: NSMutableAttributedString, font: UIFont, textColor: UIColor, boldTextColor: UIColor?) {
        let fullRange = NSRange(location: 0, length: text.length)
        
        let boldFontDescriptor = font.fontDescriptor.withSymbolicTraits(.traitBold)
        let boldFont = boldFontDescriptor.map { UIFont(descriptor: $0, size: font.pointSize) }
        
        text.enumerateAttribute(.font, in: fullRange, options: []) { value, range, finished in
            guard let currentFont = value as? UIFont else { return }

            let newFont: UIFont
            let newColor: UIColor

            if let boldFont = boldFont, currentFont.fontDescriptor.symbolicTraits.contains(.traitBold) {
                newFont = boldFont
                newColor = boldTextColor ?? textColor
            } else {
                newFont = font
                newColor = textColor
            }

            text.removeAttribute(.font, range: range)
            text.removeAttribute(.foregroundColor, range: range)
            
            text.addAttribute(.font, value: newFont, range: range)
            text.addAttribute(.foregroundColor, value: newColor, range: range)
        }
    }
    
    private static let listBulletCharacter = "\u{25CF}"
    
    private static func replaceBullets(in text: NSMutableAttributedString, font: UIFont) {
        let bulletFont = font.withSize(10)
        let bulletAttributes: [NSAttributedString.Key: Any] = [
            .font: bulletFont,
            .foregroundColor: Theme.colors.primary,
            .baselineOffset: (font.xHeight - bulletFont.xHeight) / 2
        ]
        
        let currentText = text.string
        var searchRange = NSRange(location: 0, length: currentText.count)
        var foundRange = NSRange()
        while searchRange.location < currentText.count {
            searchRange.length = currentText.count - searchRange.location
            foundRange = (currentText as NSString).range(of: "•", options: [], range: searchRange)
            if foundRange.location != NSNotFound {
                searchRange.location = foundRange.location + foundRange.length
                text.replaceCharacters(in: foundRange, with: NSAttributedString(string: listBulletCharacter, attributes: bulletAttributes))
            } else {
                break
            }
        }
    }
    
    private static func replaceListParagraphStyle(in text: NSMutableAttributedString, textAlignment: NSTextAlignment) {
        let fullRange = NSRange(location: 0, length: text.length)
        let listParagraphStyle = createListParagraphStyle(textAlignment: textAlignment)
        
        var previousParagraphIsListStart = false
        text.enumerateAttribute(.paragraphStyle, in: fullRange, options: []) { value, range, finished in
            
            let searchText = text.string as NSString
            if searchText.substring(with: range).starts(with: listBulletCharacter) {
                var startRange = range
                if range.location > 0 {
                    // adjust the range so the style is set before the line starts so indentations are properly calculated
                    startRange.location -= 1
                    startRange.length += 1
                }
                text.removeAttribute(.paragraphStyle, range: startRange)
                text.addAttribute(.paragraphStyle, value: listParagraphStyle, range: startRange)
                previousParagraphIsListStart = true
            } else if previousParagraphIsListStart {
                text.removeAttribute(.paragraphStyle, range: range)
                text.addAttribute(.paragraphStyle, value: listParagraphStyle, range: range)
                previousParagraphIsListStart = false
            }
        }
    }
    
    private static func removeTrailingNewlines(in text: NSMutableAttributedString) {
        while text.string.hasSuffix("\n") {
            let range = NSRange(location: text.string.count - 1, length: 1)
            text.replaceCharacters(in: range, with: "")
        }
    }
}
