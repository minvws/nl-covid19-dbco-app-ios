/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class ContactListInputView: UIView {
    private let textFieldStack = VStack()
    private let placeholder: String?
    
    init(placeholder: String) {
        self.placeholder = placeholder
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        self.placeholder = nil
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        textFieldStack
            .snap(to: .top, of: self)
        
        addContactField()
        
        textFieldStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
    }
    
    private func addContactField() {
        let textField = ContactTextField(placeholder: placeholder)
        textField.addTarget(self, action: #selector(editingDidEndOnExit), for: .editingDidEndOnExit)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        
        textFieldStack.addArrangedSubview(textField)
    }
    
    @objc private func editingChanged(_ sender: ContactTextField) {
        guard let index = textFieldStack.arrangedSubviews.firstIndex(of: sender) else { return }
        let isLastField = textFieldStack.arrangedSubviews.count - 1 == index
        
        if sender.text?.isEmpty == false, isLastField {
            addContactField()
        }
    }
    
    @objc private func editingDidEndOnExit(_ sender: ContactTextField) {
        
    }
    
    @objc private func editingDidEnd(_ sender: ContactTextField) {
        guard let index = textFieldStack.arrangedSubviews.firstIndex(of: sender) else { return }
        let isLastField = textFieldStack.arrangedSubviews.count - 1 == index
        
        if sender.text?.isEmpty == true, !isLastField {
            sender.removeFromSuperview()
        }
    }
}

private class ContactTextField: UITextField {
    
    init(placeholder: String?, text: String? = nil) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        self.text = text
        setup()
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        font = Theme.fonts.body
        
        iconView.contentMode = .center
        iconView.snap(to: .left, of: self)
        iconView.tintColor = Theme.colors.primary
        
        attributedPlaceholder = NSAttributedString(string: placeholder ?? "", attributes: [
            .font: Theme.fonts.body,
            .foregroundColor: Theme.colors.disabledBorder
        ])
        
        clearButton.setImage(UIImage(named: "DeleteContact"), for: .normal)
        clearButton.tintColor = Theme.colors.primary
        clearButton.backgroundColor = .white
        clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
        
        rightView = clearButton
        rightViewMode = .whileEditing
        
        SeparatorView().snap(to: .bottom, of: self, insets: .left(Constants.inset) + .right(-Constants.inset))
        
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        
        editingChanged()
        
        textContentType = .name
        autocapitalizationType = .words
        enablesReturnKeyAutomatically = true
    }
    
    @objc private func editingChanged() {
        iconView.isHighlighted = text?.isEmpty == false
        clearButton.isHidden = text?.isEmpty == true
    }
    
    @objc func clear() {
        text = nil
        sendActions(for: .editingChanged)
    }
    
    private func textContentsRect(forBounds bounds: CGRect) -> CGRect {
        var rect = bounds
        rect.origin.x += Constants.inset
        rect.size.width -= Constants.inset
        return rect
    }
    
    override func editingRect(forBounds bounds: CGRect) -> CGRect {
        return textContentsRect(forBounds: bounds)
    }
    
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect {
        return textContentsRect(forBounds: bounds)
    }
    
    override func borderRect(forBounds bounds: CGRect) -> CGRect {
        return textContentsRect(forBounds: bounds)
    }
    
    override func textRect(forBounds bounds: CGRect) -> CGRect {
        return textContentsRect(forBounds: bounds)
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: 100, height: height)
    }
    
    // MARK: - Private
    
    private struct Constants {
        static let inset: CGFloat = 40
    }
    
    private var height: CGFloat {
        return ceil(font!.lineHeight + 1) + 26
    }
    
    private let iconView = UIImageView(image: UIImage(named: "AddContact"),
                                       highlightedImage: UIImage(named: "Contact"))
    private let clearButton = UIButton(type: .system)
}
