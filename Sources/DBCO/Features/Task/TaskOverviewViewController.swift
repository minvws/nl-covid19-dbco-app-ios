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
    typealias SectionHeaderContent = (title: String, subtitle: String)
    private let tableViewManager: TableViewManager<TaskTableViewCell>
    private let taskManager: TaskManager
    private var tableHeaderBuilder: (() -> UIView?)?
    private var sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?
    
    private var sections: [(header: UIView?, tasks: [Task])]
    
    init(taskManager: TaskManager) {
        self.taskManager = taskManager
        
        tableViewManager = .init()
        
        sections = []
        
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
        
        let otherContacts = taskManager.tasks.filter { ($0 as? ContactDetailsTask)?.preferredStaffContact == false }
        let staffContacts = taskManager.tasks.filter { ($0 as? ContactDetailsTask)?.preferredStaffContact == true }
        
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

extension TaskOverviewViewModel: TaskManagerListener {
    func taskManagerDidUpdateTasks(_ taskManager: TaskManager) {
        buildSections()
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
        tableView.embed(in: contentView, preservesSuperviewLayoutMargins: false)
        tableView.delaysContentTouches = false
        
        let tableHeaderBuilder = { [unowned self] in
            Button(title: .taskOverviewAddContactButtonTitle, style: .secondary)
                .touchUpInside(self, action: #selector(requestContact))
                .wrappedInReadableWidth(insets: .top(16))
        }
        
        let sectionHeaderBuilder = { (title: String, subtitle: String) -> UIView in
            VStack(spacing: 4,
                   Label(title, font: Theme.fonts.bodyBold),
                   Label(subtitle, font: Theme.fonts.subhead, textColor: Theme.colors.captionGray))
                .wrappedInReadableWidth(insets: .top(20) + .bottom(16))
        }
        
        viewModel.setupTableView(tableView, tableHeaderBuilder: tableHeaderBuilder, sectionHeaderBuilder: sectionHeaderBuilder) { [weak self] task, indexPath in
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
