/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol ContactsAuthorizationViewControllerDelegate: AnyObject {
    func contactsAuthorizationViewControllerDidSelectAllow(_ controller: ContactsAuthorizationViewController)
    func contactsAuthorizationViewControllerDidSelectManual(_ controller: ContactsAuthorizationViewController)
}

class ContactsAuthorizationViewModel {
    
    let title: String
    let allowButtonTitle: String
    let manualButtonTitle: String
    
    enum Style {
        case onboarding
        case selectContact
    }
    
    let topMargin: CGFloat
    
    init(contactName: String?, style: Style) {
        switch style {
        case .onboarding:
            title = .determineContactsAuthorizationTitle
            topMargin = 18
            allowButtonTitle = .determineContactsAuthorizationAllowButton
            manualButtonTitle = .determineContactsAuthorizationAddManuallyButton
        case .selectContact:
            if let contactName = contactName {
                title = .selectContactAuthorizationTitle(name: contactName)
            } else {
                title = .selectContactAuthorizationFallbackTitle
            }
            
            topMargin = 64
            allowButtonTitle = .selectContactAuthorizationAllowButton
            manualButtonTitle = .selectContactAuthorizationManualButton
        }
    }
}

class ContactsAuthorizationViewController: ViewController, ScrollViewNavivationbarAdjusting {
    private let viewModel: ContactsAuthorizationViewModel
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: ContactsAuthorizationViewControllerDelegate?
    
    let shortTitle: String = ""
    
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
        
        scrollView.embed(in: view)
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        
        setupView()
    }
    
    private func setupView() {
        scrollView.contentWidth(equalTo: view)
        
        let margin: UIEdgeInsets = .top(viewModel.topMargin) + .bottom(16)
        
        let stack =
            VStack(spacing: 24,
                   VStack(spacing: 16,
                          UILabel(title2: viewModel.title),
                          UILabel(body: .selectContactAuthorizationMessage, textColor: Theme.colors.captionGray)),
                   VStack(spacing: 16,
                          Button(title: viewModel.manualButtonTitle, style: .secondary)
                            .touchUpInside(self, action: #selector(manual)),
                          Button(title: viewModel.allowButtonTitle, style: .primary)
                            .touchUpInside(self, action: #selector(allow))))
                .distribution(.equalSpacing)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
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
