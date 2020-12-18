/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol TaskOverviewViewControllerDelegate: class {
    func taskOverviewViewControllerDidRequestAddContact(_ controller: TaskOverviewViewController)
    func taskOverviewViewController(_ controller: TaskOverviewViewController, didSelect task: Task)
    func taskOverviewViewControllerDidRequestUpload(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestRefresh(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestDebugMenu(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestReset(_ controller: TaskOverviewViewController)
}

/// - Tag: TaskOverviewViewModel
class TaskOverviewViewModel {
    typealias SectionHeaderContent = (title: String, subtitle: String)
    typealias PromptFunction = (_ animated: Bool) -> Void
    
    private let tableViewManager: TableViewManager<TaskTableViewCell>
    private var tableHeaderBuilder: (() -> UIView?)?
    private var sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?
    
    private var sections: [(header: UIView?, tasks: [Task])]
    
    private var hidePrompt: PromptFunction?
    private var showPrompt: PromptFunction?
    
    @Bindable private(set) var isDoneButtonHidden: Bool = false
    @Bindable private(set) var isResetButtonHidden: Bool = true
    @Bindable private(set) var isAddContactButtonHidden: Bool = false
    @Bindable private(set) var isWindowExpiredMessageHidden: Bool = true
    
    init() {
        tableViewManager = .init()
        
        sections = []
        
        tableViewManager.numberOfSections = { [unowned self] in return self.sections.count }
        tableViewManager.numberOfRowsInSection = { [unowned self] in return self.sections[$0].tasks.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return self.sections[$0.section].tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] in return self.sections[$0].header }
        
        Services.caseManager.addListener(self)
    }
    
    func setupTableView(_ tableView: UITableView, tableHeaderBuilder: (() -> UIView?)?, sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?, selectedTaskHandler: @escaping (Task, IndexPath) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedTaskHandler
        self.tableHeaderBuilder = tableHeaderBuilder
        self.sectionHeaderBuilder = sectionHeaderBuilder
        
        tableView.allowsSelection = !Services.caseManager.isWindowExpired
        
        buildSections()
    }
    
    func setHidePrompt(_ hidePrompt: @escaping PromptFunction) {
        self.hidePrompt = hidePrompt
        
        if Services.caseManager.isSynced && !Services.caseManager.isWindowExpired {
            hidePrompt(false)
        }
    }
    
    func setShowPrompt(_ showPrompt: @escaping PromptFunction) {
        self.showPrompt = showPrompt
        
        if !Services.caseManager.isSynced || Services.caseManager.isWindowExpired {
            showPrompt(false)
        }
    }
    
    private func buildSections() {
        sections = []
        sections.append((tableHeaderBuilder?(), []))
        
        let tasks = Services.caseManager.tasks.filter { !$0.deletedByIndex }
        
        let uninformedContacts = tasks.filter { !$0.isOrCanBeInformed }
        let informedContacts = tasks.filter { $0.isOrCanBeInformed }
        
        let uninformedSectionHeader = SectionHeaderContent(.taskOverviewUninformedContactsHeaderTitle, .taskOverviewUninformedContactsHeaderSubtitle)
        let informedSectionHeader = SectionHeaderContent(.taskOverviewInformedContactsHeaderTitle, .taskOverviewInformedContactsHeaderSubtitle)
        
        if !uninformedContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(uninformedSectionHeader),
                             tasks: uninformedContacts))
        }
        
        if !informedContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(informedSectionHeader),
                             tasks: informedContacts))
        }
    }
}

extension TaskOverviewViewModel: CaseManagerListener {
    func caseManagerDidUpdateTasks(_ caseManager: CaseManaging) {
        buildSections()
        tableViewManager.reloadData()
    }
    
    func caseManagerDidUpdateSyncState(_ caseManager: CaseManaging) {
        if caseManager.isSynced {
            hidePrompt?(true)
        } else {
            showPrompt?(true)
        }
    }
    
