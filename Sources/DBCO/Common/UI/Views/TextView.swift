/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class TextView: UITextView, UITextViewDelegate {
    
    private var linkHandlers = [(URL) -> Void]()
    private var textChangedHandlers = [(String?) -> Void]()
    
    init(htmlText: String, font: UIFont = Theme.fonts.body, textColor: UIColor = Theme.colors.captionGray, boldTextColor: UIColor = .black) {
        super.init(frame: .zero, textContainer: nil)
        setup()
        
        html(htmlText, font: font, textColor: textColor, boldTextColor: boldTextColor)
    }
    
    init(text: String? = nil) {
        super.init(frame: .zero, textContainer: nil)
        setup()
        
        self.text = text
    }
    
    init(attributedText: NSAttributedString) {
        super.init(frame: .zero, textContainer: nil)
        setup()
        
        self.attributedText = attributedText
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup() {
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
    
    override var intrinsicContentSize: CGSize {
        let superSize = super.intrinsicContentSize
        
        if isEditable {
            return CGSize(width: 200, height: max(114, superSize.height))
        } else {
            return superSize
        }
    }
    
    @discardableResult
    func html(_ htmlText: String?, font: UIFont = Theme.fonts.body, textColor: UIColor = Theme.colors.captionGray, boldTextColor: UIColor = .black) -> Self {
        attributedText = .makeFromHtml(text: htmlText, font: font, textColor: textColor, boldTextColor: boldTextColor)
        return self
    }
    
    @discardableResult
    func linkTouched(handler: @escaping (URL) -> Void) -> Self {
        isSelectable = true
        linkHandlers.append(handler)
        return self
    }
    
    @discardableResult
    func textChanged(handler: @escaping (String?) -> Void) -> Self {
        isSelectable = true
        textChangedHandlers.append(handler)
        return self
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        switch interaction {
        case .invokeDefaultAction:
            linkHandlers.forEach { $0(URL) }
        default:
            return false
        }
        
        return false
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        textChangedHandlers.forEach { $0(textView.text) }
    }
    
}
