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
    func taskOverviewViewControllerDidRequestTips(_ controller: TaskOverviewViewController)
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
    private var addContactFooterBuilder: (() -> UIView?)?
    private var tableFooterBuilder: (() -> UIView?)?
    
    private var sections: [(header: UIView?, tasks: [Task], footer: UIView?)]
    
    private var hidePrompt: PromptFunction?
    private var showPrompt: PromptFunction?
    
    private var pairingTimeoutTimer: Timer?
    
    @Bindable private(set) var isDoneButtonHidden: Bool = false
    @Bindable private(set) var isResetButtonHidden: Bool = true
    @Bindable private(set) var isHeaderAddContactButtonHidden: Bool = false
    @Bindable private(set) var isAddContactButtonHidden: Bool = false
    @Bindable private(set) var isWindowExpiredMessageHidden: Bool = true
    @Bindable private(set) var isPairingViewHidden: Bool = true
    
    init() {
        tableViewManager = .init()
        
        sections = []
        
        tableViewManager.numberOfSections = { [unowned self] in return self.sections.count }
        tableViewManager.numberOfRowsInSection = { [unowned self] in return self.sections[$0].tasks.count }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return self.sections[$0.section].tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] in return self.sections[$0].header }
        tableViewManager.viewForFooterInSection = { [unowned self] in return self.sections[$0].footer }
        
        Services.caseManager.addListener(self)
        Services.pairingManager.addListener(self)
    }
    
    func setupTableView(_ tableView: UITableView,
                        tableHeaderBuilder: (() -> UIView?)?,
                        sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?,
                        addContactFooterBuilder: (() -> UIView?)?,
                        tableFooterBuilder: (() -> UIView?)?,
                        selectedTaskHandler: @escaping (Task, IndexPath) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedTaskHandler
        self.tableHeaderBuilder = tableHeaderBuilder
        self.sectionHeaderBuilder = sectionHeaderBuilder
        self.addContactFooterBuilder = addContactFooterBuilder
        self.tableFooterBuilder = tableFooterBuilder
        
        tableView.allowsSelection = !Services.caseManager.isWindowExpired
        
        buildSections()
    }
    
    var tipMessageText: NSAttributedString {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale.current
        formatter.dateFormat = .taskOverviewTipsDateFormat
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let dateString = formatter.string(from: Services.caseManager.dateOfSymptomOnset)
        
        let fullString: String = .taskOverviewTipsMessage(date: dateString)
        let dateRange = (fullString as NSString).range(of: dateString)
        
        let attributed = NSMutableAttributedString(string: fullString as String, attributes: [
            .font: Theme.fonts.subhead,
            .foregroundColor: Theme.colors.captionGray
        ])
        
        attributed.addAttribute(.font, value: Theme.fonts.subheadBold, range: dateRange)
        attributed.addAttribute(.foregroundColor, value: UIColor.black, range: dateRange)
        
        return attributed
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
        sections.append((tableHeaderBuilder?(), [], nil))
        
        let tasks = Services.caseManager.tasks.filter { !$0.deletedByIndex }
        
        let uninformedContacts = tasks.filter { !$0.isOrCanBeInformed }
        let informedContacts = tasks.filter { $0.isOrCanBeInformed }
        
        let uninformedSectionHeader = SectionHeaderContent(.taskOverviewUninformedContactsHeaderTitle, .taskOverviewUninformedContactsHeaderSubtitle)
        let informedSectionHeader = SectionHeaderContent(.taskOverviewInformedContactsHeaderTitle, .taskOverviewInformedContactsHeaderSubtitle)
        
        if !uninformedContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(uninformedSectionHeader),
                             tasks: uninformedContacts,
                             footer: addContactFooterBuilder?()))
        }
        
        if !informedContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(informedSectionHeader),
                             tasks: informedContacts,
                             footer: nil))
        }
        
        sections.append((tableFooterBuilder?(), [], nil))
        
        let windowExpired = Services.caseManager.isWindowExpired
        
        isHeaderAddContactButtonHidden = !uninformedContacts.isEmpty || windowExpired
        isAddContactButtonHidden = uninformedContacts.isEmpty || windowExpired
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
        isHeaderAddContactButtonHidden = true
        isWindowExpiredMessageHidden = false
        
        tableViewManager.tableView?.allowsSelection = false
        
        showPrompt?(true)
    }
}

