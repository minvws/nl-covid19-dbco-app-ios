/*
 * Copyright (c) 2020 De Staat der Nederlanden, Ministerie van Volksgezondheid, Welzijn en Sport.
 *  Licensed under the EUROPEAN UNION PUBLIC LICENCE v. 1.2
 *
 *  SPDX-License-Identifier: EUPL-1.2
 */

import UIKit

protocol VerifyZipCodeViewControllerDelegate: AnyObject {
    func verifyZipCodeViewController(_ controller: VerifyZipCodeViewController, didFinishWithActiveZipCode: Bool)
}

class VerifyZipCodeViewModel {
    
}

/// Not all GGD Regions might be using GGD Contact. This ViewController asks for the user's zip code and informs them about support in their region.
///
/// # See also
/// [ZipRange](x-source-tag://ZipRange)
/// 
/// - Tag: VerifyZipCodeViewController
class VerifyZipCodeViewController: ViewController, ScrollViewNavivationbarAdjusting, KeyboardActionable {
    let shortTitle: String = ""
    
    private let viewModel: VerifyZipCodeViewModel
    
    private let scrollView = UIScrollView()
    private let codeField =
        CodeField(with: CodeDescription(digitGroupSize: 4,
                                        numberOfGroups: 1,
                                        accessibilityLabel: .onboardingVerifyZipCodeTitle,
                                        accessibilityHint: .onboardingVerifyZipCodeAccessibilityHint,
                                        adjustKerningForWidth: false))
    
    private var keyboardSpacerHeightConstraint: NSLayoutConstraint!
    
    weak var delegate: VerifyZipCodeViewControllerDelegate?

    init(viewModel: VerifyZipCodeViewModel) {
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

        let titleLabel = UILabel(title2: .onboardingVerifyZipCodeTitle)
        
        let subtitleLabel = UILabel(body: .onboardingVerifyZipCodeMessage, textColor: Theme.colors.captionGray)
        
        let keyboardSpacerView = UIView()
        keyboardSpacerHeightConstraint = keyboardSpacerView.heightAnchor.constraint(equalToConstant: 0)
        keyboardSpacerHeightConstraint.isActive = true
        
        let nextButton = Button(title: .next, style: .primary)
            .touchUpInside(self, action: #selector(verify))
        
        nextButton.isEnabled = false
        codeField.didUpdatePairingCode { nextButton.isEnabled = $0 != nil }
        
        let topMargin: CGFloat = UIScreen.main.bounds.height < 600 ? 0 : 32
        
        let containerView =
            VStack(spacing: 32,
                   VStack(spacing: 16,
                          titleLabel,
                          subtitleLabel,
                          codeField),
                   VStack(spacing: 20,
                          nextButton,
                          keyboardSpacerView))
            .distribution(.equalSpacing)
        
        containerView.embed(in: scrollView.readableWidth, insets: .top(topMargin))
        
        containerView.heightAnchor.constraint(greaterThanOrEqualTo: scrollView.safeAreaLayoutGuide.heightAnchor, multiplier: 1, constant: -topMargin).isActive = true
        
        scrollView.embed(in: view)
        scrollView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        navigationController?.setNavigationBarHidden(false, animated: animated)
        codeField.becomeFirstResponder()
    }
    
    @objc private func verify() {
        guard let codeString = codeField.code, let code = Int(codeString) else { return }
        
        let isInRange = Services.configManager.supportedZipCodeRanges.contains { $0.contains(code) }
        
        delegate?.verifyZipCodeViewController(self, didFinishWithActiveZipCode: isInRange)
    }
    
    // MARK: - Keyboard handling
    func keyboardWillShow(with convertedFrame: CGRect, notification: NSNotification) {
        let inset = view.frame.maxY - convertedFrame.minY - view.safeAreaInsets.bottom
        keyboardSpacerHeightConstraint.constant = inset
    }

    func keyboardWillHide(notification: NSNotification) {
        keyboardSpacerHeightConstraint.constant = 0
    }
}

// MARK: - UIScrollViewDelegate

extension VerifyZipCodeViewController: UIScrollViewDelegate {
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        codeField.resignFirstResponder() // Hide keyboard on scroll
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        adjustNavigationBar(for: scrollView)
    }
    
}
