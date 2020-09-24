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
        case .firstName: return "Voornaam"
        case .lastName: return "Achternaam"
        case .phoneNumber: return "Telefoonnummer"
        case .email: return "E-mailadres"
        case .relation: return "Wat is dit van je?"
        case .birthDate: return "Geboortedatum"
        case .bsn: return "Burgerservice nummer"
        case .profession: return "Beroep"
        case .companyName: return "Naam bedrijf/vereniging"
        case .notes: return "Toelichting"
        }
    }
}

class EditContactViewModel {
    let contact: Contact
    let title: String
    
    init(contact: CNContact) {
        self.contact = Contact(type: .roommate, cnContact: contact)
        self.title = contact.fullName
    }
    
    init(contact: Contact) {
        self.contact = contact
        self.title = contact.fullName
    }
    
    typealias Input = (label: String, text: String?)
    
    enum Row {
        case group([Input])
        case single(Input)
    }
    
    private func values(for field: ContactField) -> [String?] {
        return contact.values
            .filter { $0.field == field }
            .map { $0.value }
    }
    
    var rows: [Row] {
        let inputs = contact.type.requiredFields.flatMap { field -> [Input] in
            values(for: field)
                .map { Input(label: field.label, text: $0) }
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
    
    weak var delegate: EditContactViewControllerDelegate?
    
    init(viewModel: EditContactViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = viewModel.title
        
        promptView = Button(title: "Opslaan")
            .touchUpInside(self, action: #selector(save))
        
        let scrollView = UIScrollView()
        scrollView.embed(in: contentView)
        scrollView.preservesSuperviewLayoutMargins = true
        scrollView.keyboardDismissMode = .onDrag
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        
        func createTextField(_ input: EditContactViewModel.Input) -> TextField {
            return TextField(label: input.label, text: input.text)
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
    }
    
    @objc private func save() {
        delegate?.editContactViewController(self, didSave: viewModel.contact)
    }

}

