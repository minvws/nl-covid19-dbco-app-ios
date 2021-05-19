/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol ContactsExplanationViewControllerDelegate: AnyObject {
    func contactsExplanationViewControllerWantsToContinue(_ controller: ContactsExplanationViewController)
}

class ContactsExplanationViewModel {
    
}

/// A viewcontroller showing a list of items explaining the benefits of giving permission to access contacts, and what that acces entails.
///
/// - Tag: ContactsExplanationViewController
class ContactsExplanationViewController: ViewController, ScrollViewNavivationbarAdjusting {
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
        
        scrollView.embed(in: view)
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        
        let widthProviderView = UIView()
        widthProviderView.snap(to: .top, of: scrollView, height: 0)
        widthProviderView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        setupView()
    }
    
    private func setupView() {
        let margin: UIEdgeInsets = .top(32) + .bottom(16) + .right(16)
        
        let stack =
            VStack(spacing: 24,
                   VStack(spacing: 24,
                       VStack(spacing: 16,
                              UILabel(title2: .determineContactsExplanationTitle),
                              UILabel(body: .determineContactsExplanationMessage, textColor: Theme.colors.captionGray)),
                       VStack(spacing: 16,
                              listItem(.determineContactsExplanationItem1, imageName: "ListItem/Checkmark"),
                              listItem(.determineContactsExplanationItem2, imageName: "ListItem/Checkmark"),
                              listItem(.determineContactsExplanationItem3, imageName: "ListItem/Questionmark"),
                              listItem(.determineContactsExplanationItem4, imageName: "ListItem/Stop"))),
                   Button(title: .next, style: .primary)
                       .touchUpInside(self, action: #selector(handleContinue)))
                .distribution(.equalSpacing)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: view.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
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
