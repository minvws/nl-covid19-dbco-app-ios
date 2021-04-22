/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol UnfinishedTasksViewControllerDelegate: class {
    func unfinishedTasksViewController(_ controller: UnfinishedTasksViewController, didSelect task: Task)
    func unfinishedTasksViewControllerDidRequestUpload(_ controller: UnfinishedTasksViewController)
    func unfinishedTasksViewControllerDidCancel(_ controller: UnfinishedTasksViewController)
}

/// - Tag: UnfinishedTasksViewModel
class UnfinishedTasksViewModel {
    typealias SectionHeaderContent = (title: String, subtitle: String)
    
    private let tableViewManager: TableViewManager<TaskTableViewCell>
    private var tableHeaderBuilder: (() -> UIView?)?
    
    private let relevantTaskIdentifiers: [UUID]
    
    private var sections: [(header: UIView?, tasks: [Task])]
    
    init() {
        tableViewManager = .init()
        
        sections = []
        
        // Store unfisnished task identifiers now, so any completed tasks won't have to dissappear from the overview.
        relevantTaskIdentifiers = Services.caseManager.tasks
            .filter(\.isUnfinished)
            .map { $0.uuid }
        
        tableViewManager.numberOfSections = { [unowned self] in return sections.count }
        tableViewManager.numberOfRowsInSection = { [unowned self] in return sections[$0].tasks.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return sections[$0.section].tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] in return sections[$0].header }
        
        Services.caseManager.addListener(self)
    }
    
    func setupTableView(_ tableView: UITableView, tableHeaderBuilder: (() -> UIView?)?, selectedTaskHandler: @escaping (Task, IndexPath) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedTaskHandler
        self.tableHeaderBuilder = tableHeaderBuilder
        
        buildSections()
    }
    
    private func buildSections() {
        sections = []
        sections.append((tableHeaderBuilder?(), []))
        
        let tasks = Services.caseManager.tasks
            .filter { relevantTaskIdentifiers.contains($0.uuid) }
            .sorted(by: <)
        
        sections.append((nil, tasks))
    }
}

extension UnfinishedTasksViewModel: CaseManagerListener {
    func caseManagerDidUpdateTasks(_ caseManager: CaseManaging) {
        buildSections()
        tableViewManager.reloadData()
    }
    
    func caseManagerDidUpdateSyncState(_ caseManager: CaseManaging) {}
    
    func caseManagerWindowExpired(_ caseManager: CaseManaging) {}
}

/// - Tag: UnfinishedTasksViewControllers
class UnfinishedTasksViewController: PromptableViewController {
    private let viewModel: UnfinishedTasksViewModel
    private let tableView = UITableView.createDefaultGrouped()
    
    weak var delegate: UnfinishedTasksViewControllerDelegate?
    
    required init(viewModel: UnfinishedTasksViewModel) {
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
        title = .unfinishedTasksOverviewTitle
        navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        setupTableView()
        
        promptView = Button(title: .taskOverviewDoneButtonTitle)
            .touchUpInside(self, action: #selector(upload))
    }
    
    private func setupTableView() {
        tableView.embed(in: contentView, preservesSuperviewLayoutMargins: false)
        tableView.delaysContentTouches = false
        
        let tableHeaderBuilder = {
            UILabel(title2: .unfinishedTasksOverviewMessage)
                .multiline()
                .wrappedInReadableWidth(insets: .top(60))
        }
        
        viewModel.setupTableView(tableView, tableHeaderBuilder: tableHeaderBuilder) { [weak self] task, indexPath in
            guard let self = self else { return }
            
            self.delegate?.unfinishedTasksViewController(self, didSelect: task)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @objc private func cancel() {
        delegate?.unfinishedTasksViewControllerDidCancel(self)
    }
    
    @objc private func upload() {
        delegate?.unfinishedTasksViewControllerDidRequestUpload(self)
    }

}
