/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

enum ContactDetails {
    case name(String)
    case phoneNumber(String)
    case email(String)
    case birthday(DateComponents)
    case address(CNPostalAddress)
}

class SelectContactDetailsViewModel {
    private let contact: CNContact
    private let tableViewManager: TableViewManager<ContactDetailsTableViewCell>
    
    init(contact: CNContact) {
        self.contact = contact
        
        tableViewManager = .init()
        
        var details = [ContactDetails]()
        
        if contact.isKeyAvailable(CNContactPhoneNumbersKey) {
            contact.phoneNumbers.forEach {
                details.append(.phoneNumber($0.value.stringValue))
            }
        }
        
        if contact.isKeyAvailable(CNContactEmailAddressesKey) {
            contact.emailAddresses.forEach {
                details.append(.email($0.value as String))
            }
        }
        
        if contact.isKeyAvailable(CNContactBirthdayKey), let dateComponents = contact.birthday {
            details.append(.birthday(dateComponents))
        }
        
        if contact.isKeyAvailable(CNContactPostalAddressesKey) {
            contact.postalAddresses.forEach {
                details.append(.address($0.value))
            }
        }
        
        tableViewManager.numberOfRowsInSection = { _ in details.count }
        tableViewManager.itemForCellAtIndexPath = { details[$0.row] }
        tableViewManager.titleForHeaderInSection = { _ in "Welke contactgegevens wil je delen?" }
    }
    
    var title: String {
        return contact.fullName
    }
    
    func setupTableView(_ tableView: UITableView) {
        tableViewManager.manage(tableView)
    }
}

protocol SelectContactDetailsViewControllerDelegate: class {
    func selectContactDetailsViewControllerDidFinish(_ controller: SelectContactDetailsViewModel)
}

final class SelectContactDetailsViewController: UIViewController {
    private let viewModel: SelectContactDetailsViewModel
    private let tableView: UITableView = .createDefaultGrouped()
    
    weak var delegate: SelectContactDetailsViewControllerDelegate?
    
    init(viewModel: SelectContactDetailsViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        view.backgroundColor = .white
        title = viewModel.title
        
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.embed(in: view)
        viewModel.setupTableView(tableView)
    }

}

final class ContactDetailsTableViewCell: UITableViewCell, Configurable, Reusable {
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .default, reuseIdentifier: reuseIdentifier)
        build()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func configure(_ item: ContactDetails) {
        let birthdayFormatter = DateFormatter()
        birthdayFormatter.dateStyle = .long
        
        switch item {
        case .name(let name):
            titleLabel.text = name
        case .email(let email):
            titleLabel.text = email
        case .birthday(let dateComponents):
            titleLabel.text = dateComponents.date.map { birthdayFormatter.string(from: $0) }
        case .address(let address):
            titleLabel.text = CNPostalAddressFormatter.string(from: address, style: .mailingAddress)
        case .phoneNumber(let number):
            titleLabel.text = number
        }
    }

    private func build() {
        separatorView.backgroundColor = UIColor(white: 0.9, alpha: 1)
        separatorView.snap(to: .bottom, of: contentView, height: 1, insets: .left(14))
        
        titleLabel.embed(in: contentView, insets: .leftRight(16) + .topBottom(12))
        titleLabel.numberOfLines = 0
        
        selectionStyle = .none
        accessoryType = .checkmark
    }

    // MARK: - Private

    private let separatorView = UIView()
    private let titleLabel = UILabel()
}

