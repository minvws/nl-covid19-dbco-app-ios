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

class UnfinishedTasksViewModel {
    typealias SectionHeaderContent = (title: String, subtitle: String)
    
    private let tableViewManager: TableViewManager<TaskTableViewCell>
    private let taskManager: TaskManager
    private var tableHeaderBuilder: (() -> UIView?)?
    private var sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?
    
    private let relevantTaskIdentifiers: [String]
    
    private var sections: [(header: UIView?, tasks: [Task])]
    
    init(taskManager: TaskManager) {
        self.taskManager = taskManager
        
        tableViewManager = .init()
        
        sections = []
        
        relevantTaskIdentifiers = taskManager.tasks
            .filter { $0.status != .completed }
            .map { $0.identifier }
        
        tableViewManager.numberOfSections = { [unowned self] in return sections.count }
        tableViewManager.numberOfRowsInSection = { [unowned self] in return sections[$0].tasks.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return sections[$0.section].tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] in return sections[$0].header }
        
        taskManager.addListener(self)
    }
    
    func setupTableView(_ tableView: UITableView, tableHeaderBuilder: (() -> UIView?)?, sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?, selectedTaskHandler: @escaping (Task, IndexPath) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedTaskHandler
        self.tableHeaderBuilder = tableHeaderBuilder
        self.sectionHeaderBuilder = sectionHeaderBuilder
        
        buildSections()
    }
    
    private func buildSections() {
        sections = []
        sections.append((tableHeaderBuilder?(), []))
        
        let tasks = taskManager.tasks.filter { relevantTaskIdentifiers.contains($0.identifier) }
        
        let otherContacts = tasks.filter { ($0 as? ContactDetailsTask)?.preferredStaffContact == false }
        let staffContacts = tasks.filter { ($0 as? ContactDetailsTask)?.preferredStaffContact == true }
        
        let otherSectionHeader = SectionHeaderContent("Jij informeert deze contacten", "Vul zo veel mogelijk contactgegevens aan")
        let staffSectionHeader = SectionHeaderContent("De GGD informeert deze contacten", "Vul zo veel mogelijk contactgegevens aan")
        
        if !otherContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(otherSectionHeader),
                             tasks: otherContacts))
        }
        
        if !staffContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(staffSectionHeader),
                             tasks: staffContacts))
        }
    }
}

extension UnfinishedTasksViewModel: TaskManagerListener {
    func taskManagerDidUpdateTasks(_ taskManager: TaskManager) {
        buildSections()
        tableViewManager.reloadData()
    }
    
    func taskManagerDidUpdateSyncState(_ taskManager: TaskManager) {}
}

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
        title = "Bijna klaar"
        navigationItem.leftBarButtonItem = .init(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        
        setupTableView()
        
        promptView = Button(title: .next)
            .touchUpInside(self, action: #selector(upload))
    }
    
    private func setupTableView() {
        tableView.embed(in: contentView, preservesSuperviewLayoutMargins: false)
        tableView.delaysContentTouches = false
        
        let tableHeaderBuilder = {
            Label(title2: "Kun je de gegevens van deze contacten controleren?")
                .multiline()
                .wrappedInReadableWidth(insets: .top(60) + .bottom(20))
        }
        
        let sectionHeaderBuilder = { (title: String, subtitle: String) -> UIView in
            VStack(spacing: 4,
                   Label(bodyBold: title),
                   Label(subhead: subtitle, textColor: Theme.colors.captionGray))
                .wrappedInReadableWidth(insets: .top(20) + .bottom(16))
        }
        
        viewModel.setupTableView(tableView, tableHeaderBuilder: tableHeaderBuilder, sectionHeaderBuilder: sectionHeaderBuilder) { [weak self] task, indexPath in
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
