/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

protocol ContactListInputViewDelegate: AnyObject {
    func contactListInputView(_ view: ContactListInputView, didBeginEditingIn textField: UITextField)
    func contactListInputView(_ view: ContactListInputView, didEndEditingIn textField: UITextField)
    func viewForPresentingSuggestionsFromContactListInputView(_ view: ContactListInputView) -> UIView
    func contactsAvailableForSuggestionInContactListInputView(_ view: ContactListInputView) -> [CNContact]
}

/// An auto expanding list of names. When the app has permission to acces Contacts, tappable suggestions will be shown on the view provided by the delegate.
///
/// - Tag: ContactListInputView
class ContactListInputView: UIView {
    struct Contact {
        var name: String
        var cnContactIdentifier: String?
    }
    
    weak var delegate: ContactListInputViewDelegate?
    
    private let textFieldStack = VStack()
    private let placeholder: String?
    
    private var activeField: ContactTextField?
    
    var contacts: [Contact] {
        get { listContacts() }
        set { createFields(for: newValue) }
    }
    
    private var availableContacts: [CNContact] = []
    private var activeSuggestions: [CNContact] = [] {
        didSet { updateSuggestionView() }
    }
    private weak var suggestionPresenter: UIView?
    
    private var suggestionContainerView: UIView!
    private var suggestedNamesStackView: UIStackView!
    
