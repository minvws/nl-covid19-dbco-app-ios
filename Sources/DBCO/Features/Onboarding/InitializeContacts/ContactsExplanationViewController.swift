/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol ContactsExplanationViewControllerDelegate: class {
    func contactsExplanationViewControllerWantsToContinue(_ controller: ContactsExplanationViewController)
}

class ContactsExplanationViewModel {
    
}

/// - Tag: ContactsExplanationViewControlle
class ContactsExplanationViewController: PromptableViewController, ScrollViewNavivationbarAdjusting {
    private let viewModel: ContactsExplanationViewModel
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: ContactsExplanationViewControllerDelegate?
    
    let shortTitle: String = .determineContactsExplanationShortTitle
    
    init(viewModel: ContactsExplanationViewModel) {
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
        
        let margin: UIEdgeInsets = .top(32) + .bottom(18) + .right(16)
        
        let stack =
            VStack(spacing: 24,
                   VStack(spacing: 24,
                       VStack(spacing: 16,
                              UILabel(title2: .determineContactsExplanationTitle).multiline(),
                              UILabel(body: .determineContactsExplanationMessage, textColor: Theme.colors.captionGray).multiline()),
                       VStack(spacing: 16,
                              listItem(.determineContactsExplanationItem1, imageName: "ListItem/Checkmark"),
                              listItem(.determineContactsExplanationItem2, imageName: "ListItem/Checkmark"),
                              listItem(.determineContactsExplanationItem3, imageName: "ListItem/Questionmark"),
                              listItem(.determineContactsExplanationItem4, imageName: "ListItem/Stop"))),
                   UIView()) // Empty view for spacing
                .distribution(.equalSpacing)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: contentView.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
        
        promptView = Button(title: .next, style: .primary)
            .touchUpInside(self, action: #selector(handleContinue))
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        let scrollingHeight = scrollView.contentSize.height + scrollView.safeAreaInsets.top + scrollView.safeAreaInsets.bottom
        let canScroll = scrollingHeight > scrollView.frame.height
        showPromptViewSeparator = canScroll
    }
    
    @objc private func handleContinue() {
        delegate?.contactsExplanationViewControllerWantsToContinue(self)
    }
    
}

extension ContactsExplanationViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}
