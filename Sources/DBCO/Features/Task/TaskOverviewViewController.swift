/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol TaskOverviewViewControllerDelegate: AnyObject {
    func taskOverviewViewControllerDidRequestAddContact(_ controller: TaskOverviewViewController)
    func taskOverviewViewController(_ controller: TaskOverviewViewController, didSelect task: Task)
    func taskOverviewViewControllerDidRequestTips(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestUpload(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestRefresh(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestDebugMenu(_ controller: TaskOverviewViewController)
    func taskOverviewViewControllerDidRequestReset(_ controller: TaskOverviewViewController)
    func taskOverviewViewController(_ controller: TaskOverviewViewController, wantsToOpen url: URL)
}

/// - Tag: TaskOverviewViewModel
class TaskOverviewViewModel {
    typealias SectionHeaderContent = (title: String, subtitle: String?)
    typealias PromptFunction = (_ animated: Bool) -> Void
    
    struct Input {
        let pairing: PairingManaging
        let `case`: CaseManaging
    }
    
    private let input: Input
    
    private let tableViewManager: TableViewManager<TaskTableViewCell>
    private var tableHeaderBuilder: (() -> UIView?)?
    private var sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?
    private var tableFooterBuilder: (() -> UIView?)?
    
    private var sections: [(header: UIView?, tasks: [Task], footer: UIView?)]
    
    private var hidePrompt: PromptFunction?
    private var showPrompt: PromptFunction?
    
    private var pairingTimeoutTimer: Timer?
    private var isSetup: Bool = false
    
    @Bindable private(set) var isDoneButtonHidden: Bool = false
    @Bindable private(set) var isResetButtonHidden: Bool = true
    @Bindable private(set) var isAddContactButtonHidden: Bool = false
    @Bindable private(set) var isWindowExpiredMessageHidden: Bool = true
    @Bindable private(set) var isPairingViewHidden: Bool = true
    @Bindable private(set) var isPairingErrorViewHidden: Bool = true
    @Bindable private(set) var pairingErrorText: String = ""
    
    @Bindable private(set) var statusText: String?
    
    init(_ input: Input) {
        self.input = input
        tableViewManager = .init()
        
        sections = []
        
        // There is a weird issue with the html parsing functionality in NSAttributedString.
        // It seems to trigger a layout update in some cases, leaving the tableview in a weird state with out of date data.
        // Guarding the indices into the sections arrays to be in bounds, is needed to prevent crashes in this state.
        tableViewManager.numberOfSections = { [unowned self] in return self.sections.count }
        tableViewManager.numberOfRowsInSection = { [unowned self] in return self.sections[safe: $0]?.tasks.count ?? 0 }
        tableViewManager.itemForCellAtIndexPath = { [unowned self] in return self.sections[$0.section].tasks[$0.row] }
        tableViewManager.viewForHeaderInSection = { [unowned self] in return self.sections[safe: $0]?.header }
        tableViewManager.viewForFooterInSection = { [unowned self] in return self.sections[safe: $0]?.footer }
        
        input.case.addListener(self)
        input.pairing.addListener(self)
    }
    
    func setupTableView(_ tableView: UITableView,
                        tableHeaderBuilder: (() -> UIView?)?,
                        sectionHeaderBuilder: ((SectionHeaderContent) -> UIView?)?,
                        tableFooterBuilder: (() -> UIView?)?,
                        selectedTaskHandler: @escaping (Task, IndexPath) -> Void) {
        tableViewManager.manage(tableView)
        tableViewManager.didSelectItem = selectedTaskHandler
        self.tableHeaderBuilder = tableHeaderBuilder
        self.sectionHeaderBuilder = sectionHeaderBuilder
        self.tableFooterBuilder = tableFooterBuilder
        
        buildSections()
        tableView.reloadData()
        
        isSetup = true
    }
    
    var tipMessageText: NSAttributedString {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = .display
        formatter.dateFormat = .taskOverviewTipsDateFormat
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        
        let date = input.case.startOfContagiousPeriod ?? Date()
        
        let dateString = formatter.string(from: date)
        
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
        
        if input.case.isSynced && !input.case.isWindowExpired {
            hidePrompt(false)
        }
    }
    
    func setShowPrompt(_ showPrompt: @escaping PromptFunction) {
        self.showPrompt = showPrompt
        
        if !input.case.isSynced || input.case.isWindowExpired {
            showPrompt(false)
        }
    }
    
    private func buildSections() {
        sections = []
        
        tableHeaderBuilder.map { sections.append(($0(), [], nil)) }
        
        if input.case.hasSynced {
            buildSections(split: \.isSyncedWithPortal,
                          failingSectionTitle: .taskOverviewUnsyncedContactsHeader,
                          passingSectionTitle: .taskOverviewSyncedContactsHeader)
        } else {
            buildSections(split: \.isOrCanBeInformed,
                          failingSectionTitle: .taskOverviewUninformedContactsHeader,
                          passingSectionTitle: .taskOverviewInformedContactsHeader)
        }
        
        tableFooterBuilder.map { sections.append(($0(), [], nil)) }
        
        let windowExpired = input.case.isWindowExpired
        isAddContactButtonHidden = windowExpired
    }
    
    private func buildSections(split: KeyPath<Task, Bool>, failingSectionTitle: String, passingSectionTitle: String) {
        let tasks = input.case.tasks
            .filter { !$0.deletedByIndex }
            .sorted(by: <)
        
        let failingContacts = tasks.filter { !$0[keyPath: split] }
        let passingContacts = tasks.filter { $0[keyPath: split] }
        
        let failingSectionHeader = SectionHeaderContent(failingSectionTitle, nil)
        let passingSectionHeader = SectionHeaderContent(passingSectionTitle, nil)
        
        if !failingContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(failingSectionHeader),
                             tasks: failingContacts,
                             footer: nil))
        }
        
        if !passingContacts.isEmpty {
            sections.append((header: sectionHeaderBuilder?(passingSectionHeader),
                             tasks: passingContacts,
                             footer: nil))
        }
    }
}

