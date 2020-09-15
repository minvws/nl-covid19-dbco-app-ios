/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class HelpViewModel {
    private let items: [HelpOverviewItem]

    init(helpItems: [HelpOverviewItem]) {
        items = helpItems
    }
    
    var rowCount: Int {
        return items.count
    }
    
    func item(at index: Int) -> HelpOverviewItem {
        return items[index]
    }
}

protocol HelpViewControllerDelegate: class {
    
    func helpViewController(_ controller: HelpViewController, didSelect item: HelpOverviewItem)
    
}

final class HelpViewController: UIViewController {
    private let viewModel: HelpViewModel
    private let tableView: UITableView = createHelpTableView()
    
    weak var delegate: HelpViewControllerDelegate?
    
    required init(viewModel: HelpViewModel) {
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
        title = .helpTitle
        
        setupTableView()
    }
    
    private func setupTableView() {
        view.addSubview(tableView)
        
        tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        
        tableView.dataSource = self
        tableView.delegate = self
        
        tableView.register(HelpItemTableViewCell.self, forCellReuseIdentifier: HelpItemTableViewCell.reuseIdentifier)
    }
    
    private static func createHelpTableView() -> UITableView {
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

// MARK: - UITableViewDataSource
extension HelpViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        viewModel.rowCount
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HelpItemTableViewCell.reuseIdentifier, for: indexPath) as! HelpItemTableViewCell
        cell.configure(for: viewModel.item(at: indexPath.row))
        return cell
    }
    
}

// MARK: - UITableViewDelegate
extension HelpViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        delegate?.helpViewController(self, didSelect: viewModel.item(at: indexPath.row))
    }
    
}


