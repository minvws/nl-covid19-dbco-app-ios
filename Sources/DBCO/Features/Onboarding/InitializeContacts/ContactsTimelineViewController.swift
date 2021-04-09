/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

protocol ContactsTimelineViewControllerDelegate: class {
    func contactsTimelineViewController(_ controller: ContactsTimelineViewController, didFinishWith contacts: [Onboarding.Contact], dateOfSymptomOnset: Date)
    func contactsTimelineViewController(_ controller: ContactsTimelineViewController, didFinishWith contacts: [Onboarding.Contact], testDate: Date)
    func contactsTimelineViewController(_ controller: ContactsTimelineViewController, didCancelWith contacts: [Onboarding.Contact])
    func contactsTimelineViewControllerDidRequestHelp(_ controller: ContactsTimelineViewController)
}

class ContactsTimelineViewModel {
    
    enum Section {
        case day(date: Date, title: String, subtitle: String?)
        case reviewTips
        case activityTips
    }
    
    enum Configuration {
        case dateOfSymptomOnset(Date)
        case testDate(Date)
        
        var date: Date {
            switch self {
            case .dateOfSymptomOnset(let date):
                return date
            case .testDate(let date):
                return date
            }
        }
    }
    
    private(set) var configuration: Configuration
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.timeZone = .current
        formatter.dateFormat = .contactsTimelineDateFormat
        
        return formatter
    }()
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.timeZone = .current
        formatter.dateFormat = .contactsTimelineShortDateFormat
        
        return formatter
    }()
    
    init(dateOfSymptomOnset: Date) {
        configuration = .dateOfSymptomOnset(dateOfSymptomOnset.start)
    }
    
    init(testDate: Date) {
        configuration = .testDate(testDate.start)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private var endDate: Date {
        switch configuration {
        case .dateOfSymptomOnset(let date):
            return Calendar.current.date(byAdding: .day, value: -2, to: date)!
        case .testDate(let date):
            return date
        }
    }
    
    var title: String {
        return .contactsTimelineTitle(endDate: dateFormatter.string(from: endDate))
    }
    
    var sections: [Section] {
        let today = Date().start
    
        let numberOfDays = Calendar.current.dateComponents([.day], from: endDate, to: today).day! + 1
        
        func title(for index: Int, date: Date) -> String {
            let titleFormats: [String] = [
                .contactsTimelineSectionTitleTodayFormat,
                .contactsTimelineSectionTitleYesterdayFormat,
                .contactsTimelineSectionTitle2DaysAgoFormat
            ]
            
            if titleFormats.indices.contains(index) {
                return String(format: titleFormats[index], dateFormatter.string(from: date))
            } else {
                return dateFormatter.string(from: date).capitalizingFirstLetter()
            }
        }
        
        func subtitle(for index: Int) -> String? {
            let reversedSubtitles: [String?]
            
            switch configuration {
            case .dateOfSymptomOnset:
                reversedSubtitles = [
                    .contactsTimelineSectionSubtitleBeforeOnset,
                    .contactsTimelineSectionSubtitleBeforeOnset,
                    .contactsTimelineSectionSubtitleSymptomOnset
                ]
            case .testDate:
                reversedSubtitles = [
                    .contactsTimelineSectionSubtitleTestDate
                ]
            }
            
            let reversedIndex = (numberOfDays - 1) - index
            
            if reversedSubtitles.indices.contains(reversedIndex) {
                return reversedSubtitles[reversedIndex]
            } else {
                return nil
            }
        }
        
        var sections = (0 ..< numberOfDays).map { index -> Section in
            let date = Calendar.current.date(byAdding: .day, value: -index, to: today)!
            
            let section = Section.day(date: date,
                                      title: title(for: index, date: date),
                                      subtitle: subtitle(for: index))
            
            return section
        }
        
        sections.insert(.reviewTips, at: 0)
        
        switch numberOfDays {
        case ...4:
            sections.append(.activityTips)
        default:
            sections.insert(.activityTips, at: 5)
        }
        
        return sections
    }
    
    var hideExtraDaySection: Bool {
        switch configuration {
        case .dateOfSymptomOnset:
            return false
        case .testDate:
            return true
        }
    }
    
    var addExtraDayTitle: String? {
        guard case .dateOfSymptomOnset(let date) = configuration else { return nil }
        
        return .contactsTimelineAddExtraDayTitle(endDate: shortDateFormatter.string(from: date))
    }
    
    func addExtraDay() {
        guard case .dateOfSymptomOnset(let date) = configuration else { return }
        
        let adjustedDate = date.dateByAddingDays(-1)
        
        configuration = .dateOfSymptomOnset(adjustedDate)
    }
    
    func emptyDaysMessage(for sections: [Section]) -> String {
        let dates = sections
            .compactMap { section -> String? in
                if case .day(let date, _, _) = section {
                    return dateFormatter.string(from: date)
                } else {
                    return nil
                }
            }
            .reversed()
        
        let combinedDates: String
        
        if dates.count > 2 {
            combinedDates = dates.dropLast().joined(separator: .contactsTimelineEmptyDaysSeparator) + .contactsTimelineEmptyDaysFinalSeparator + dates.last!
        } else {
            combinedDates = dates.joined(separator: .contactsTimelineEmptyDaysFinalSeparator)
        }
        
        return .contactsTimelineEmptyDaysMessage(days: combinedDates)
    }
    
    private(set) lazy var contacts: [CNContact] = {
        guard case .authorized = CNContactStore.authorizationStatus(for: .contacts) else { return [] }
        
        let keys = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactTypeKey as CNKeyDescriptor
        ]
        
        let request = CNContactFetchRequest(keysToFetch: keys)
        request.sortOrder = .givenName
        
        var contacts = [CNContact]()
        try? CNContactStore().enumerateContacts(with: request) { contact, stop in
            if contact.contactType == .person {
                contacts.append(contact)
            }
        }
        return contacts
    }()
}