extension TaskOverviewViewModel: CaseManagerListener {
    func caseManagerDidUpdateTasks(_ caseManager: CaseManaging) {
        guard isSetup else { return }
        
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
        
        showPrompt?(true)
    }
}

extension TaskOverviewViewModel: PairingManagerListener {
    
    func showPairingViewIfNeeded() {
        guard !input.pairing.isPaired else { return }
        
        pairingTimeoutTimer?.invalidate()
        pairingTimeoutTimer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: false) { [unowned self] _ in
            let wasPairingViewHidden = self.isPairingViewHidden
            self.isPairingViewHidden = false
            self.isPairingErrorViewHidden = true
            self.isDoneButtonHidden = true
            
            if wasPairingViewHidden {
                statusText = .taskOverviewWaitingForPairingAccessible
            }
        }
    }
    
    func pairingManagerDidStartPollingForPairing(_ pairingManager: PairingManaging) {
        showPairingViewIfNeeded()
    }
    
    func pairingManager(_ pairingManager: PairingManaging, didFailWith error: PairingManagingError) {
        pairingTimeoutTimer?.invalidate()
        
        pairingErrorText = input.pairing.canResumePolling ?
            .taskOverviewPairingFailed :
            .taskOverviewPairingExpired
        
        isPairingViewHidden = true
        isPairingErrorViewHidden = false
        isDoneButtonHidden = true
        
        statusText = pairingErrorText
    }
    
    func pairingManagerDidCancelPollingForPairing(_ pairingManager: PairingManaging) {
        pairingTimeoutTimer?.invalidate()
        
        isPairingViewHidden = true
        isPairingErrorViewHidden = true
        isDoneButtonHidden = false
    }
    
    func pairingManager(_ pairingManager: PairingManaging, didReceiveReversePairingCode code: String) {
        showPairingViewIfNeeded()
    }
    
    func pairingManagerDidFinishPairing(_ pairingManager: PairingManaging) {
        pairingTimeoutTimer?.invalidate()
        
        isPairingViewHidden = true
        isPairingErrorViewHidden = true
        isDoneButtonHidden = false
    
        statusText = .reversePairingFinished
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
        setupPromptView()
        
        refreshControl.addTarget(self, action: #selector(refresh), for: .valueChanged)
    }
    
    private func setupPromptView() {
        let windowExpiredMessage =
            HStack(spacing: 8,
                   UIImageView(imageName: "Warning").asIcon().withInsets(.top(2)),
                   UILabel(subhead: .windowExpiredMessage, textColor: Theme.colors.primary))
            .alignment(.top)
        
        let doneButton = Button(title: .taskOverviewDoneButtonTitle)
            .touchUpInside(self, action: #selector(upload))
        
        let resetButton = Button(title: .taskOverviewDeleteDataButtonTitle)
            .touchUpInside(self, action: #selector(reset))
        
        let pairingView = createPairingView()
        let pairingErrorView = createPairingErrorView()
        
        promptView = VStack(spacing: 16,
                            pairingErrorView,
                            pairingView,
                            windowExpiredMessage,
                            doneButton,
                            resetButton)
        
        viewModel.$isDoneButtonHidden.binding = { doneButton.isHidden = $0 }
        viewModel.$isResetButtonHidden.binding = { resetButton.isHidden = $0 }
        viewModel.$isWindowExpiredMessageHidden.binding = { windowExpiredMessage.isHidden = $0 }
        
        viewModel.$isPairingViewHidden.binding = { pairingView.isHidden = $0 }
        viewModel.$isPairingErrorViewHidden.binding = { pairingErrorView.isHidden = $0 }
        
        viewModel.setHidePrompt { [unowned self] in self.hidePrompt(animated: $0) }
        viewModel.setShowPrompt { [unowned self] in self.showPrompt(animated: $0) }
        
        viewModel.$statusText.binding = { [unowned self] statusText in
            guard presentedViewController == nil else { return }
            guard statusText?.isEmpty == false else { return }
            
            UIAccessibility.post(notification: .announcement, argument: statusText)
        }
        
    }
    
    private func createPairingView() -> UIView {
        let pairingActivityView = ActivityIndicatorView(style: .gray)
        pairingActivityView.accessibilityLabel = .taskOverviewWaitingForPairingAccessible
        pairingActivityView.startAnimating()
        pairingActivityView.setContentHuggingPriority(.required, for: .horizontal)
        let pairingView = VStack(spacing: 16,
                                 HStack(spacing: 6,
                                        pairingActivityView,
                                        UILabel(subhead: .taskOverviewWaitingForPairing, textColor: Theme.colors.primary)
                                            .accessibleText(text: .taskOverviewWaitingForPairingAccessible)),
                                 Button(title: .taskOverviewPairingTryAgain, style: .secondary)
                                    .touchUpInside(self, action: #selector(upload)))
        
        return pairingView
    }
    
    private func createPairingErrorView() -> UIView {
        let label = UILabel(subhead: "", textColor: Theme.colors.warning)
        
        viewModel.$pairingErrorText.binding = { label.text = $0 }
        
        let pairingView = VStack(spacing: 16,
                                 HStack(spacing: 6,
                                        UIImageView(imageName: "Warning").asIcon(color: Theme.colors.warning),
                                        label)
                                    .alignment(.top),
                                 Button(title: .taskOverviewPairingTryAgain, style: .secondary)
                                    .touchUpInside(self, action: #selector(upload)))
        
        return pairingView
    }
    
    private func setupTableView() {
        tableView.embed(in: contentView, preservesSuperviewLayoutMargins: false)
        tableView.delaysContentTouches = false
        tableView.refreshControl = refreshControl
        
        let sectionHeaderBuilder = { [unowned self] in self.sectionHeaderBuilder(title: $0, subtitle: $1) }
        let tableFooterBuilder = { [unowned self] in self.tableFooterBuilder() }
        
        viewModel.setupTableView(tableView,
                                 tableHeaderBuilder: nil,
                                 sectionHeaderBuilder: sectionHeaderBuilder,
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
        viewModel.showPairingViewIfNeeded()
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

private extension TaskOverviewViewController {
    
    private func createTipContainerView() -> UIView {
        let tipContainerView = UIView()
        
        let backgroundView = UIView()
        backgroundView.backgroundColor = Theme.colors.graySeparator
        backgroundView.layer.borderColor = Theme.colors.border.cgColor
        backgroundView.layer.borderWidth = 1 / UIScreen.main.scale
        backgroundView.layer.cornerRadius = 8
        backgroundView.embed(in: tipContainerView)
        
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
        tipButton.setContentCompressionResistancePriority(.required, for: .vertical)
        
        VStack(VStack(spacing: 4,
                      UILabel(body: .taskOverviewTipsTitle),
                      UILabel(attributedString: viewModel.tipMessageText)),
               tipButton)
            .embed(in: tipContainerView, insets: .right(92) + .left(16) + .top(16) + .bottom(5))
        
        return tipContainerView
    }
    
    private func createTipSectionView() -> UIView {
        let addContactButton = Button(title: .taskOverviewAddContactButtonTitle, style: .info)
            .touchUpInside(self, action: #selector(requestContact))
        
        addContactButton.setImage(UIImage(named: "Plus"), for: .normal)
        addContactButton.titleEdgeInsets = .left(5)
        addContactButton.imageEdgeInsets = .right(5)
        
        self.viewModel.$isAddContactButtonHidden.binding = { addContactButton.isHidden = $0 }
        
        return VStack(spacing: 12,
                      createTipContainerView(),
                      addContactButton)
            .withInsets(.top(20))
    }
    
    func sectionHeaderBuilder(title: String, subtitle: String?) -> UIView {
        return VStack(spacing: 4,
                      UILabel(bodyBold: title).asHeader(),
                      UILabel(subhead: subtitle, textColor: Theme.colors.captionGray).hideIfEmpty())
                   .wrappedInReadableWidth(insets: .top(5) + .bottom(0))
    }
    
    private var privacyTextView: TextView {
        let privacyTextView = TextView(htmlText: .taskOverviewPrivacyFooter,
                                       font: Theme.fonts.footnote,
                                       textColor: Theme.colors.footer)
            .linkTouched { [unowned self] in self.delegate?.taskOverviewViewController(self, wantsToOpen: $0) }
        privacyTextView.textAlignment = .center
        
        return privacyTextView
    }
    
    private var versionLabel: UILabel {
        let versionLabel = UILabel(footnote: .mainAppVersionTitle, textColor: Theme.colors.footer)
        versionLabel.textAlignment = .center
        versionLabel.sizeToFit()
        versionLabel.frame = CGRect(x: 0, y: 0, width: versionLabel.frame.width, height: 60.0)
        versionLabel.isUserInteractionEnabled = true
        
        let gestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(openDebugMenu))
        gestureRecognizer.numberOfTapsRequired = 4

        versionLabel.addGestureRecognizer(gestureRecognizer)
        
        return versionLabel
    }
    
    func tableFooterBuilder() -> UIView {
        let containerView = UIView()
        
        let backgroundColorView = UIView()
        backgroundColorView.backgroundColor = Theme.colors.overviewSecondaryBackground
        backgroundColorView.snap(to: .top, of: containerView, height: 1000)
        
        SeparatorView().snap(to: .top, of: containerView)
        
        let resetButton = Button(title: .taskOverviewDeleteDataButtonTitle, style: .info)
            .touchUpInside(self, action: #selector(reset))
        
        resetButton.setTitleColor(Theme.colors.warning, for: .normal)
        
        VStack(spacing: 12,
                      createTipSectionView(),
                      privacyTextView,
                      versionLabel,
                      resetButton)
            .alignment(.center)
            .wrappedInReadableWidth()
            .embed(in: containerView)
        
        return containerView
    }
    
}
