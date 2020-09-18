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
    private var searchResults: [CNContact]
    
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
        
        searchResults = []
    }
    
    var rowCount: Int {
        return contacts.count
    }
    
    func contact(at index: Int) -> CNContact {
        return contacts[index]
    }
    
    var searchText: String? {
        didSet {
            if let searchText = searchText, !searchText.isEmpty {
                searchResults = contacts.filter { $0.fullName.lowercased().contains(searchText.lowercased())}
            } else {
                searchResults = []
            }
        }
    }
    
    var searchResultRowCount: Int {
        return searchResults.count
    }
    
    func searchResult(at index: Int) -> CNContact {
        return searchResults[index]
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
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: ContactTableViewCell.reuseIdentifier)
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
        searchResultsController.reload()
    }

}

extension SelectContactViewController: SearchResultsViewControllerDelegate {
    
    fileprivate func searchResultsViewController(_ controller: SearchResultsViewController, didSelect contact: CNContact) {
        delegate?.selectContactViewController(self, didSelect: contact)
    }
    
}

extension SelectContactViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as! ContactTableViewCell
        cell.configure(for: viewModel.contact(at: indexPath.row))
        return cell
    }
    
}

extension SelectContactViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        delegate?.selectContactViewController(self, didSelect: viewModel.contact(at: indexPath.row))
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
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(ContactTableViewCell.self, forCellReuseIdentifier: ContactTableViewCell.reuseIdentifier)
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
    
    func reload() {
        tableView.reloadData()
    }
    
}

extension SearchResultsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.searchResultRowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactTableViewCell.reuseIdentifier, for: indexPath) as! ContactTableViewCell
        cell.configure(for: viewModel.searchResult(at: indexPath.row))
        return cell
    }
    
}

extension SearchResultsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        delegate?.searchResultsViewController(self, didSelect: viewModel.searchResult(at: indexPath.row))
    }
    
}
