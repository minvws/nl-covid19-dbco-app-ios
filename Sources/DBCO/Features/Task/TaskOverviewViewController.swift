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
    func taskOverviewViewControllerDidRequestUpload(_ controller: TaskOverviewViewController)
}

class TaskOverviewViewModel {
    typealias SectionHeaderContent = (title: String, subtitle: String)
    typealias PromptFunction = (_ animated: Bool) -> Void
    
    private let tableViewManager: TableViewManager<TaskTableViewCell>
    private var tableHeaderBuilder: (() -> UIView?)?
    private var sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?
    
    private var sections: [(header: UIView?, tasks: [Task])]
    
    private var hidePrompt: PromptFunction?
    private var showPrompt: PromptFunction?
    
    init() {
        tableViewManager = .init()
        
        sections = []
        
        tableViewManager.numberOfSections = { [unowned self] in return sections.count }
        tableViewManager.numberOfRowsInSection = { [unowned self] in return sections[$0].tasks.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return sections[$0.section].tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] in return sections[$0].header }
        
        Services.taskManager.addListener(self)
    }
    
    func setupTableView(_ tableView: UITableView, tableHeaderBuilder: (() -> UIView?)?, sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?, selectedTaskHandler: @escaping (Task, IndexPath) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedTaskHandler
        self.tableHeaderBuilder = tableHeaderBuilder
        self.sectionHeaderBuilder = sectionHeaderBuilder
        
        buildSections()
    }
    
    func setHidePrompt(_ hidePrompt: @escaping PromptFunction) {
        self.hidePrompt = hidePrompt
    }
    
    func setShowPrompt(_ showPrompt: @escaping PromptFunction) {
        self.showPrompt = showPrompt
    }
    
    private func buildSections() {
        sections = []
        sections.append((tableHeaderBuilder?(), []))
        
        let otherContacts = Services.taskManager.tasks.filter { [.index, .none].contains($0.contact.communication) }
        let staffContacts = Services.taskManager.tasks.filter { $0.contact.communication == .staff }
        
        let otherSectionHeader = SectionHeaderContent(.taskOverviewIndexContactsHeaderTitle, .taskOverviewIndexContactsHeaderSubtitle)
        let staffSectionHeader = SectionHeaderContent(.taskOverviewStaffContactsHeaderTitle, .taskOverviewStaffContactsHeaderSubtitle)
        
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
    func taskManagerDidUpdateTasks(_ taskManager: TaskManaging) {
        buildSections()
        tableViewManager.reloadData()
    }
    
    func taskManagerDidUpdateSyncState(_ taskManager: TaskManaging) {
        if taskManager.isSynced {
            hidePrompt?(true)
        } else {
            showPrompt?(true)
        }
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
            .touchUpInside(self, action: #selector(upload))
        
        viewModel.setHidePrompt { [unowned self] in hidePrompt(animated: $0) }
        viewModel.setShowPrompt { [unowned self] in showPrompt(animated: $0) }
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
                   Label(bodyBold: title),
                   Label(subhead: subtitle, textColor: Theme.colors.captionGray))
                .wrappedInReadableWidth(insets: .top(20) + .bottom(16))
        }
        
        viewModel.setupTableView(tableView, tableHeaderBuilder: tableHeaderBuilder, sectionHeaderBuilder: sectionHeaderBuilder) { [weak self] task, indexPath in
            guard let self = self else { return }
            
            self.delegate?.taskOverviewViewController(self, didSelect: task)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
        
        let versionLabel = Label(caption1: .mainAppVersionTitle, textColor: Theme.colors.captionGray)
        versionLabel.textAlignment = .center
        versionLabel.sizeToFit()
        versionLabel.frame = CGRect(x: 0, y: 0, width: versionLabel.frame.width, height: 60.0)
        
        tableView.tableFooterView = versionLabel
    }
    
    @objc private func openHelp() {
        delegate?.taskOverviewViewControllerDidRequestHelp(self)
    }
    
    @objc private func requestContact() {
        delegate?.taskOverviewViewControllerDidRequestAddContact(self)
    }
    
    @objc private func upload() {
        delegate?.taskOverviewViewControllerDidRequestUpload(self)
    }

}
