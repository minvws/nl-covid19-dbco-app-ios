/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol ContactsAuthorizationViewControllerDelegate: class {
    func contactsAuthorizationViewControllerDidSelectAllow(_ controller: ContactsAuthorizationViewController)
    func contactsAuthorizationViewControllerDidSelectManual(_ controller: ContactsAuthorizationViewController)
}

class ContactsAuthorizationViewModel {
    
    let title: String
    
    init(contactName: String?) {
        if let contactName = contactName {
            title = .selectContactAuthorizationTitle(name: contactName)
        } else {
            title = .selectContactAuthorizationFallbackTitle
        }
    }
}

class ContactsAuthorizationViewController: PromptableViewController, ScrollViewNavivationbarAdjusting {
    private let viewModel: ContactsAuthorizationViewModel
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: ContactsAuthorizationViewControllerDelegate?
    
    let shortTitle: String = .onboardingConsentShortTitle
    
    init(viewModel: ContactsAuthorizationViewModel) {
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
        
        scrollView.embed(in: contentView)
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: contentView.widthAnchor).isActive = true
        
        func listItem(_ text: String) -> UIView {
            return HStack(spacing: 16,
                          ImageView(imageName: "PrivacyItem").asIcon(),
                          Label(body: text, textColor: Theme.colors.captionGray).multiline())
                .alignment(.top)
        }
        
        func htmlListItem(_ text: String) -> UIView {
            let attributedString: NSAttributedString = .makeFromHtml(text: text,
                                                                     font: Theme.fonts.body,
                                                                     textColor: Theme.colors.captionGray,
                                                                     boldTextColor: .black)
            let label = Label("")
            label.attributedText = attributedString
            
            return HStack(spacing: 16,
                          ImageView(imageName: "PrivacyItem").asIcon(),
                          label.multiline())
                .alignment(.top)
        }
        
        let margin: UIEdgeInsets = .top(64) + .bottom(18)
        
        let stack =
            VStack(spacing: 24,
                   VStack(spacing: 24,
                       VStack(spacing: 16,
                              Label(title2: viewModel.title).multiline(),
                              Label(body: .selectContactAuthorizationMessage, textColor: Theme.colors.captionGray).multiline()),
                       VStack(spacing: 16,
                              listItem(.selectContactAuthorizationItem1),
                              htmlListItem(.selectContactAuthorizationItem2),
                              listItem(.selectContactAuthorizationItem3))),
                   UIView())
                .distribution(.equalSpacing)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: contentView.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
        
        promptView = VStack(spacing: 16,
                            Button(title: .selectContactAuthorizationManualButton, style: .secondary)
                                .touchUpInside(self, action: #selector(manual)),
                            Button(title: .selectContactAuthorizationAllowButton, style: .primary)
                                .touchUpInside(self, action: #selector(allow)))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let scrollingHeight = scrollView.contentSize.height + scrollView.safeAreaInsets.top + scrollView.safeAreaInsets.bottom
        let canScroll = scrollingHeight > scrollView.frame.height
        showPromptViewSeparator = canScroll
    }
    
    @objc private func allow() {
        delegate?.contactsAuthorizationViewControllerDidSelectAllow(self)
    }
    
    @objc private func manual() {
        delegate?.contactsAuthorizationViewControllerDidSelectManual(self)
    }

}

extension ContactsAuthorizationViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}
