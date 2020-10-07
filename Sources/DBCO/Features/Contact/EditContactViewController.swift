/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

class EditContactViewModel {
    private(set) var contact: Contact
    let title: String
    let showCancelButton: Bool
    
    init(contact: CNContact, showCancelButton: Bool = false) {
        self.contact = Contact(type: .roommate, cnContact: contact)
        self.title = contact.fullName
        self.showCancelButton = showCancelButton
    }
    
    init(contact: Contact, showCancelButton: Bool = false) {
        self.contact = contact.copy() as! Contact
        self.title = contact.fullName.isEmpty ? .contactFallbackTitle : contact.fullName
        self.showCancelButton = showCancelButton
    }
    
    enum Row {
        case group([UIView])
        case single(UIView)
    }
    
    var rows: [Row] {
        let firstNameField = InputField(for: contact, path: \.firstName)
        let lastNameField = InputField(for: contact, path: \.lastName)
        
        let phoneNumberFields = contact.phoneNumbers.indices
            .map { \Contact.phoneNumbers[$0] }
            .map { InputField(for: contact, path: $0) }
            .map(Row.single)
        
        let emailFields = contact.emailAddresses.indices
            .map { \Contact.emailAddresses[$0] }
            .map { InputField(for: contact, path: $0) }
            .map(Row.single)
        
        var base = [Row.group([firstNameField, lastNameField])]
        base += phoneNumberFields
        base += emailFields
        
        return base + [
            .single(InputField(for: contact, path: \.relationType)),
            .single(InputField(for: contact, path: \.birthDate)),
            .single(InputField(for: contact, path: \.bsn)),
            .single(InputField(for: contact, path: \.profession)),
            .single(InputField(for: contact, path: \.notes))
        ]
    }
}

protocol EditContactViewControllerDelegate: class {
    func editContactViewControllerDidCancel(_ controller: EditContactViewController)
    func editContactViewController(_ controller: EditContactViewController, didSave contact: Contact)
    
}

final class EditContactViewController: PromptableViewController {
    private let viewModel: EditContactViewModel
    private let scrollView = UIScrollView()
    
    weak var delegate: EditContactViewControllerDelegate?
    
    init(viewModel: EditContactViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = viewModel.title
        
        if viewModel.showCancelButton {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        }
        
        promptView = Button(title: .save)
            .touchUpInside(self, action: #selector(save))
        
        scrollView.embed(in: contentView)
        scrollView.keyboardDismissMode = .interactive
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        
        let rows = viewModel.rows.map { row -> UIView in
            switch row {
            case .group(let fields):
                return UIStackView(horizontal: fields, spacing: 15).distribution(.fillEqually)
            case .single(let field):
                return field
            }
        }
        
        let contactTypeSection = SectionView(title: "Aard van het contact", caption: "Vragen over jullie ontmoeting", index: 1)
        contactTypeSection.isCompleted = true
        contactTypeSection.collapse(animated: false)
        
        let contactDetailsSection = SectionView(title: "Contactgegevens", caption: "Vul contactgegevens aan", index: 2)
        UIStackView(vertical: rows, spacing: 16)
            .embed(in: contactDetailsSection.contentView.readableWidth)
        
        let informContactSection = SectionView(title: "Informeren", caption: "Deel het handelingsperspectief", index: 3)
        informContactSection.collapse(animated: false)
        
        VStack(contactTypeSection,
               contactDetailsSection,
               informContactSection)
            .embed(in: scrollView)
        
        registerForKeyboardNotifications()
    }
    
    private var contactDetailsSection: SectionView!
    
    @objc private func save() {
        delegate?.editContactViewController(self, didSave: viewModel.contact)
    }
    
    @objc private func cancel() {
        delegate?.editContactViewControllerDidCancel(self)
    }
    
    // MARK: - Keyboard handling
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        
        let convertedFrame = view.window?.convert(endFrame, to: contentView)
        
        let inset = contentView.frame.maxY - (convertedFrame?.minY ?? 0)
        
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets.bottom = .zero
    }

}
