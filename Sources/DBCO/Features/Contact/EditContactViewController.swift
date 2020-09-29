/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

extension ContactField {
    var label: String {
        switch self {
        case .firstName: return .contactInformationFirstName
        case .lastName: return .contactInformationLastName
        case .phoneNumber: return .contactInformationPhoneNumber
        case .email: return .contactInformationEmailAddress
        case .relation: return .contactInformationRelationType
        case .birthDate: return .contactInformationBirthDate
        case .bsn: return .contactInformationBSN
        case .profession: return .contactInformationProfession
        case .companyName: return .contactInformationCompanyName
        case .notes: return .contactInformationNotes
        }
    }
}

extension FieldType {

    var inputType: TextField.InputType {
        switch self {
        case .text(let validation):
            switch validation {
            case .name:
                return .name
            case .email:
                return .email
            case .phoneNumber:
                return .number
            case .number:
                return .number
            case .general:
                return .text
            }
        case .multilineText:
            return .text
        case .date:
            return .date(Contact.birthDateFormatter)
        case .dropdown(let options):
            return .options(options)
        }
    }
}

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
        self.contact = contact
        self.title = contact.fullName
        self.showCancelButton = showCancelButton
    }
    
    struct Input {
        let label: String
        let text: String?
        let valueHandler: TextField.ValueHandler
        let validator: TextField.Validator
        let inputType: TextField.InputType
    }
    
    enum Row {
        case group([Input])
        case single(Input)
    }
    
    private func values(for field: ContactField) -> [(value: String?, identifier: UUID)] {
        return contact.values
            .filter { $0.field == field }
            .map { ($0.value, $0.identifier) }
    }
    
    var rows: [Row] {
        let inputs = contact.type.requiredFields.flatMap { [unowned self] field -> [Input] in
            values(for: field)
                .map { value, identifier in
                    Input(
                        label: field.label,
                        text: value,
                        valueHandler: { newValue in
                            contact.setValue(newValue, forFieldWithIdentifier: identifier)
                        },
                        validator: { _ in return true },
                        inputType: field.fieldType.inputType)
                }
        }
        
        let name = Row.group(Array(inputs.prefix(2)))
        let other = inputs.suffix(from: 2).map(Row.single)
        return [name] + other
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
        scrollView.preservesSuperviewLayoutMargins = true
        scrollView.keyboardDismissMode = .interactive
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        
        func createTextField(_ input: EditContactViewModel.Input) -> TextField {
            let textField = TextField(label: input.label, text: input.text)
            textField.editingDidEndHandler = input.valueHandler
            textField.inputType = input.inputType
            textField.validator = input.validator
            return textField
        }
        
        let rows = viewModel.rows.map { row -> UIView in
            switch row {
            case .group(let inputs):
                let columns = inputs.map(createTextField)
                return UIStackView(horizontal: columns, spacing: 15).distribution(.fillEqually)
            case .single(let input):
                return createTextField(input)
            }
        }
        
        UIStackView(vertical: rows, spacing: 16)
            .embed(in: scrollView.readableWidth, insets: .topBottom(32))
        
        registerForKeyboardNotifications()
    }

    
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
        
        if let firstResponder = UIResponder.currentFirstResponder as? TextField {
            let frame = firstResponder
                .convert(firstResponder.bounds, to: scrollView)
                .insetBy(dx: 0, dy: -16) // Apply some margin above and below
            
            let visibleFrame = CGRect(x: 0,
                                      y: scrollView.contentOffset.y,
                                      width: scrollView.frame.width,
                                      height: scrollView.frame.height)
                .inset(by: scrollView.contentInset)
                .inset(by: scrollView.safeAreaInsets)
            
            // cancel current animation
            scrollView.setContentOffset(scrollView.contentOffset, animated: false)
            
            if !visibleFrame.contains(frame) {
                if frame.minY < visibleFrame.minY {
                    scrollView.setContentOffset(CGPoint(x: 0,
                                                        y: frame.minY - scrollView.safeAreaInsets.top),
                                                animated: true)
                } else {
                    let delta = visibleFrame.maxY - frame.maxY
                    scrollView.setContentOffset(CGPoint(x: 0,
                                                        y: visibleFrame.minY - delta - scrollView.safeAreaInsets.top),
                                                animated: true)
                }
            }
        }
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets.bottom = .zero
    }

}

extension UIResponder {

    private static weak var _currentFirstResponder: UIResponder?

    static var currentFirstResponder: UIResponder? {
        _currentFirstResponder = nil
        UIApplication.shared.sendAction(#selector(UIResponder.findFirstResponder(_:)), to: nil, from: nil, for: nil)

        return _currentFirstResponder
    }

    @objc func findFirstResponder(_ sender: Any) {
        UIResponder._currentFirstResponder = self
    }
    
}
