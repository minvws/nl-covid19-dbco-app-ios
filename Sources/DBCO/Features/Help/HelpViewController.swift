/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

class HelpViewModel {
    private let items: [HelpOverviewItem]
    private let tableViewManager: TableViewManager<HelpItemTableViewCell>

    init(helpItems: [HelpOverviewItem]) {
        items = helpItems
        tableViewManager = .init()
        
        tableViewManager.numberOfRowsInSection = { [unowned self] _ in self.items.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in self.items[$0.row] }
    }
    
    func setupTableView(_ tableView: UITableView, selectedItemHandler: @escaping (HelpItem) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedItemHandler
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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        tableView.indexPathForSelectedRow.map { tableView.deselectRow(at: $0, animated: true) }
    }
    
    private func setupTableView() {
        tableView.embed(in: view)
        
        viewModel.setupTableView(tableView) { [weak self] item in
            guard let self = self else { return }
            self.delegate?.helpViewController(self, didSelect: item as! HelpOverviewItem)
        }
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


