/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit
import Contacts

protocol SelectRoommatesViewControllerDelegate: AnyObject {
    func selectRoommatesViewController(_ controller: SelectRoommatesViewController, didFinishWith roommates: [Onboarding.Contact])
    func selectRoommatesViewController(_ controller: SelectRoommatesViewController, didCancelWith roommates: [Onboarding.Contact])
}

class SelectRoommatesViewModel {
    
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
    
    @Bindable private(set) var continueButtonTitle: String = .next
    
    func setNumberOfEnteredContacts(_ value: Int) {
        if value > 0 {
            continueButtonTitle = .next
        } else {
            continueButtonTitle = .determineRoommatesNoContactsButtonTitle
        }
    }
    
}

/// - Tag: SelectRoommatesViewController
class SelectRoommatesViewController: ViewController, ScrollViewNavivationbarAdjusting, KeyboardActionable {
    private let viewModel: SelectRoommatesViewModel
    private let navigationBackgroundView = UIView()
    private let separatorView = SeparatorView()
    private var contactListView: ContactListInputView!
    
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: SelectRoommatesViewControllerDelegate?
    
    let shortTitle: String = .determineRoommatesShortTitle
    
    init(viewModel: SelectRoommatesViewModel) {
        self.viewModel = viewModel
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
        
        setupView()
    }
    
    private func setupView() {
        let margin: UIEdgeInsets = .top(32) + .bottom(16)
        let contacts = Services.onboardingManager.roommates?.map { ContactListInputView.Contact(name: $0.name, cnContactIdentifier: $0.contactIdentifier) } ?? []

        contactListView = ContactListInputView(placeholder: .determineRoommatesAddContact, contacts: contacts, delegate: self)
        let continueButton = Button(title: .next, style: .primary).touchUpInside(self, action: #selector(handleContinue))
        
        let stack =
            VStack(spacing: 24,
                   VStack(spacing: 16,
                          UILabel(title2: .determineRoommatesTitle),
                          UILabel(body: .determineRoommatesMessage, textColor: Theme.colors.captionGray)),
                   contactListView,
                   continueButton)
                .distribution(.fill)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
        
        viewModel.$continueButtonTitle.binding = { continueButton.setTitle($0, for: .normal) }
        viewModel.setNumberOfEnteredContacts(contacts.count)
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(hideSuggestions)))
    }
    
    @objc private func hideSuggestions() {
        contactListView.hideSuggestions()
    }
    
    private var today: Date {
        return Date().start
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        if isMovingFromParent {
            delegate?.selectRoommatesViewController(self, didCancelWith: contactListView.contacts.map {
                Onboarding.Contact(date: today, name: $0.name, contactIdentifier: $0.cnContactIdentifier, isRoommate: true)
            })
        }
    }
    
    @objc private func handleContinue() {
        delegate?.selectRoommatesViewController(self, didFinishWith: contactListView.contacts.map {
            Onboarding.Contact(date: today, name: $0.name, contactIdentifier: $0.cnContactIdentifier, isRoommate: true)
        })
    }
    
    // MARK: - Keyboard handling
    
    func keyboardWillShow(with convertedFrame: CGRect, notification: NSNotification) {
        let inset = view.frame.maxY - convertedFrame.minY
        
        scrollView.contentInset.bottom = inset
        scrollView.verticalScrollIndicatorInsets.bottom = inset
    }

    func keyboardWillHide(notification: NSNotification) {
        scrollView.contentInset = .zero
        scrollView.verticalScrollIndicatorInsets.bottom = .zero
    }

}

extension SelectRoommatesViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}

extension SelectRoommatesViewController: ContactListInputViewDelegate {
    
    func contactListInputView(_ view: ContactListInputView, didBeginEditingIn textField: UITextField) {
        view.scrollTextFieldToVisible(textField, in: scrollView)
    }
    
    func contactListInputView(_ view: ContactListInputView, didEndEditingIn textField: UITextField) {
        viewModel.setNumberOfEnteredContacts(view.contacts.count)
    }
    
    func viewForPresentingSuggestionsFromContactListInputView(_ view: ContactListInputView) -> UIView {
        return self.view
    }
    
    func contactsAvailableForSuggestionInContactListInputView(_ view: ContactListInputView) -> [CNContact] {
        return viewModel.contacts
    }
    
}
