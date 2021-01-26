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
}

private extension Date {
    var normalized: Date {
        Calendar.current.date(bySettingHour: 0, minute: 0, second: 0, of: self)!
    }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
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
        formatter.dateFormat = "EEEE d MMMM"
        
        return formatter
    }()
    
    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = .current
        formatter.timeZone = .current
        formatter.dateFormat = "d MMMM"
        
        return formatter
    }()
    
    private var remainingExtraDays = 2
    
    init(dateOfSymptomOnset: Date) {
        configuration = .dateOfSymptomOnset(dateOfSymptomOnset.normalized)
    }
    
    init(testDate: Date) {
        configuration = .testDate(testDate.normalized)
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
        return "Wie heb je ontmoet tussen \(dateFormatter.string(from: endDate)) en vandaag?"
    }
    
    var sections: [Section] {
        let today = Date().normalized
    
        let numberOfDays = Calendar.current.dateComponents([.day], from: endDate, to: today).day! + 1
        
        func title(for index: Int, date: Date) -> String {
            let titleFormats = [
                "Vandaag (%@)",
                "Gisteren (%@)",
                "Eergisteren (%@)"
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
                    "Deze dag was je ook al besmettelijk",
                    "Deze dag was je ook al besmettelijk",
                    "De eerste dag dat je klachten had"
                ]
            case .testDate:
                reversedSubtitles = [
                    "Op deze dag liet je jezelf testen"
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
            return remainingExtraDays == 0
        case .testDate:
            return true
        }
    }
    
    var addExtraDayTitle: String? {
        guard case .dateOfSymptomOnset(let date) = configuration else { return nil }
        
        return "Weet je zeker dat je voor \(shortDateFormatter.string(from: date)) nog geen klachten had?"
    }
    
    func addExtraDay() {
        guard case .dateOfSymptomOnset(let date) = configuration else { return }
        guard remainingExtraDays > 0 else { return }
        
        let adjustedDate = Calendar.current.date(byAdding: .day, value: -1, to: date)!
        
        configuration = .dateOfSymptomOnset(adjustedDate)
        
        remainingExtraDays -= 1
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
            combinedDates = dates.dropLast().joined(separator: ", ") + " en " + dates.last!
        } else {
            combinedDates = dates.joined(separator: " en ")
        }
        
        return "Klopt het dat je op \(combinedDates) niemand hebt ontmoet?"
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
    private let titleLabel = Label(title2: nil)
    private var addExtraDaySectionView: UIStackView!
    private let addExtraDayTitleLabel = Label(bodyBold: nil)
    
    private let scrollView = UIScrollView(frame: .zero)
    private var sectionStackView: UIStackView!
    
    weak var delegate: ContactsTimelineViewControllerDelegate?
    
    let shortTitle: String = "Contacten"
    
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
        
        let addExtraDayButton = Button(title: "Extra dag toevoegen", style: .secondary)
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
                          Label(body: "Weet je niet hoe iemand heet? Zet het contact er dan toch in. Bijvoorbeeld als trainer, kapper of buurvrouw. Je hoeft hier geen huisgenoten toe te voegen.", textColor: Theme.colors.captionGray).multiline()),
                   sectionStackView,
                   VStack(spacing: 16,
                          addExtraDaySectionView,
                          Button(title: .next, style: .primary).touchUpInside(self, action: #selector(handleContinue))))
                .distribution(.fill)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                                          multiplier: 1,
                                          constant: -(margin.top + margin.bottom)).isActive = true
        
        configureSections()
        
        registerForKeyboardNotifications()
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
                return sectionView.contactList.contacts.map { Onboarding.Contact(date: date, name: $0.name, contactIdentifier: $0.cnContactIdentifier) }
            }
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
            let alert = UIAlertController(title: "Je hebt niet aan iedere dag contacten toegevoegd",
                                          message: viewModel.emptyDaysMessage(for: emptySections),
                                          preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "Terug", style: .default, handler: nil))
            alert.addAction(UIAlertAction(title: "Ga verder", style: .default) { _ in
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
            
            if currentOffset > minOffset {
                scrollView.setContentOffset(CGPoint(x: 0, y: minOffset), animated: true)
            } else if currentOffset < maxOffset {
                scrollView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: true)
            }
        }
        
        // Next runcycle so keyboard size is properly incorporated
        DispatchQueue.main.async(execute: scrollVisible)
    }
    
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
        
        Label(caption1: "Geheugentip".uppercased(), textColor: .white)
            .embed(in: headerContainerView, insets: .all(4))
        
        return VStack(headerContainerView).alignment(.leading)
    }
    
    func createTipItem(icon: String, text: String) -> UIView {
        let icon = UIImageView(image: UIImage(named: "MemoryTips/\(icon)"))
        icon.contentMode = .center
        icon.widthAnchor.constraint(equalToConstant: 22).isActive = true
        
        return HStack(spacing: 12,
                      icon,
                      Label(body: text, textColor: Theme.colors.tipItemColor).multiline())
    }
}

private class DaySectionView: TimelineSectionView {
    private let titleLabel = Label(bodyBold: nil)
    private let subtitleLabel = Label(body: nil, textColor: Theme.colors.captionGray)
    private(set) var contactList = ContactListInputView(placeholder: "Contact toevoegen")
    
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
                      Label(bodyBold: "Mensen vergeten vaak activiteiten. Bekijk daarom ook je:").multiline()),
               HStack(spacing: 24,
                      VStack(spacing: 16,
                             createTipItem(icon: "Photos", text: "Foto's"),
                             createTipItem(icon: "Calendar", text: "Agenda's")),
                      VStack(spacing: 16,
                             createTipItem(icon: "SocialMedia", text: "Social Media"),
                             createTipItem(icon: "Transactions", text: "Pintransacties")))
                .distribution(.fillProportionally)
                .verticalIf(screenWidthLessThan: 330, spacing: 0))
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
                      Label(bodyBold: "Deze activiteiten worden vaak vergeten").multiline()),
               VStack(spacing: 16,
                      createTipItem(icon: "Car", text: "Samen in de auto zitten"),
                      createTipItem(icon: "Meetings", text: "Ontmoetingen buiten of bij jou thuis"),
                      createTipItem(icon: "Conversations", text: "Een onverwachts gesprek op werk")))
            .embed(in: self, insets: .all(16))
    }
    
}