extension TaskOverviewViewModel: PairingManagerListener {
    
    func pairingManagerDidStartPollingForPairing(_ pairingManager: PairingManaging) {
        pairingTimeoutTimer?.invalidate()
        pairingTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [unowned self] _ in
            self.isPairingViewHidden = false
            self.isDoneButtonHidden = true
        }
    }
    
    func pairingManager(_ pairingManager: PairingManaging, didFailWith error: PairingManagingError) {
        pairingTimeoutTimer?.invalidate()
        
        isPairingViewHidden = true
        isDoneButtonHidden = false
    }
    
    func pairingManagerDidCancelPollingForPairing(_ pairingManager: PairingManaging) {
        pairingTimeoutTimer?.invalidate()
        
        isPairingViewHidden = true
        isDoneButtonHidden = false
    }
    
    func pairingManager(_ pairingManager: PairingManaging, didReceiveReversePairingCode code: String) {}
    
    func pairingManagerDidFinishPairing(_ pairingManager: PairingManaging) {
        pairingTimeoutTimer?.invalidate()
        
        isPairingViewHidden = true
        isDoneButtonHidden = false
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
        
        let windowExpiredMessage =
            HStack(spacing: 8,
                   ImageView(imageName: "Warning").asIcon().withInsets(.top(2)),
                   Label(subhead: .windowExpiredMessage,
                         textColor: Theme.colors.primary).multiline())
            .alignment(.top)
        
        let doneButton = Button(title: .taskOverviewDoneButtonTitle)
            .touchUpInside(self, action: #selector(upload))
        
        let resetButton = Button(title: .taskOverviewDeleteDataButtonTitle)
            .touchUpInside(self, action: #selector(reset))
        
        let pairingActivityView = ActivityIndicatorView(style: .gray)
        pairingActivityView.startAnimating()
        pairingActivityView.setContentHuggingPriority(.required, for: .horizontal)
        let pairingView = VStack(spacing: 16,
                                 HStack(spacing: 6,
                                        pairingActivityView,
                                        Label(subhead: .taskOverviewWaitingForPairing, textColor: Theme.colors.primary).multiline()),
                                 Button(title: .taskOverviewPairingTryAgain, style: .secondary)
                                    .touchUpInside(self, action: #selector(upload)))
        
        promptView = VStack(spacing: 16,
                            pairingView,
                            windowExpiredMessage,
                            doneButton,
                            resetButton)
        
        viewModel.$isDoneButtonHidden.binding = { doneButton.isHidden = $0 }
        viewModel.$isResetButtonHidden.binding = { resetButton.isHidden = $0 }
        viewModel.$isWindowExpiredMessageHidden.binding = { windowExpiredMessage.isHidden = $0 }
        
        viewModel.$isPairingViewHidden.binding = { pairingView.isHidden = $0 }
        
        viewModel.setHidePrompt { [unowned self] in self.hidePrompt(animated: $0) }
        viewModel.setShowPrompt { [unowned self] in self.showPrompt(animated: $0) }
        
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func setupTableView() {
        tableView.embed(in: contentView, preservesSuperviewLayoutMargins: false)
        tableView.delaysContentTouches = false
        tableView.refreshControl = refreshControl
        
        let tableHeaderBuilder = { [unowned self] () -> UIView in
            let tipContainerView = UIView()
            tipContainerView.backgroundColor = Theme.colors.graySeparator
            tipContainerView.layer.cornerRadius = 8
            
            let thinkingImage = UIImage(named: "Thinking")!
            let thinkingImageView = UIImageView(image: thinkingImage)
            thinkingImageView.snap(to: .bottomRight,
                                   of: tipContainerView,
                                   width: thinkingImage.size.width + 8) // add 1 cornerradius worth of margin on the left
            thinkingImageView.contentMode = .bottomRight
            thinkingImageView.layer.cornerRadius = 8
            thinkingImageView.clipsToBounds = true
            
            let tipButton = Button(title: .taskOverviewTipsButton, style: .info)
            tipButton.contentHorizontalAlignment = .left
            tipButton.contentEdgeInsets = .zero
            tipButton.titleLabel?.font = Theme.fonts.subheadBold
            tipButton.touchUpInside(self, action: #selector(requestTips))
            
            VStack(VStack(spacing: 4,
                          Label(bodyBold: .taskOverviewTipsTitle).multiline(),
                          Label(viewModel.tipMessageText).multiline()),
                   tipButton)
                .embed(in: tipContainerView, insets: .right(92) + .left(16) + .top(16) + .bottom(11))
            
            let addContactButton = Button(title: .taskOverviewAddContactButtonTitle, style: .info)
                .touchUpInside(self, action: #selector(requestContact))
            
            addContactButton.setImage(UIImage(named: "Plus"), for: .normal)
            addContactButton.titleEdgeInsets = .left(5)
            addContactButton.imageEdgeInsets = .right(5)
            
            self.viewModel.$isHeaderAddContactButtonHidden.binding = { addContactButton.isHidden = $0 }
            
            return VStack(spacing: 12,
                          tipContainerView,
                          addContactButton)
                .wrappedInReadableWidth(insets: .top(32))
        }
        
        let sectionHeaderBuilder = { (title: String, subtitle: String) -> UIView in
            VStack(spacing: 4,
                   Label(bodyBold: title).multiline(),
                   Label(subhead: subtitle, textColor: Theme.colors.captionGray).multiline())
                .wrappedInReadableWidth(insets: .top(20) + .bottom(16))
        }
        
        let addContactFooterBuilder = { [unowned self] () -> UIView in
            let addContactButton = Button(title: .taskOverviewAddContactButtonTitle, style: .info)
                .touchUpInside(self, action: #selector(requestContact))
            
            addContactButton.setImage(UIImage(named: "Plus"), for: .normal)
            addContactButton.titleEdgeInsets = .left(5)
            addContactButton.imageEdgeInsets = .right(5)
            
            self.viewModel.$isAddContactButtonHidden.binding = { addContactButton.isHidden = $0 }
            
            return addContactButton
                .wrappedInReadableWidth(insets: .top(2) + .bottom(16))
        }
        
        let tableFooterBuilder = { [unowned self] () -> UIView in
            
            let versionLabel = Label(caption1: .mainAppVersionTitle, textColor: Theme.colors.captionGray)
            versionLabel.textAlignment = .center
            versionLabel.sizeToFit()
            versionLabel.frame = CGRect(x: 0, y: 0, width: versionLabel.frame.width, height: 60.0)
            versionLabel.isUserInteractionEnabled = true
            
            let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openDebugMenu))
            gestureRecognizer.numberOfTapsRequired = 4
            
            versionLabel.addGestureRecognizer(gestureRecognizer)
            
            return versionLabel.wrappedInReadableWidth(insets: .top(8) + .bottom(8))
        }
        
        viewModel.setupTableView(tableView,
                                 tableHeaderBuilder: tableHeaderBuilder,
                                 sectionHeaderBuilder: sectionHeaderBuilder,
                                 addContactFooterBuilder: addContactFooterBuilder,
                                 tableFooterBuilder: tableFooterBuilder) { [weak self] task, indexPath in
            guard let self = self else { return }
            
            self.delegate?.taskOverviewViewController(self, didSelect: task)
            self.tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    @objc private func requestContact() {
        delegate?.taskOverviewViewControllerDidRequestAddContact(self)
    }
    
    @objc private func requestTips() {
        delegate?.taskOverviewViewControllerDidRequestTips(self)
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