class ContactsTimelineViewController: ViewController, ScrollViewNavivationbarAdjusting {
    private let viewModel: ContactsTimelineViewModel
    private let navigationBackgroundView = UIView()
    private let separatorView = SeparatorView()
    private let titleLabel = UILabel(title2: nil)
    private var addExtraDaySectionView: UIStackView!
    private let addExtraDayTitleLabel = UILabel(bodyBold: nil)
    
    private let scrollView = UIScrollView(frame: .zero)
    private var sectionStackView: UIStackView!
    
    weak var delegate: ContactsTimelineViewControllerDelegate?
    
    let shortTitle: String = .contactsTimelineShortTitle
    
    init(viewModel: ContactsTimelineViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        if #available(iOS 14.0, *) {
            navigationItem.backButtonDisplayMode = .generic
        }
        
        view.backgroundColor = .white
        
        scrollView.embed(in: view)
        scrollView.keyboardDismissMode = .onDrag
        scrollView.delegate = self
        
        let margin: UIEdgeInsets = .top(32) + .bottom(16)
        
        sectionStackView = VStack(spacing: 40)
        
        let addExtraDayButton = Button(title: .contactsTimelineAddExtraDayButton, style: .secondary)
            .touchUpInside(self, action: #selector(addExtraDay))
        
        addExtraDayButton.setImage(UIImage(named: "Plus"), for: .normal)
        addExtraDayButton.titleEdgeInsets = .left(5)
        addExtraDayButton.imageEdgeInsets = .right(5)
        
        addExtraDaySectionView = VStack(spacing: 24,
                                        addExtraDayTitleLabel.multiline(),
                                        addExtraDayButton)

        let stack =
            VStack(spacing: 40,
                   VStack(spacing: 16,
                          titleLabel.multiline(),
                          TextView(htmlText: .contactsTimelineMessage, font: Theme.fonts.body, textColor: Theme.colors.captionGray, boldTextColor: Theme.colors.primary)
                            .linkTouched { [weak self] _ in self?.openHelp() }),
                   sectionStackView,
                   VStack(spacing: 16,
                          addExtraDaySectionView,
                          Button(title: .done, style: .primary).touchUpInside(self, action: #selector(handleContinue))))
                .distribution(.fill)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                                          multiplier: 1,
                                          constant: -(margin.top + margin.bottom)).isActive = true
        
        configureSections()
        
        registerForKeyboardNotifications()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideSuggestions)))
    }
    
    @objc private func hideSuggestions() {
        sectionStackView.arrangedSubviews
            .compactMap { $0 as? DaySectionView }
            .forEach { $0.contactList.hideSuggestions() }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent {
            delegate?.contactsTimelineViewController(self, didCancelWith: listAllContacts())
        }
    }
    
    private func configureSections() {
        titleLabel.text = viewModel.title
        
        let existingSectionViews = sectionStackView.arrangedSubviews.compactMap { $0 as? TimelineSectionView }
        
        let storedContacts = Services.onboardingManager.contacts ?? []
        
        func view(for section: ContactsTimelineViewModel.Section) -> TimelineSectionView {
            if let sectionView = existingSectionViews.first(where: { $0.isConfigured(for: section) }) {
                return sectionView
            } else {
                switch section {
                case .day(let date, _, _):
                    let sectionView = DaySectionView()
                    sectionView.contactListDelegate = self
                    sectionView.contactList.contacts = storedContacts
                        .filter { $0.date == date }
                        .map { ContactListInputView.Contact(name: $0.name, cnContactIdentifier: $0.contactIdentifier) }
                    return sectionView
                case .reviewTips:
                    return ReviewTipsSectionView()
                case .activityTips:
                    return ActivityTipsSectionView()
                }
            }
        }
        
        sectionStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        viewModel.sections.forEach { section in
            let sectionView = view(for: section)
            sectionView.section = section
            self.sectionStackView.addArrangedSubview(sectionView)
        }
        
        addExtraDaySectionView.isHidden = viewModel.hideExtraDaySection
        addExtraDayTitleLabel.text = viewModel.addExtraDayTitle
    }
    
    private func listAllContacts() -> [Onboarding.Contact] {
        return sectionStackView.arrangedSubviews
            .compactMap { $0 as? DaySectionView }
            .flatMap { sectionView -> [Onboarding.Contact] in
                guard case .day(let date, _, _) = sectionView.section else { return [] }
                return sectionView.contactList.contacts.map { Onboarding.Contact(date: date, name: $0.name, contactIdentifier: $0.cnContactIdentifier, isRoommate: false) }
            }
    }
    
    private func openHelp() {
        delegate?.contactsTimelineViewControllerDidRequestHelp(self)
    }
    
    @objc private func handleContinue() {
        let emptySections = sectionStackView
            .arrangedSubviews
            .compactMap { $0 as? DaySectionView }
            .filter { $0.contactList.contacts.isEmpty }
            .compactMap { $0.section }
        
        func finish() {
            switch viewModel.configuration {
            case .dateOfSymptomOnset(let date):
                delegate?.contactsTimelineViewController(self, didFinishWith: listAllContacts(), dateOfSymptomOnset: date)
            case .testDate(let date):
                delegate?.contactsTimelineViewController(self, didFinishWith: listAllContacts(), testDate: date)
            }
        }
        
        if emptySections.isEmpty {
            finish()
        } else {
            let alert = UIAlertController(title: .contactsTimelineEmptyDaysTitle,
                                          message: viewModel.emptyDaysMessage(for: emptySections),
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: .contactsTimelineEmptyDaysBackButton, style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: .contactsTimelineEmptyDaysContinueButton, style: .default) { _ in
                finish()
            })
            
            present(alert, animated: true)
        }
    }
    
    @objc private func addExtraDay() {
        viewModel.addExtraDay()
        
        configureSections()
    }
    
    // MARK: - Keyboard handling
    
    private func registerForKeyboardNotifications() {
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow), name: UIWindow.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide), name: UIWindow.keyboardWillHideNotification, object: nil)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let userInfo = notification.userInfo else { return }
        let endFrame = (userInfo[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue)?.cgRectValue ?? .zero
        
        let convertedFrame = view.window?.convert(endFrame, to: view)
        
        let inset = view.frame.maxY - (convertedFrame?.minY ?? 0)
        
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    @objc private func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets.bottom = .zero
    }

}

