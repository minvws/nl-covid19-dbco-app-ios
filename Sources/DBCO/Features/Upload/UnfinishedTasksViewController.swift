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
    private var sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?
    
    private let relevantTaskIdentifiers: [UUID]
    
    private var sections: [(header: UIView?, tasks: [Task])]
    
    init() {
        tableViewManager = .init()
        
        sections = []
        
        // Store unfisnished task identifiers now, so any completed tasks won't have to dissappear from the overview.
        relevantTaskIdentifiers = Services.caseManager.tasks
            .filter { !$0.isOrCanBeInformed }
            .map { $0.uuid }
        
        tableViewManager.numberOfSections = { [unowned self] in return sections.count }
        tableViewManager.numberOfRowsInSection = { [unowned self] in return sections[$0].tasks.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return sections[$0.section].tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] in return sections[$0].header }
        
        Services.caseManager.addListener(self)
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
        
        let tasks = Services.caseManager.tasks.filter { relevantTaskIdentifiers.contains($0.uuid) }
        
        let otherContacts = tasks.filter { [.index, .none].contains($0.contact.communication) }
        let staffContacts = tasks.filter { $0.contact.communication == .staff }
        
        let otherSectionHeader = SectionHeaderContent(.unfinishedTaskOverviewIndexContactsHeaderTitle, .unfinishedTaskOverviewIndexContactsHeaderSubtitle)
        let staffSectionHeader = SectionHeaderContent(.unfinishedTaskOverviewStaffContactsHeaderTitle, .unfinishedTaskOverviewStaffContactsHeaderSubtitle)
        
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

extension UnfinishedTasksViewModel: CaseManagerListener {
    func caseManagerDidUpdateTasks(_ caseManager: CaseManaging) {
        buildSections()
        tableViewManager.reloadData()
    }
    
    func caseManagerDidUpdateSyncState(_ caseManager: CaseManaging) {}
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
        
        promptView = Button(title: .next)
            .touchUpInside(self, action: #selector(upload))
    }
    
    private func setupTableView() {
        tableView.embed(in: contentView, preservesSuperviewLayoutMargins: false)
        tableView.delaysContentTouches = false
        
        let tableHeaderBuilder = {
            Label(title2: .unfinishedTasksOverviewMessage)
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