    func caseManagerWindowExpired(_ caseManager: CaseManaging) {
        isDoneButtonHidden = true
        isResetButtonHidden = false
        isAddContactButtonHidden = true
        isWindowExpiredMessageHidden = false
        
        tableViewManager.tableView?.allowsSelection = false
        
        showPrompt?(true)
    }
}

/// - Tag: TaskOverviewViewController
class TaskOverviewViewController: PromptableViewController {
    private let viewModel: TaskOverviewViewModel
    private let tableView = UITableView.createDefaultGrouped()
    private let refreshControl = UIRefreshControl()
    
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
        
        let doneButton = Button(title: .taskOverviewDoneButtonTitle)
            .touchUpInside(self, action: #selector(upload))
        
        let resetButton = Button(title: .taskOverviewDeleteDataButtonTitle)
            .touchUpInside(self, action: #selector(reset))
        
        promptView = VStack(doneButton, resetButton)
        
        viewModel.$isDoneButtonHidden.binding = { doneButton.isHidden = $0 }
        viewModel.$isResetButtonHidden.binding = { resetButton.isHidden = $0 }
        
        viewModel.setHidePrompt { [unowned self] in self.hidePrompt(animated: $0) }
        viewModel.setShowPrompt { [unowned self] in self.showPrompt(animated: $0) }
        
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func setupTableView() {
        tableView.embed(in: contentView, preservesSuperviewLayoutMargins: false)
        tableView.delaysContentTouches = false
        tableView.refreshControl = refreshControl
        
        let tableHeaderBuilder = { [unowned self] () -> UIView in
            let addContactButton = Button(title: .taskOverviewAddContactButtonTitle, style: .secondary)
                .touchUpInside(self, action: #selector(requestContact))
            
            addContactButton.setImage(UIImage(named: "Plus"), for: .normal)
            addContactButton.titleEdgeInsets = .left(5)
            addContactButton.imageEdgeInsets = .right(5)
            
            let iconView = UIImageView(image: UIImage(named: "Warning"))
            iconView.contentMode = .center
            iconView.setContentHuggingPriority(.required, for: .horizontal)
            iconView.tintColor = Theme.colors.primary
            
            let windowExpiredMessage =
                HStack(spacing: 8,
                       iconView.withInsets(.top(2)),
                       Label(subhead: .windowExpiredMessage,
                             textColor: Theme.colors.primary).multiline())
                .alignment(.top)
            
            self.viewModel.$isAddContactButtonHidden.binding = { addContactButton.isHidden = $0 }
            self.viewModel.$isWindowExpiredMessageHidden.binding = { windowExpiredMessage.isHidden = $0 }
            
            return VStack(addContactButton, windowExpiredMessage)
                .wrappedInReadableWidth(insets: .top(16))
        }
        
        let sectionHeaderBuilder = { (title: String, subtitle: String) -> UIView in
            VStack(spacing: 4,
                   Label(bodyBold: title).multiline(),
                   Label(subhead: subtitle, textColor: Theme.colors.captionGray).multiline())
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
        versionLabel.isUserInteractionEnabled = true
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openDebugMenu))
        gestureRecognizer.numberOfTapsRequired = 4
        
        versionLabel.addGestureRecognizer(gestureRecognizer)
        
        tableView.tableFooterView = versionLabel
    }
    
    @objc private func requestContact() {
        delegate?.taskOverviewViewControllerDidRequestAddContact(self)
    }
    
    @objc private func upload() {
        delegate?.taskOverviewViewControllerDidRequestUpload(self)
    }
    
    @objc private func refresh() {
        delegate?.taskOverviewViewControllerDidRequestRefresh(self)
    }
    
    @objc private func openDebugMenu() {
        delegate?.taskOverviewViewControllerDidRequestDebugMenu(self)
    }
    
    @objc private func reset() {
        delegate?.taskOverviewViewControllerDidRequestReset(self)
    }
    
    var isLoading: Bool {
        get { refreshControl.isRefreshing }
        set { newValue ? refreshControl.beginRefreshing() : refreshControl.endRefreshing() }
    }

}