extension ContactsTimelineViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}

extension ContactsTimelineViewController: ContactListInputViewDelegate {
    
    func contactListInputView(_ view: ContactListInputView, didBeginEditingIn textField: UITextField) {
        func scrollVisible() {
            let convertedBounds = scrollView.convert(textField.bounds, from: textField)
            let extraMargin = UIEdgeInsets(top: 32, left: 0, bottom: 100, right: 0)
            let visibleHeight =
                scrollView.bounds.height -
                scrollView.safeAreaInsets.top -
                scrollView.safeAreaInsets.bottom -
                scrollView.contentInset.bottom
        
            let minOffset = convertedBounds.minY - (scrollView.safeAreaInsets.top + extraMargin.top)
            let maxOffset = minOffset - visibleHeight + convertedBounds.height + extraMargin.bottom
            let currentOffset = scrollView.contentOffset.y
            
            if traitCollection.verticalSizeClass == .compact {
                scrollView.setContentOffset(CGPoint(x: 0, y: minOffset), animated: true)
            } else if currentOffset > minOffset {
                scrollView.setContentOffset(CGPoint(x: 0, y: minOffset), animated: true)
            } else if currentOffset < maxOffset {
                scrollView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: true)
            }
        }
        
        // Next runcycle so keyboard size is properly incorporated
        DispatchQueue.main.async(execute: scrollVisible)
    }
    
    func contactListInputView(_ view: ContactListInputView, didEndEditingIn textField: UITextField) {}
    
    func viewForPresentingSuggestionsFromContactListInputView(_ view: ContactListInputView) -> UIView {
        return self.view
    }
    
    func contactsAvailableForSuggestionInContactListInputView(_ view: ContactListInputView) -> [CNContact] {
        return viewModel.contacts
    }
    
}

