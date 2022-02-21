/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol PrivacyConsentViewControllerDelegate: AnyObject {
    func privacyConsentViewControllerWantsToContinue(_ controller: PrivacyConsentViewController)
    func privacyConsentViewController(_ controller: PrivacyConsentViewController, wantsToOpen url: URL)
}

class PrivacyConsentViewModel {
    let buttonTitle: String
    
    @Bindable private(set) var isContinueButtonEnabled: Bool = false
    
    init(buttonTitle: String) {
        self.buttonTitle = buttonTitle
    }
    
    func registerConsent(value: Bool) {
        isContinueButtonEnabled = value
    }
}

/// - Tag: PrivacyConsentViewController
class PrivacyConsentViewController: ViewController, ScrollViewNavivationbarAdjusting {
    private let viewModel: PrivacyConsentViewModel
    private let scrollView = UIScrollView(frame: .zero)
    
    weak var delegate: PrivacyConsentViewControllerDelegate?
    
    let shortTitle: String = .onboardingConsentShortTitle
    
    init(viewModel: PrivacyConsentViewModel) {
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
        scrollView.contentWidth(equalTo: view)
        scrollView.delegate = self
        scrollView.delaysContentTouches = false
        
        setupView()
    }
    
    private func setupView() {
        let continueButton = Button(title: viewModel.buttonTitle, style: .primary).touchUpInside(self, action: #selector(handleContinue))
        viewModel.$isContinueButtonEnabled.binding = { continueButton.isEnabled = $0 }
        
        let margin: UIEdgeInsets = .top(32) + .bottom(16)
        
        let stack =
            VStack(spacing: 24,
                   VStack(spacing: 24,
                       VStack(spacing: 16,
                              UILabel(title2: .onboardingConsentTitle),
                              TextView(htmlText: .onboardingConsentMessage, textColor: Theme.colors.captionGray)
                                .linkTouched { [unowned self] in self.open($0) }),
                       VStack(spacing: 16,
                              listItem(.onboardingConsentItem1),
                              listItem(.onboardingConsentItem2),
                              listItem(.onboardingConsentItem3),
                              listItem(.onboardingConsentItem4))),
                   VStack(spacing: 24,
                          SelectableButton(title: .onboardingConsentButtonTitle, selected: false).valueChanged(self, action: #selector(consentValueChanged)),
                          continueButton))
                .distribution(.equalSpacing)
                .embed(in: scrollView.readableWidth, insets: margin)
        
        stack.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.safeAreaLayoutGuide.heightAnchor,
                                      multiplier: 1,
                                      constant: -(margin.top + margin.bottom)).isActive = true
    }
    
    @objc private func handleContinue() {
        delegate?.privacyConsentViewControllerWantsToContinue(self)
    }
    
    private func open(_ url: URL) {
        delegate?.privacyConsentViewController(self, wantsToOpen: url)
    }
    
    @objc private func consentValueChanged(_ sender: SelectableButton) {
        viewModel.registerConsent(value: sender.isSelected)
    }
    
}

extension PrivacyConsentViewController: UIScrollViewDelegate {
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}
