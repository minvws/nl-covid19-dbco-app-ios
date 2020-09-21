/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

extension CNContact {
    var fullName: String {
        return CNContactFormatter.string(from: self, style: .fullName) ?? ""
    }
}

class SelectContactViewModel {
    
    private let contactStore = CNContactStore()
    private let contacts: [CNContact]
    private let suggestedContacts: [CNContact]
    private var searchResults: [CNContact]
    
    private let contactTableViewManager: TableViewManager<ContactTableViewCell>
    private let searchTableViewManager: TableViewManager<ContactTableViewCell>
    
    init(suggestedName: String? = nil) {
        let keys = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactBirthdayKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPostalAddressesKey as CNKeyDescriptor,
            CNContactTypeKey as CNKeyDescriptor
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .familyName
        
        do {
            var contacts = [CNContact]()
            try contactStore.enumerateContacts(with: request) { contact, stop in
                if contact.contactType == .person {
                    contacts.append(contact)
                }
            }
            self.contacts = contacts
        } catch {
            contacts = []
        }
        
        if let suggestedNameParts = suggestedName?.lowercased().split(separator: " ") {
            func calculateMatchedParts(for contact: CNContact) -> Int {
                let contactNameParts = contact.fullName.lowercased().split(separator: " ")
                return suggestedNameParts
                    .filter { contactNameParts.contains($0) }
                    .count
            }
            
            let sortedSuggestions = contacts
                .map { (contact: $0, matchedParts: calculateMatchedParts(for: $0)) }
                .filter { $0.matchedParts > 0 }
                .sorted { $0.matchedParts > $1.matchedParts }
            
            suggestedContacts = sortedSuggestions.map { $0.contact }
        } else {
            suggestedContacts = []
        }
        
        searchResults = []
        
        contactTableViewManager = .init()
        searchTableViewManager = .init()
        
        var sections = [(title: String, contacts: [CNContact])]()
        
        if !suggestedContacts.isEmpty {
            sections.append(("Waarschijnlijk zoek je", suggestedContacts))
        }
        
        sections.append(("Andere contacten", contacts))
        
        contactTableViewManager.numberOfSections = { sections.count }
        contactTableViewManager.numberOfRowsInSection = { sections[$0].contacts.count }
        contactTableViewManager.itemForCellAtIndexPath = { sections[$0.section].contacts[$0.row] }
        contactTableViewManager.titleForHeaderInSection = { sections.count > 1 ? sections[$0].title : nil }
        
        searchTableViewManager.numberOfRowsInSection = { [unowned self] _ in self.searchResults.count }
        searchTableViewManager.itemForCellAtIndexPath = { [unowned self] in self.searchResults[$0.row] }
        
    }
    
    private var numberOfSections: Int {
        return suggestedContacts.isEmpty ? 1 : 2
    }
    
    var searchText: String? {
        didSet {
            if let searchText = searchText, !searchText.isEmpty {
                searchResults = contacts.filter { $0.fullName.lowercased().contains(searchText.lowercased())}
            } else {
                searchResults = []
            }
            
            searchTableViewManager.reloadData()
        }
    }
    
    func setupContactsTableView(_ tableView: UITableView, selectedContactHandler: @escaping (CNContact) -> Void) {
        contactTableViewManager.manage(tableView)
        contactTableViewManager.didSelectItem = selectedContactHandler
    }
    
    func setupSearchTableView(_ tableView: UITableView, selectedContactHandler: @escaping (CNContact) -> Void) {
        searchTableViewManager.manage(tableView)
        searchTableViewManager.didSelectItem = selectedContactHandler
    }
    
    
}

protocol SelectContactViewControllerDelegate: class {
    
    func selectContactViewController(_ controller: SelectContactViewController, didSelect contact: CNContact)
    
}

class SelectContactViewController: UIViewController {
    private let viewModel: SelectContactViewModel
    private let searchResultsController: SearchResultsViewController
    private let tableView: UITableView = createContactsTableView()
    private let searchController: UISearchController
    
    weak var delegate: SelectContactViewControllerDelegate?
    
    init(viewModel: SelectContactViewModel) {
        self.viewModel = viewModel
        self.searchResultsController = SearchResultsViewController(viewModel: viewModel)
        self.searchController = UISearchController(searchResultsController: self.searchResultsController)
        
        super.init(nibName: nil, bundle: nil)
        
        self.searchResultsController.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        title = "Contact toevoegen"
        view.backgroundColor = .white
        
        setupTableView()
        setupSearchController()
    }
    
    private func setupTableView() {
        tableView.embed(in: view)
        viewModel.setupContactsTableView(tableView) { [weak self] contact in
            guard let self = self else { return }
            self.delegate?.selectContactViewController(self, didSelect: contact)
        }
    }
    
    private func setupSearchController() {
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Naam contact"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }
    
    private static func createContactsTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = true

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension

        tableView.estimatedSectionHeaderHeight = 50
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.allowsMultipleSelection = false
        tableView.tableFooterView = UIView()
        return tableView
    }
    
}

extension SelectContactViewController: UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        viewModel.searchText = searchController.searchBar.text
    }

}

extension SelectContactViewController: SearchResultsViewControllerDelegate {
    
    fileprivate func searchResultsViewController(_ controller: SearchResultsViewController, didSelect contact: CNContact) {
        delegate?.selectContactViewController(self, didSelect: contact)
    }
    
}

// MARK: - Search Results
private protocol SearchResultsViewControllerDelegate: class {
    
    func searchResultsViewController(_ controller: SearchResultsViewController, didSelect contact: CNContact)
    
}

private class SearchResultsViewController: UIViewController {
    private let viewModel: SelectContactViewModel
    private let tableView: UITableView = createContactsTableView()
    private let searchController = UISearchController(searchResultsController: nil)
    
    weak var delegate: SearchResultsViewControllerDelegate?
    
    init(viewModel: SelectContactViewModel) {
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
        setupTableView()
    }
    
    private func setupTableView() {
        tableView.embed(in: view)
        viewModel.setupSearchTableView(tableView) { [weak self] contact in
            guard let self = self else { return }
            self.delegate?.searchResultsViewController(self, didSelect: contact)
        }
    }
    
    private static func createContactsTableView() -> UITableView {
        let tableView = UITableView(frame: .zero, style: .grouped)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        tableView.separatorStyle = .none
        tableView.backgroundColor = .clear

        tableView.showsVerticalScrollIndicator = true
        tableView.showsHorizontalScrollIndicator = false
        tableView.isScrollEnabled = true

        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableView.automaticDimension

        tableView.estimatedSectionHeaderHeight = 50
        tableView.sectionHeaderHeight = UITableView.automaticDimension

        tableView.allowsMultipleSelection = false
        tableView.tableFooterView = UIView()
        return tableView
    }
    
}