private class TimelineSectionView: UIView {
    
    var section: ContactsTimelineViewModel.Section? {
        didSet { configureForSection() }
    }
    
    init() {
        super.init(frame: .zero)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    func setup() { }
    
    func configureForSection() {}
    
    func isConfigured(for section: ContactsTimelineViewModel.Section) -> Bool {
        return false
    }
    
    func createTipHeaderLabel() -> UIView {
        let headerContainerView = UIView()
        headerContainerView.layer.cornerRadius = 4
        headerContainerView.backgroundColor = Theme.colors.tipHeaderBackground
        
        UILabel(caption1: "Geheugentip".uppercased(), textColor: .white)
            .embed(in: headerContainerView, insets: .all(4))
        
        return VStack(headerContainerView).alignment(.leading)
    }
    
    func createTipItem(icon: String, text: String) -> UIView {
        let icon = UIImageView(image: UIImage(named: "MemoryTips/\(icon)"))
        icon.contentMode = .center
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
        
        return HStack(spacing: 12,
                      icon,
                      UILabel(body: text, textColor: Theme.colors.tipItemColor).multiline())
    }
}

private class DaySectionView: TimelineSectionView {
    private let titleLabel = UILabel(bodyBold: nil)
    private let subtitleLabel = UILabel(body: nil, textColor: Theme.colors.captionGray)
    private(set) var contactList = ContactListInputView(placeholder: .contactsTimelineAddContact)
    
    weak var contactListDelegate: ContactListInputViewDelegate? {
        didSet { contactList.delegate = contactListDelegate }
    }
    
    override func setup() {
        super.setup()
        
        VStack(spacing: 8,
               VStack(spacing: 4,
                      titleLabel.multiline(),
                      subtitleLabel.multiline().hideIfEmpty()),
               contactList)
            .embed(in: self)
    }
        
    override func configureForSection() {
        super.configureForSection()
        
        guard case .day(_, let title, let subtitle) = section else { return }
        
        titleLabel.text = title
        subtitleLabel.text = subtitle
    }
    
    override func isConfigured(for section: ContactsTimelineViewModel.Section) -> Bool {
        if case .day(let date, _, _) = self.section, case .day(let otherDate, _, _) = section {
            return date == otherDate
        }
        
        return false
    }
    
}

private class ReviewTipsSectionView: TimelineSectionView {
    
    override func setup() {
        super.setup()
        
        layer.cornerRadius = 8
        backgroundColor = Theme.colors.tipBackgroundPrimary
        
        VStack(spacing: 16,
               VStack(spacing: 6,
                      createTipHeaderLabel(),
                      UILabel(bodyBold: .contactsTimelineReviewTipTitle).multiline()),
               HStack(spacing: 24,
                      VStack(spacing: 16,
                             createTipItem(icon: "Photos", text: .contactsTimelineReviewTipPhotos),
                             createTipItem(icon: "Calendar", text: .contactsTimelineReviewTipCalendar)),
                      VStack(spacing: 16,
                             createTipItem(icon: "SocialMedia", text: .contactsTimelineReviewTipSocialMedia),
                             createTipItem(icon: "Transactions", text: .contactsTimelineReviewTipTransactions)))
                .distribution(.fillProportionally)
                .verticalIf(screenWidthLessThan: 330, spacing: 16))
            .embed(in: self, insets: .all(16))
    }
    
}

private class ActivityTipsSectionView: TimelineSectionView {
    
    override func setup() {
        super.setup()
        
        layer.cornerRadius = 8
        backgroundColor = Theme.colors.tipBackgroundSecondary
        
        VStack(spacing: 16,
               VStack(spacing: 6,
                      createTipHeaderLabel(),
                      UILabel(bodyBold: .contactsTimelineActivityTipTitle).multiline()),
               VStack(spacing: 16,
                      createTipItem(icon: "Car", text: .contactsTimelineActivityTipCar),
                      createTipItem(icon: "Meetings", text: .contactsTimelineActivityTipMeetings),
                      createTipItem(icon: "Conversations", text: .contactsTimelineActivityTipConversations)))
            .embed(in: self, insets: .all(16))
    }
    
}