    init(placeholder: String, contacts: [Contact] = [], delegate: ContactListInputViewDelegate? = nil) {
        self.placeholder = placeholder
        self.delegate = delegate
        super.init(frame: .zero)
        setup(with: contacts)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setup(with contacts: [Contact]) {
        textFieldStack
            .snap(to: .top, of: self)
        
        textFieldStack.bottomAnchor.constraint(lessThanOrEqualTo: bottomAnchor).isActive = true
        
        createFields(for: contacts)
        
        suggestionContainerView = UIView()
        let backgroundView = UIImageView(image: UIImage(named: "ContactSuggestionBackground"))
        backgroundView.contentMode = .scaleToFill
        backgroundView.embed(in: suggestionContainerView,
                             insets: UIEdgeInsets(top: -14, left: -16, bottom: -18, right: -16))
        
        suggestedNamesStackView = VStack().embed(in: suggestionContainerView)
    }
    
    private func createFields(for contacts: [Contact]) {
        textFieldStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        contacts.forEach(addContactField)
        addContactField()
    }
    
    private func listContacts() -> [Contact] {
        func trimName(_ name: String) -> String {
            return name
                .components(separatedBy: .whitespacesAndNewlines)
                .filter { !$0.isEmpty } 
                .joined(separator: " ")
        }
 
        return textFieldStack.arrangedSubviews
            .compactMap { $0 as? ContactTextField }
            .filter { $0.text?.isEmpty == false }
            .map { Contact(name: trimName($0.text!), cnContactIdentifier: $0.acceptedSuggestedContactIdentifier) }
    }
    
    private func addContactField(for contact: Contact? = nil) {
        let textField = ContactTextField(placeholder: placeholder, text: contact?.name)
        textField.acceptedSuggestedContactIdentifier = contact?.cnContactIdentifier
        textField.addTarget(self, action: #selector(editingDidBegin), for: .editingDidBegin)
        textField.addTarget(self, action: #selector(editingDidEndOnExit), for: .editingDidEndOnExit)
        textField.addTarget(self, action: #selector(editingDidEnd), for: .editingDidEnd)
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        
        textFieldStack.addArrangedSubview(textField)
    }
    
    @objc private func editingDidBegin(_ sender: ContactTextField) {
        activeField = sender
        availableContacts = delegate?.contactsAvailableForSuggestionInContactListInputView(self) ?? []
        suggestionPresenter = delegate?.viewForPresentingSuggestionsFromContactListInputView(self)
        delegate?.contactListInputView(self, didBeginEditingIn: sender)
    }
    
    @objc private func editingChanged(_ sender: ContactTextField) {
        activeSuggestions = ContactSuggestionHelper.suggestions(for: sender.text ?? "", in: availableContacts)
        
        guard let index = textFieldStack.arrangedSubviews.firstIndex(of: sender) else { return }
        let isLastField = textFieldStack.arrangedSubviews.count - 1 == index
        
        sender.acceptedSuggestedContactIdentifier = nil
        
        if sender.text?.isEmpty == false, isLastField {
            addContactField()
        }
    }
    
    @objc private func editingDidEndOnExit(_ sender: ContactTextField) {
        // This will dismiss the keyboard
    }
    
    @objc private func editingDidEnd(_ sender: ContactTextField) {
        availableContacts = []
        activeSuggestions = []
        activeField = nil
        
        guard let index = textFieldStack.arrangedSubviews.firstIndex(of: sender) else { return }
        let isLastField = textFieldStack.arrangedSubviews.count - 1 == index
        
        if sender.text?.isEmpty == true, !isLastField {
            sender.removeFromSuperview()
        }
        
        delegate?.contactListInputView(self, didEndEditingIn: sender)
    }
    
    private func updateSuggestionView() {
        guard !activeSuggestions.isEmpty else {
            suggestionContainerView.removeFromSuperview()
            return
        }
        
        guard let suggestionPresenter = suggestionPresenter else { return }
        
        suggestionPresenter.addSubview(suggestionContainerView)
        suggestedNamesStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        activeSuggestions
            .prefix(5)
            .forEach { contact in
            suggestedNamesStackView.addArrangedSubview(SuggestionButton(contact: contact)
                                                        .touchUpInside(self, action: #selector(acceptSuggestion)))
            suggestedNamesStackView.addArrangedSubview(SeparatorView().withInsets(.left(16)))
        }
        
        suggestedNamesStackView.arrangedSubviews.last?.removeFromSuperview() // remove last separator
        
        let height = suggestedNamesStackView.systemLayoutSizeFitting(CGSize(width: 200, height: 48)).height
        
        let verticalOffset = (activeField?.frame.maxY ?? 0) - 3
        let suggestionFrame = CGRect(x: 35, y: verticalOffset, width: bounds.width - 39, height: height)
        
        suggestionContainerView.frame = suggestionPresenter.convert(suggestionFrame, from: self)
    }
    
    @objc private func acceptSuggestion(_ sender: SuggestionButton) {
        activeField?.text = sender.contact.fullName
        activeField?.acceptedSuggestedContactIdentifier = sender.contact.identifier
        activeField?.endEditing(false)
    }
    
    func hideSuggestions() {
        suggestionContainerView.removeFromSuperview()
    }
    
    func scrollTextFieldToVisible(_ textField: UITextField, in scrollView: UIScrollView) {
        // Next runcycle so keyboard size is properly incorporated
        DispatchQueue.main.async {
            let convertedBounds = scrollView.convert(textField.bounds, from: textField)
            let extraMargin = UIEdgeInsets(top: 32, left: 0, bottom: 200, right: 0)
            let visibleHeight =
                scrollView.bounds.height -
                scrollView.safeAreaInsets.top -
                scrollView.safeAreaInsets.bottom -
                scrollView.contentInset.bottom
        
            let minOffset = convertedBounds.minY - (scrollView.safeAreaInsets.top + extraMargin.top)
            let maxOffset = minOffset - visibleHeight + convertedBounds.height + extraMargin.bottom
            let currentOffset = scrollView.contentOffset.y
            
            if self.traitCollection.verticalSizeClass == .compact {
                scrollView.setContentOffset(CGPoint(x: 0, y: minOffset), animated: true)
            } else if currentOffset > minOffset {
                scrollView.setContentOffset(CGPoint(x: 0, y: minOffset), animated: true)
            } else if currentOffset < maxOffset {
                scrollView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: true)
            }
        }
    }
    
    private class SuggestionButton: UIButton {
        let contact: CNContact
        
        required init(contact: CNContact) {
            self.contact = contact
            super.init(frame: .zero)

            self.setTitle(contact.fullName, for: .normal)
            self.titleLabel?.font = Theme.fonts.body
            setTitleColor(.black, for: .normal)
            
            contentEdgeInsets = .topBottom(13.5) + .leftRight(16)
            contentHorizontalAlignment = .left
        }

        required init?(coder aDecoder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
        
        @discardableResult
        func touchUpInside(_ target: Any?, action: Selector) -> Self {
            super.addTarget(target, action: action, for: .touchUpInside)
            return self
        }
    }
}

private class ContactTextField: UITextField {
    var acceptedSuggestedContactIdentifier: String?
    
    init(placeholder: String?, text: String? = nil) {
        super.init(frame: .zero)
        self.placeholder = placeholder
        self.text = text
        
        accessibilityLabel = placeholder
        setup()
        
    }
    
    override var accessibilityValue: String? {
        get { return text }
        set { super.accessibilityValue = newValue }
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
        
        let deleteIcon = UIImage(named: "DeleteContact")!
        clearButton.setImage(deleteIcon, for: .normal)
        clearButton.tintColor = Theme.colors.primary
        clearButton.backgroundColor = .white
        clearButton.addTarget(self, action: #selector(clear), for: .touchUpInside)
        clearButton.bounds = CGRect(origin: .zero, size: deleteIcon.size)
        clearButton.accessibilityLabel = .delete
        
        rightView = clearButton
        rightViewMode = .whileEditing
        
        SeparatorView().snap(to: .bottom, of: self, insets: .left(Constants.insets.left) + .right(-Constants.insets.left))
        
        addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        
        editingChanged()
        
        textContentType = .name
        autocapitalizationType = .words
        autocorrectionType = .no
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
        rect.origin.x += Constants.insets.left
        rect.size.width -= Constants.insets.left + Constants.insets.right
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
        static let insets: UIEdgeInsets = .leftRight(40)
    }
    
    private var height: CGFloat {
        return ceil(font!.lineHeight + 1) + 26
    }
    
    private let iconView = UIImageView(image: UIImage(named: "AddContact"),
                                       highlightedImage: UIImage(named: "Contact"))
    private let clearButton = UIButton(type: .system)
}
