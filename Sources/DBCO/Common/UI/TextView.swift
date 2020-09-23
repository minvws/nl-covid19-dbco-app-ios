/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class TextView: UITextView, UITextViewDelegate {
    
    private var linkHandlers = [(URL) -> Void]()
    
    init(htmlText: String) {
        super.init(frame: .zero, textContainer: nil)
        setup()
        
        attributedText = .makeFromHtml(text: htmlText, font: Theme.fonts.body, textColor: Theme.colors.captionGray)
    }
    
    init(text: String) {
        super.init(frame: .zero, textContainer: nil)
        setup()
        
        self.text = text
    }
    
    init(attributedText: NSAttributedString) {
        super.init(frame: .zero, textContainer: nil)
        setup()
        
        self.attributedText = attributedText
    }
    
    private func setup() {
        isScrollEnabled = false
        isEditable = false
        delegate = self
        textContainerInset = .zero
        textContainer.lineFragmentPadding = 0
        linkTextAttributes = [
            .foregroundColor: Theme.colors.primary,
            .underlineColor: UIColor.clear]
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @discardableResult
    func linkTouched(handler: @escaping (URL) -> Void) -> Self {
        linkHandlers.append(handler)
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
    
}
