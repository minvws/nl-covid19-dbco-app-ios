/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol TaskOverviewViewControllerDelegate: class {
    func taskOverviewViewControllerDidRequestHelp(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestAddContact(_ controller: TaskOverviewViewController)
    func taskOverviewViewController(_ controller: TaskOverviewViewController, didSelect task: Task)
}

class TaskOverviewViewModel {
    private let tableViewManager: TableViewManager<TaskTableViewCell>
    private let taskManager: TaskManager
    private var headerViewBuilder: (() -> UIView?)?
    private var footerViewBuilder: (() -> UIView?)?
    
    init(taskManager: TaskManager) {
        self.taskManager = taskManager
        
        tableViewManager = .init()
        
        tableViewManager.numberOfRowsInSection = { [unowned self] _ in return self.taskManager.tasks.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return self.taskManager.tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] _ in return self.headerViewBuilder?() }
        tableViewManager.viewForFooterInSection = { [unowned self] _ in return self.footerViewBuilder?() }
        
        taskManager.addListener(self)
    }
    
    func setupTableView(_ tableView: UITableView, headerViewBuilder: (() -> UIView?)?, footerViewBuilder: (() -> UIView?)?, selectedTaskHandler: @escaping (Task, IndexPath) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedTaskHandler
        self.headerViewBuilder = headerViewBuilder
        self.footerViewBuilder = footerViewBuilder
    }
}

extension TaskOverviewViewModel: TaskManagerListener {
    func taskManagerDidUpdateTasks(_ taskManager: TaskManager) {
        tableViewManager.reloadData()
    }
}

class TaskOverviewViewController: PromptableViewController {
    private let viewModel: TaskOverviewViewModel
    private let tableView = UITableView.createDefaultGrouped()
    
    weak var delegate: TaskOverviewViewControllerDelegate?
    
    required init(viewModel: TaskOverviewViewModel) {
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
        title = .taskOverviewTitle
        
        setupTableView()
        
        promptView = Button(title: .taskOverviewDoneButtonTitle)
    }
    
    private func setupTableView() {
        tableView.embed(in: contentView)
        tableView.delaysContentTouches = false
        
        let headerViewBuilder = {
            TextView(htmlText: .taskOverviewHeaderText)
                .linkTouched { [weak self] _ in self?.openHelp() }
                .wrappedInReadableContentGuide(insets: .topBottom(10))
        }
        
        let footerViewBuilder = { [unowned self] in
            Button(title: .taskOverviewAddContactButtonTitle, style: .secondary)
                .touchUpInside(self, action: #selector(requestContact))
                .wrappedInReadableContentGuide(insets: .top(5) + .bottom(10))
        }
        
        viewModel.setupTableView(tableView, headerViewBuilder: headerViewBuilder, footerViewBuilder: footerViewBuilder) { [weak self] task, indexPath in
            guard let self = self else { return }
            
            self.delegate?.taskOverviewViewController(self, didSelect: task)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        
    }
    
    @objc private func openHelp() {
        delegate?.taskOverviewViewControllerDidRequestHelp(self)
    }
    
    @objc private func requestContact() {
        delegate?.taskOverviewViewControllerDidRequestAddContact(self)
    }

}
